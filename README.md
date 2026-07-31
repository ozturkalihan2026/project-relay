# Project Relay v0.6.2 rev1 — Görsel Kozmetikler ve Dengeli İlerleme

Project Relay, merkezî çekirdek çevresine en fazla altı modül yerleştirilen,
sunucu yetkili asenkron devre savaşıdır. v0.6.2 rev1, kontrollü sekizli kit ve
koleksiyon temelini gerçek görsel kozmetiklere, sürdürülebilir XP/Kredi
ekonomisine ve seviye kutlamasına bağlar.

## v0.6.2 rev1 odak noktası

- Ana menüde ayrı **Koleksiyon** ekranı
- Tam bir Jeneratör içeren, sekiz modüllük kontrollü kit
- Savaş kartında altı aktif modül ve rakibe göre iki yedek kit seçeneği
- Editör paletlerinde aktif kitte kalan modül adetleri
- Çevrimiçi ve Kariyer kartlarını sunucuda kit sınırına göre doğrulama
- Kuşanılan devre kartı temasının editör ve savaş tekrarında görünmesi
- Modül kaplamasının modül, port ve oyuncu saldırı renklerine uygulanması
- Profil çerçevesinin oyuncu bilgi çubuğunda görünmesi
- Açıklanmış **Boss Güçlendirici Kademeleri** ve kalıcı güç adaleti
- İlk beş seviyeyi koruyan, üst seviyeleri kontrollü yavaşlatan XP eğrisi
- Dengelenmiş savaş/görev/kariyer ödülleri ve 4.450 kredilik mağaza hedefi
- Seviye atlamada yeni seviye ve kilit açılımını gösteren kutlama rozeti
- API `0.6.2`, Flutter istemcisi `0.6.2+40`, savaş kuralları `0.8`

Ayrıntılı kararlar ve kabul ölçütleri:
[docs/V0.6.2_REV1_KOZMETIK_EKONOMI_VE_SEVIYE.md](docs/V0.6.2_REV1_KOZMETIK_EKONOMI_VE_SEVIYE.md)

## Sonraki adım

v0.7.0; sezon ilerlemesi, kapalı alfa ölçümleri, denge telemetrisi ve kötüye
kullanım korumasına odaklanacaktır. Rekabetçi PvP için kısmi keşif ve sınırlı
yeniden düzenleme de bu ölçüm aşamasında değerlendirilecektir.

## Çalıştırma

Docker Desktop açıkken proje kökünde:

```powershell
docker compose up --build
```

Ayrı terminalde:

```powershell
cd client
.\tool\bootstrap_client.ps1
flutter run -d edge --dart-define=RELAY_API_URL=http://127.0.0.1:8000
```

Swagger belgesi servis çalışırken `http://127.0.0.1:8000/docs` adresindedir.
