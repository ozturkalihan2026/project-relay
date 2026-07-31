# Project Relay v0.6.2 — Koleksiyon ve Kontrollü Kit

Project Relay, merkezî çekirdek çevresine en fazla altı modül yerleştirilen,
sunucu yetkili asenkron devre savaşıdır. v0.6.2, kariyer ve rekabet temelinin
üzerine güç satmayan koleksiyon ekonomisi ile sekiz yuvalı hazırlık kitini ekler.

## v0.6.2 odak noktası

- Ana menüde ayrı **Koleksiyon** ekranı
- Tam bir Jeneratör içeren, sekiz modüllük kontrollü kit
- Savaş kartında altı aktif modül ve rakibe göre iki yedek kit seçeneği
- Editör paletlerinde aktif kitte kalan modül adetleri
- Çevrimiçi ve Kariyer kartlarını sunucuda kit sınırına göre doğrulama
- Modül kaplaması, devre kartı teması ve profil çerçevesi koleksiyonu
- Devre Kredisiyle çalışan, kalıcı savaş gücü satmayan kozmetik mağaza
- Kalıcı sahiplik ve kuşanma için `player_cosmetics` ile `player_loadouts`
- Alembic `20260731_0007`
- API `0.6.2`, Flutter istemcisi `0.6.2+39`, savaş kuralları `0.8`

Ayrıntılı kararlar ve kabul ölçütleri:
[docs/V0.6.2_KOLEKSIYON_VE_KONTROLLU_KIT.md](docs/V0.6.2_KOLEKSIYON_VE_KONTROLLU_KIT.md)

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
