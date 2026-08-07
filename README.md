# Project Relay v0.8.10 — Moda Özel Sekizliler ve Ayrı Devre Durumları

Project Relay; oyuncuların merkezî çekirdek çevresine yönlü bağlantılarla
modül yerleştirdiği, savaşların sunucuda deterministik olarak çözüldüğü Flutter
+ FastAPI strateji oyunudur.

## v0.8.10 odak noktası

- Kariyer modül paleti **2 sütun × 4 sıra** düzenine geçirildi.
- Kariyer **Doğrula** düğmesi oyuncu devresinden Modül Seç kartına taşındı.
- Çevrimiçi Savaş, Antrenman ve Kariyer için ayrı başlangıç sekizlileri eklendi.
- Sekizli kaydedildiğinde ilgili savaş editörünün paleti sayfa yenilemeden anında
  güncellenir.
- Çevrimiçi, Antrenman ve Kariyer devre sağlayıcılarının birbirine veri yazması
  engellendi.
- Çevrimiçi ve Kariyer kayıtları sunucuda kendi mod sekizlilerine göre
  doğrulanır.
- Dar modül paletinde kartı geri bırakma göstergesinin taşması giderildi.

## Sürüm bilgileri

- Sunucu API: `0.8.10`
- Flutter istemci: `0.8.10+62`
- Savaş kuralları: `0.8`
- Alembic başı: `20260806_0010`

Yeni migration, moda özel sekizlilerin saklanacağı JSON alanını ekler. Eski
oyuncularda servis ilk koleksiyon erişiminde mevcut tek sekizliyi üç mod için
uyumlu başlangıç değeri olarak kullanır; ilk mod kaydında bu üçlü yapı kalıcı
hâle gelir. Sonraki kayıtlar yalnız seçilen modun sekizlisini değiştirir.

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
