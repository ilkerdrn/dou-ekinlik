# DOU Campus — Rakip fark analizi

İncelenen ürün kümeleri: Ready Education/CampusGroups, Suitable ve Modern Campus Involve.

| Rakip yeteneği               | DOU Campus karşılığı                              | Durum                          |
| ---------------------------- | ------------------------------------------------- | ------------------------------ |
| Etkinlik keşfi, RSVP, takvim | Etkinlik listesi, kayıt/favori, yaklaşan kayıtlar | Hazır                          |
| QR/mobil check-in            | Kamera taraması + süreli oturum modeli            | Entegrasyon bilgisi bekliyor   |
| Çoklu check-in/no-show       | Attendance modeli ve yönetim operasyonu           | Backend bağlantısında açılacak |
| Kişiselleştirilmiş öneriler  | İlgi ve katılım temelli “Sana özel” alanı         | Hazır                          |
| Kulüp yönetimi               | Kulüp performansı ve yönetici daveti              | Hazır                          |
| İçerik onay iş akışı         | Etkinlik/challenge/ödül onay merkezi              | Hazır                          |
| Yetkinlik ve dijital rozet   | Yetkinlik matrisi ve doğrulanmış başarılar        | Hazır                          |
| Sosyal transkript            | Yazdırılabilir sosyal transkript + SQL görünümü   | Hazır                          |
| Hizmet saati takibi          | Doğrulanmış service_hours modeli                  | Hazır                          |
| Geri bildirim                | Katılıma bağlı puan ve yorum modeli               | Hazır                          |
| SIS/SSO entegrasyonu         | Entra ID + Supabase Auth hazırlığı                | Tenant/Client bilgisi bekliyor |
| Yönetim analitiği            | Katılım, bölüm, geri dönüş, CSV raporu            | Hazır; gerçek veri bekliyor    |

Üretim engeli yalnızca dış servis bağlantılarıdır: Supabase Project URL, publishable key, Entra Tenant ID ve Client ID. Secret değerleri kaynak koda eklenmez.
