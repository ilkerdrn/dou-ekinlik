-- Run after schema.sql. Designed for Supabase Postgres 15+.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create type public.approval_status as enum ('pending','approved','returned','rejected');
create type public.feedback_visibility as enum ('private','organizer','institution');

create table public.event_feedback (
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  comment text check (char_length(comment) <= 1000),
  visibility public.feedback_visibility not null default 'organizer',
  created_at timestamptz not null default now(),
  primary key(event_id,user_id)
);
create table public.event_approvals (
  id bigint generated always as identity primary key,
  event_id uuid not null references public.events(id) on delete cascade,
  status public.approval_status not null default 'pending',
  submitted_by uuid not null references public.profiles(id),
  reviewed_by uuid references public.profiles(id),
  review_note text check (char_length(review_note) <= 1000),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);
create table public.competencies (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null,
  description text not null default '',
  is_active boolean not null default true
);
create table public.event_competencies (
  event_id uuid references public.events(id) on delete cascade,
  competency_id uuid references public.competencies(id) on delete cascade,
  weight smallint not null default 1 check (weight between 1 and 5),
  primary key(event_id,competency_id)
);
create table public.service_hours (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  event_id uuid references public.events(id) on delete set null,
  minutes integer not null check (minutes between 1 and 1440),
  verified_by uuid not null references public.profiles(id),
  verified_at timestamptz not null default now()
);

alter table public.event_feedback enable row level security;
alter table public.event_approvals enable row level security;
alter table public.competencies enable row level security;
alter table public.event_competencies enable row level security;
alter table public.service_hours enable row level security;

create policy "own feedback read" on public.event_feedback for select to authenticated using ((select auth.uid())=user_id);
create policy "own feedback insert" on public.event_feedback for insert to authenticated with check ((select auth.uid())=user_id and exists(select 1 from public.attendance a where a.event_id=event_id and a.user_id=(select auth.uid())));
create policy "own feedback update" on public.event_feedback for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy "active competencies read" on public.competencies for select to authenticated using (is_active);
create policy "event competencies read" on public.event_competencies for select to authenticated using (exists(select 1 from public.events e where e.id=event_id and e.status='published'));
create policy "own service hours" on public.service_hours for select to authenticated using ((select auth.uid())=user_id);

grant select,insert,update on public.event_feedback to authenticated;
grant select on public.competencies,public.event_competencies,public.service_hours to authenticated;
revoke all on public.event_approvals from anon,authenticated;

create or replace function private.is_staff(p_user uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.user_roles r where r.user_id=p_user and r.role in ('club_admin','organizer','super_admin'));
$$;
revoke all on function private.is_staff(uuid) from public;

create or replace function private.verify_attendance(p_qr_session uuid,p_device uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_session public.qr_sessions%rowtype; v_xp integer;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  select * into v_session from public.qr_sessions where id=p_qr_session for update;
  if not found or v_session.revoked_at is not null or now() not between v_session.starts_at and v_session.expires_at then raise exception 'QR_INVALID_OR_EXPIRED'; end if;
  if not exists(select 1 from public.devices d where d.id=p_device and d.user_id=v_user and d.revoked_at is null) then raise exception 'DEVICE_NOT_VERIFIED'; end if;
  if not exists(select 1 from public.event_registrations r where r.event_id=v_session.event_id and r.user_id=v_user and r.cancelled_at is null and not r.waitlisted) then raise exception 'REGISTRATION_REQUIRED'; end if;
  select xp into v_xp from public.events where id=v_session.event_id and status='published' and now() between starts_at-interval '30 minutes' and ends_at+interval '30 minutes';
  if v_xp is null then raise exception 'EVENT_NOT_ACTIVE'; end if;
  insert into public.attendance(event_id,user_id,device_id,qr_session_id) values(v_session.event_id,v_user,p_device,p_qr_session) on conflict do nothing;
  if not found then raise exception 'ALREADY_VERIFIED'; end if;
  insert into public.xp_ledger(user_id,amount,reason,reference_type,reference_id) values(v_user,v_xp,'Doğrulanmış etkinlik katılımı','attendance',v_session.event_id);
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,metadata) values(v_user,'attendance.verify','event',v_session.event_id::text,jsonb_build_object('device_id',p_device,'qr_session_id',p_qr_session));
  return jsonb_build_object('ok',true,'event_id',v_session.event_id,'xp',v_xp);
end;$$;
revoke all on function private.verify_attendance(uuid,uuid) from public,anon;
grant execute on function private.verify_attendance(uuid,uuid) to authenticated;
grant usage on schema private to authenticated;

-- Data API only exposes this invoker wrapper; privileged logic remains in private.
create or replace function public.verify_attendance(p_qr_session uuid,p_device uuid)
returns jsonb language sql volatile security invoker set search_path='' as $$
  select private.verify_attendance(p_qr_session,p_device);
$$;
revoke all on function public.verify_attendance(uuid,uuid) from public,anon;
grant execute on function public.verify_attendance(uuid,uuid) to authenticated;

create or replace view public.student_competency_totals with (security_invoker=true) as
select a.user_id, c.id competency_id, c.code, c.title, sum(ec.weight)::bigint score
from public.attendance a join public.event_competencies ec on ec.event_id=a.event_id join public.competencies c on c.id=ec.competency_id
group by a.user_id,c.id,c.code,c.title;
grant select on public.student_competency_totals to authenticated;

create or replace view public.student_social_transcript with (security_invoker=true) as
select p.id user_id,p.display_name,p.student_no,p.department,count(distinct a.event_id)::bigint verified_events,
       coalesce(sum(sh.minutes),0)::bigint service_minutes,coalesce(x.total_xp,0)::bigint total_xp
from public.profiles p left join public.attendance a on a.user_id=p.id left join public.service_hours sh on sh.user_id=p.id
left join public.student_xp_totals x on x.user_id=p.id group by p.id,p.display_name,p.student_no,p.department,x.total_xp;
grant select on public.student_social_transcript to authenticated;
