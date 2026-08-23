-- DOU Campus production schema
-- Run in a NEW Supabase project through SQL Editor, then run Security Advisor.
create extension if not exists pgcrypto;
create type public.app_role as enum ('student','club_admin','organizer','super_admin');
create type public.event_status as enum ('draft','review','published','cancelled','completed');
create type public.claim_status as enum ('active','used','cancelled','expired');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  student_no text unique,
  display_name text not null,
  university_email text unique not null check (university_email ~* '^[^@]+@dogus\.edu\.tr$'),
  department text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.app_role not null default 'student',
  granted_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  primary key(user_id,role)
);
create table public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  logo_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.club_members (
  club_id uuid references public.clubs(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  is_manager boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key(club_id,user_id)
);
create table public.events (
  id uuid primary key default gen_random_uuid(),
  club_id uuid references public.clubs(id),
  created_by uuid not null references public.profiles(id),
  title text not null check (char_length(title) between 3 and 120),
  description text not null default '',
  category text not null,
  location text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null check (ends_at > starts_at),
  registration_deadline timestamptz,
  capacity integer not null check (capacity > 0),
  xp integer not null default 0 check (xp between 0 and 5000),
  status public.event_status not null default 'draft',
  cover_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.event_registrations (
  event_id uuid references public.events(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  waitlisted boolean not null default false,
  registered_at timestamptz not null default now(),
  cancelled_at timestamptz,
  primary key(event_id,user_id)
);
create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  public_fingerprint_hash text not null,
  label text,
  verified_at timestamptz,
  revoked_at timestamptz,
  last_seen_at timestamptz not null default now(),
  unique(user_id,public_fingerprint_hash)
);
create table public.qr_sessions (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  nonce_hash text not null unique,
  starts_at timestamptz not null,
  expires_at timestamptz not null,
  created_by uuid not null references public.profiles(id),
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);
create table public.attendance (
  event_id uuid references public.events(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  device_id uuid not null references public.devices(id),
  qr_session_id uuid not null references public.qr_sessions(id),
  verified_at timestamptz not null default now(),
  primary key(event_id,user_id),
  unique(qr_session_id,user_id)
);
create table public.xp_ledger (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount integer not null check (amount <> 0),
  reason text not null,
  reference_type text not null,
  reference_id uuid,
  created_at timestamptz not null default now(),
  unique(user_id,reference_type,reference_id)
);
create table public.challenges (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  rule jsonb not null default '{}'::jsonb,
  xp integer not null check (xp between 0 and 5000),
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean not null default true,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);
create table public.challenge_progress (
  challenge_id uuid references public.challenges(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  progress integer not null default 0,
  completed_at timestamptz,
  approved_by uuid references public.profiles(id),
  primary key(challenge_id,user_id)
);
create table public.rewards (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  xp_cost integer not null check (xp_cost > 0),
  stock integer not null check (stock >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.reward_claims (
  id uuid primary key default gen_random_uuid(),
  reward_id uuid not null references public.rewards(id),
  user_id uuid not null references public.profiles(id),
  code_hash text not null unique,
  status public.claim_status not null default 'active',
  claimed_at timestamptz not null default now(),
  used_at timestamptz
);
create table public.notifications (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  link text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles(id),
  action text not null,
  entity_type text not null,
  entity_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index events_status_starts_idx on public.events(status,starts_at);
create index registrations_user_idx on public.event_registrations(user_id);
create index xp_user_created_idx on public.xp_ledger(user_id,created_at desc);
create index notifications_user_idx on public.notifications(user_id,created_at desc);
create index audit_created_idx on public.audit_logs(created_at desc);

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.clubs enable row level security;
alter table public.club_members enable row level security;
alter table public.events enable row level security;
alter table public.event_registrations enable row level security;
alter table public.devices enable row level security;
alter table public.qr_sessions enable row level security;
alter table public.attendance enable row level security;
alter table public.xp_ledger enable row level security;
alter table public.challenges enable row level security;
alter table public.challenge_progress enable row level security;
alter table public.rewards enable row level security;
alter table public.reward_claims enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

create policy "profile own read" on public.profiles for select to authenticated using ((select auth.uid())=id);
create policy "profile own update" on public.profiles for update to authenticated using ((select auth.uid())=id) with check ((select auth.uid())=id);
create policy "public active clubs" on public.clubs for select to anon,authenticated using (is_active);
create policy "public published events" on public.events for select to anon,authenticated using (status='published');
create policy "student own registrations" on public.event_registrations for select to authenticated using ((select auth.uid())=user_id);
create policy "student own registration insert" on public.event_registrations for insert to authenticated with check ((select auth.uid())=user_id);
create policy "student own registration update" on public.event_registrations for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy "student own devices" on public.devices for select to authenticated using ((select auth.uid())=user_id);
create policy "student own device insert" on public.devices for insert to authenticated with check ((select auth.uid())=user_id);
create policy "student own attendance" on public.attendance for select to authenticated using ((select auth.uid())=user_id);
create policy "student own xp" on public.xp_ledger for select to authenticated using ((select auth.uid())=user_id);
create policy "active challenges" on public.challenges for select to authenticated using (is_active);
create policy "student own challenge progress" on public.challenge_progress for select to authenticated using ((select auth.uid())=user_id);
create policy "active rewards" on public.rewards for select to authenticated using (is_active);
create policy "student own claims" on public.reward_claims for select to authenticated using ((select auth.uid())=user_id);
create policy "student own notifications" on public.notifications for select to authenticated using ((select auth.uid())=user_id);
create policy "student mark notifications" on public.notifications for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);

-- No INSERT policy exists for attendance, xp_ledger or reward_claims.
-- These sensitive writes must be performed by audited server-side endpoints.
revoke all on public.user_roles,public.devices,public.qr_sessions,public.attendance,public.xp_ledger,public.reward_claims,public.audit_logs from anon;
grant select on public.clubs,public.events to anon;
grant select,update on public.profiles to authenticated;
grant select on public.clubs,public.events,public.challenges,public.rewards to authenticated;
grant select,insert,update on public.event_registrations,public.devices to authenticated;
grant select on public.attendance,public.xp_ledger,public.challenge_progress,public.reward_claims to authenticated;
grant select,update on public.notifications to authenticated;

create view public.student_xp_totals with (security_invoker=true) as
select user_id,coalesce(sum(amount),0)::bigint as total_xp from public.xp_ledger group by user_id;
