# Project Relay v0.8.18 — Sabit Üst Bar ve Savaş Sunumu

Project Relay; oyuncuların merkezî çekirdek çevresine yönlü bağlantılarla
modül yerleştirdiği, savaşların sunucuda deterministik olarak çözüldüğü Flutter
+ FastAPI strateji oyunudur.

## v0.8.18 odak noktası

- Profil solda, Devre Kredisi/Ayarlar/Yardım sağda olacak şekilde üst bar standardı
  tüm ana ekranlarda korunur; replay savaş ekranında üst bar scroll alanından ayrıdır.
- Devre Kredisi için tek amblem kullanılır; üst bar, mağaza ve ödül popup'ları aynı
  `CircuitCreditGlyph` bileşenini paylaşır.
- İstatistiklerde sezon adı `SEZON YYYY.MM`, Project Relay amblemi ve ilk üç için
  altın/gümüş/bronz madalya sunumu kullanılır.
- Oyna ekranına düşük opaklıklı 4×4 devre kartı arka planı eklenmiştir.
- Ortak savaş replay görsel katmanı saldırı izi, impact halkası/parçacıkları, kalkan,
  onarım, aşırı ısınma, enerji yetersizliği ve devre dışı kalma geri bildirimleriyle
  güçlendirilmiştir.
- v0.8.17'deki kariyer kart ölçüleri ve süre sonu tie-break kuralları korunur.

## Sürüm bilgileri

- Sunucu API: `0.8.18`
- Flutter istemci: `0.8.18+74`
- Savaş kuralları: `0.8`
- Alembic başı: `20260807_0011`

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
