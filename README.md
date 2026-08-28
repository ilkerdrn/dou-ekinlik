# DOU Campus

Doğuş Üniversitesi için etkinlik, challenge, QR katılım doğrulama, XP, lig ve ödül deneyimi.

## Ekranlar

- `index.html`: tanıtım ve giriş
- `student.html`: öğrenci deneyimi
- `admin.html`: yönetim ve kulüp operasyonları

Demo öğrenci: `999999999 / demo1234`

Demo yönetim: `admin@dogus.edu.tr / admin1234`

GitHub Pages demosu verileri tarayıcıda tutar. Üretimde üniversite SSO, sunucu taraflı imzalı QR doğrulaması, PostgreSQL/RLS ve merkezi öğrenci sistemi entegrasyonu gerekir.

## Üretime geçiş

- Veritabanı ve RLS şeması: `supabase/schema.sql`
- Güvenli QR RPC, yetkinlik, geri bildirim ve sosyal transkript: `supabase/production-hardening.sql`
- Supabase/Entra örnek ayarı: `config.example.js`
- Rakip özellik fark analizi: `docs/COMPETITOR-GAP-ANALYSIS.md`
- Aktivasyon adımları: `docs/PRODUCTION-CHECKLIST.md`
- KVKK taslak ekranı: `privacy.html`

`config.js` varsayılan olarak güvenli demo modundadır. Gerçek anahtarlar repoya yazılmamalıdır.
