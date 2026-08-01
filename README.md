# Project Relay v0.8.0 — Sosyal Yapı ve Klan Temeli

Project Relay; oyuncuların merkezî çekirdek çevresine yönlü bağlantılarla modül
yerleştirip sunucu yetkili, deterministik devre savaşları yaptığı Flutter +
FastAPI projesidir.

## v0.8.0 odak noktası

- Oyuncuya özel sosyal durum mesajı ve favori modül
- Oyuncu adına göre arama
- Gönderilen ve gelen arkadaşlık istekleri
- Arkadaşlık isteğini kabul etme, reddetme ve arkadaşlıktan çıkarma
- Bir oyuncunun aynı anda yalnızca bir klana üye olabildiği klan temeli
- Açık klan keşfi, klan kurma, katılma ve ayrılma
- Klan lideri ve üye rollerinin sunucu tarafında doğrulanması
- Klan başına 20 üye sınırı
- Liderin, klanında başka üyeler varken ayrılamaması
- Sosyal ve klan özelliklerinin rekabetçi savaş gücü vermemesi
- Alembic `20260801_0009` geçişi
- Flutter istemcisi `0.8.0+42`, API `0.8.0`, savaş kuralları `0.8`

v0.7.0'daki Alfa Sezonu, geri bildirim ve kötüye kullanım korumaları ile
v0.6.2 rev1'deki kontrollü sekizli kit, görsel kozmetikler, sürdürülebilir
XP/Devre Kredisi ekonomisi ve seviye kutlamaları korunur.

Ayrıntılı sürüm belgesi:
[docs/V0.8.0_SOSYAL_VE_KLAN.md](docs/V0.8.0_SOSYAL_VE_KLAN.md)

## Çalıştırma

Docker Desktop açıkken proje kökünde:

```powershell
docker compose down
docker compose up --build -d
docker compose logs api --tail 100
```

İstemciyi doğrulamak ve çalıştırmak için ayrı terminalde:

```powershell
cd client
.\tool\bootstrap_client.ps1
flutter run -d edge --dart-define=RELAY_API_URL=http://127.0.0.1:8000
```

Swagger belgesi servis çalışırken `http://127.0.0.1:8000/docs` adresindedir.

## Sonraki hedef

v1.0.0 açık beta öncesinde; onboarding, hata telemetrisi, performans ve gerçek
oyuncu alfa verileriyle dengeleme tamamlanacaktır. Canlı 1v1, gerçek para,
enerji kapısı ve kalıcı savaş gücü bu sürümde bulunmaz.
