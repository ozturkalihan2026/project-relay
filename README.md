# Project Relay v0.8.11 — Arcade-Tech Görsel Yenileme

Project Relay; oyuncuların merkezî çekirdek çevresine yönlü bağlantılarla
modül yerleştirdiği, savaşların sunucuda deterministik olarak çözüldüğü Flutter
+ FastAPI strateji oyunudur.

## v0.8.11 odak noktası

- Mevcut koyu teknik kimlik korunurken daha canlı **arcade-tech** renk sistemi
  uygulandı.
- Uygulamanın tüm rotalarında görünen katmanlı mavi/lacivert arka plan gradyanı
  eklendi.
- Cyan, mint, amber ve coral vurgularına magenta ile violet destek renkleri
  eklendi.
- Kart, buton, giriş alanı, ikon düğmesi, ilerleme çubuğu ve bildirim yüzeyleri
  daha parlak ve daha sıcak hale getirildi.
- Ana merkezde Oyna kartı üç tonlu kahraman gradyanına geçirildi; Klan,
  İstatistikler, Mağaza ve Profil kendi vurgu renkleriyle ayrıştırıldı.
- Oyna ekranında Çevrimiçi Savaş, Kariyer ve Antrenman kartlarının mod kimliği
  daha belirgin hale getirildi.
- Oyuncu durum çubuğu, mağaza ürün ön izlemeleri ve Profil kozmetik kartları
  renkli gradyan ve düşük yoğunluklu parıltılarla yenilendi.
- v0.8.10'daki moda özel başlangıç sekizlileri, devre izolasyonu ve oyun
  davranışları değiştirilmedi.

## Sürüm bilgileri

- Sunucu API: `0.8.16`
- Flutter istemci: `0.8.11+63`
- Savaş kuralları: `0.8`
- Alembic başı: `20260806_0010`

Bu sürüm istemci ağırlıklı görsel yenilemedir. Veritabanı şeması, savaş motoru,
modül değerleri ve sunucu sözleşmeleri değişmemiştir.

## Çalıştırma

Docker Desktop açıkken proje kökünde:

```powershell
docker compose down
docker compose up --build -d
docker compose logs api --tail 100
```

İstemci kabulü ve çalıştırma:

```powershell
cd client
.\tool\bootstrap_client.ps1
flutter run -d edge --dart-define=RELAY_API_URL=http://127.0.0.1:8000
```

Swagger belgesi servis çalışırken `http://127.0.0.1:8000/docs` adresindedir.

## Sonraki hedef

v0.9.0 kapalı alfa hazırlığında telemetri, hata kayıtları, cihaz/ekran QA ve
gerçek oyuncu test akışı kurulacaktır. Komutan Sistemi özellik havuzunda kalır.
