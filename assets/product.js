(function () {
  const q = (s, p = document) => p.querySelector(s);
  const esc = (v) =>
    String(v).replace(
      /[&<>'"]/g,
      (c) =>
        ({
          "&": "&amp;",
          "<": "&lt;",
          ">": "&gt;",
          "'": "&#39;",
          '"': "&quot;",
        })[c],
    );
  const notifications = [
    {
      id: 1,
      title: "Kampüs Quest yarın",
      body: "Kayıtlı olduğun etkinlik yarın 17:30’da Çengelköy Kampüsü’nde.",
      time: "2 saat önce",
      read: false,
    },
    {
      id: 2,
      title: "Challenge ilerlemen güncellendi",
      body: "Kulüp Kaşifi görevinde 2/3 seviyesine ulaştın.",
      time: "Dün",
      read: false,
    },
    {
      id: 3,
      title: "Yeni ödül stokta",
      body: "DOU bez çanta yeniden ödül mağazasına eklendi.",
      time: "2 gün önce",
      read: true,
    },
  ];
  const approvals = [
    {
      id: 1,
      title: "Yapay Zekâ Kariyer Buluşması",
      owner: "Yazılım Kulübü",
      type: "Etkinlik",
      risk: "Düşük",
    },
    {
      id: 2,
      title: "Toplumsal Fayda Maratonu",
      owner: "Sosyal Sorumluluk Kulübü",
      type: "Challenge",
      risk: "Düşük",
    },
    {
      id: 3,
      title: "Konser öncelikli giriş",
      owner: "SKS Müdürlüğü",
      type: "Ödül",
      risk: "Stok kontrolü",
    },
  ];
  const clubs = [
    { name: "Yazılım Kulübü", members: 486, events: 18, rate: 84 },
    { name: "Girişimcilik Kulübü", members: 352, events: 12, rate: 79 },
    { name: "Sosyal Sorumluluk", members: 301, events: 15, rate: 91 },
  ];
  function banner() {
    const page = document.body.dataset.page;
    if (!page) return;
    const cfg = window.DOU_CONFIG || {},
      live =
        cfg.mode === "supabase" &&
        /^https:\/\/.+\.supabase\.co$/.test(cfg.supabaseUrl || "") &&
        /^sb_publishable_/.test(cfg.supabasePublishableKey || "");
    const main = q(".main"),
      top = q(".topbar");
    if (!main || !top) return;
    const el = document.createElement("div");
    el.className = "integration-banner";
    el.innerHTML = `<div><strong>${live ? "Canlı altyapı yapılandırıldı" : "Güvenli demo modu"}</strong><small>${live ? "Supabase ve Microsoft Entra bağlantısı etkinleştirilmeye hazır." : "Supabase URL, publishable key ve Entra kimlikleri girildiğinde gerçek oturum ve senkronizasyon açılır."}</small></div><span class="status ${live ? "" : "offline"}">${live ? "Hazır" : "Demo"}</span>`;
    top.after(el);
  }
  function renderTranscript() {
    const el = q("#transcriptContent");
    if (!el) return;
    const xp = Store.get("xp", 1280),
      scans = Store.get("scans", []).length;
    el.innerHTML = `<div class="transcript-hero"><article class="card transcript-score"><span class="eyebrow" style="color:#ff7189">2026 Güz dönemi</span><h2>Demo Öğrenci</h2><p style="color:#bbb">Doğrulanmış ders dışı gelişim kaydı</p><div class="stats"><div class="stat"><strong>${xp.toLocaleString("tr-TR")}</strong><span>Toplam XP</span></div><div class="stat"><strong>${scans + 7}</strong><span>Katılım</span></div><div class="stat"><strong>4</strong><span>Yetkinlik</span></div></div></article><article class="card"><span class="eyebrow">Seviye</span><h2>Kampüs Öncüsü</h2><p>Bir sonraki seviyeye ${Math.max(0, 2000 - xp)} XP kaldı.</p><div class="progress"><span style="width:${Math.min(100, xp / 20)}%"></span></div></article></div><div class="dashboard-grid"><article class="card"><h3>Yetkinlik gelişimi</h3><div class="skill-grid">${[
      ["Takım çalışması", 82],
      ["Liderlik", 68],
      ["Sosyal sorumluluk", 91],
      ["Kariyer farkındalığı", 74],
    ]
      .map(
        ([n, v]) =>
          `<div class="skill-row"><span>${n}</span><div class="progress"><span style="width:${v}%"></span></div><b>${v}</b></div>`,
      )
      .join(
        "",
      )}</div></article><article class="card"><h3>Doğrulanmış başarılar</h3><div class="list"><div class="achievement"><div class="iconbox"><i data-lucide="badge-check"></i></div><div><b>Kulüp Kaşifi</b><div class="muted">3 farklı topluluk</div></div></div><div class="achievement"><div class="iconbox"><i data-lucide="heart-handshake"></i></div><div><b>İyilik Elçisi</b><div class="muted">12 hizmet saati</div></div></div></div></article></div>`;
  }
  function renderNotifications() {
    const el = q("#notificationList");
    if (!el) return;
    const data = Store.get("notifications", notifications);
    el.innerHTML = data.length
      ? data
          .map(
            (n) =>
              `<div class="list-item ${n.read ? "" : "unread"}"><div><b>${esc(n.title)}</b><div class="muted">${esc(n.body)}</div></div><small class="muted">${esc(n.time)}</small></div>`,
          )
          .join("")
      : '<div class="empty">Yeni bildirim yok.</div>';
  }
  window.markAllRead = function () {
    Store.set(
      "notifications",
      Store.get("notifications", notifications).map((x) => ({
        ...x,
        read: true,
      })),
    );
    renderNotifications();
    toast("Tüm bildirimler okundu");
  };
  window.downloadTranscript = function () {
    window.print();
  };
  function renderApprovals() {
    const el = q("#approvalList");
    if (!el) return;
    const data = Store.get("approvals", approvals);
    q("#approvalCount").textContent = `${data.length} bekleyen`;
    el.innerHTML = data.length
      ? data
          .map(
            (a) =>
              `<div class="list-item"><div><b>${esc(a.title)}</b><div class="muted">${esc(a.owner)} · ${esc(a.type)} · ${esc(a.risk)}</div></div><div class="approval-actions"><button class="btn btn-light btn-sm" onclick="decideApproval(${a.id},false)">İade et</button><button class="btn btn-primary btn-sm" onclick="decideApproval(${a.id},true)">Onayla</button></div></div>`,
          )
          .join("")
      : '<div class="empty">Bekleyen işlem yok.</div>';
  }
  window.decideApproval = function (id, ok) {
    Store.set(
      "approvals",
      Store.get("approvals", approvals).filter((x) => x.id !== id),
    );
    audit(ok ? "approval.accept" : "approval.return", { id });
    renderApprovals();
    toast(ok ? "İçerik onaylandı" : "Düzeltme için iade edildi");
  };
  function renderClubs() {
    const el = q("#clubCards");
    if (!el) return;
    el.innerHTML = clubs
      .map(
        (c) =>
          `<article class="card"><div class="iconbox"><i data-lucide="users-round"></i></div><h3>${esc(c.name)}</h3><div class="club-kpi"><div><strong>${c.members}</strong><small class="muted">Üye</small></div><div><strong>${c.events}</strong><small class="muted">Etkinlik</small></div><div><strong>%${c.rate}</strong><small class="muted">Memnuniyet</small></div></div></article>`,
      )
      .join("");
  }
  window.inviteClubManager = function () {
    const email = prompt("Davet edilecek @dogus.edu.tr adresi");
    if (!email) return;
    if (!/^[^@]+@dogus\.edu\.tr$/i.test(email))
      return toast("Kurumsal e-posta adresi gerekli");
    audit("club.manager.invite", { domain: "dogus.edu.tr" });
    toast("Davet taslağı oluşturuldu");
  };
  function enhanceEvents() {
    const search = q("#events .search");
    if (search)
      search.addEventListener("input", (e) => {
        const term = e.target.value.toLocaleLowerCase("tr");
        document
          .querySelectorAll("#studentEvents .event-card")
          .forEach(
            (card) =>
              (card.hidden = !card.textContent
                .toLocaleLowerCase("tr")
                .includes(term)),
          );
      });
    const grid = q("#studentEvents");
    if (grid && grid.firstElementChild)
      grid.firstElementChild.classList.add("recommendation");
  }
  document.addEventListener("DOMContentLoaded", () => {
    banner();
    renderTranscript();
    renderNotifications();
    renderApprovals();
    renderClubs();
    enhanceEvents();
    window.lucide?.createIcons({ attrs: { "stroke-width": 1.8 } });
  });
})();
