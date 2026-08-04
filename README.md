# Project Relay v0.8.4 — Profil, Klan ve Kariyer Hazırlığı

Project Relay; oyuncuların merkezî çekirdek çevresine yönlü bağlantılarla modül
yerleştirip sunucu yetkili, deterministik devre savaşları yaptığı Flutter +
FastAPI projesidir.

## v0.8.4 odak noktası

- Profil içeriğinin tek yerde toplanması ve **Arkadaşlar** bölümünün Genel'in
  yanına ayrı sekme olarak eklenmesi
- Sosyal Merkez kabuğunun kaldırılması; profil düzenleme ve arkadaşlıkların
  Profil içinde, klanın yalnız Klan ekranında sunulması
- Günlük görev ve başarım ödüllerinin Profil ekranında alınması; Kariyer
  ekranından yinelenen görev/başarım alanlarının kaldırılması
- Bütün ana oyun ekranlarında etkin profil kartı, Ayarlar ve Nasıl Oynanır
  erişimi sağlayan ortak üst sağ eylem alanı
- Kariyer hazırlığının ayrı düz metin sayfası yerine doğrudan düzenlenebilir
  oyuncu devresi ve karşı koşu devresiyle aynı ekranda yapılması
- Kariyer savaşı başlamadan önce güncel devrenin doğrulanıp sunucuya kaydedilmesi
- Komutan Sistemi ve Oyuncu Tarzı Profilinin uygulanmadan özellik havuzunda
  korunması

API ve istemci sürümleri `0.8.4` / `0.8.4+50` olarak güncellendi. PostgreSQL
şeması, Alembic başı `20260801_0009`, savaş kuralları `0.8` ve oyun dengesi
değişmedi.

Ayrıntılı sürüm belgesi:
[docs/V0.8.4_PROFIL_KLAN_VE_KARIYER_HAZIRLIK.md](docs/V0.8.4_PROFIL_KLAN_VE_KARIYER_HAZIRLIK.md)

Test raporu:
[docs/V0.8.4_TEST_RAPORU.md](docs/V0.8.4_TEST_RAPORU.md)

Özellik havuzu:
[docs/OZELLIK_HAVUZU.md](docs/OZELLIK_HAVUZU.md)

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

v0.9.0 kapalı alfa hazırlığında telemetri, hata kayıtları, cihaz/ekran QA ve
gerçek oyuncu test akışı kurulacaktır. Canlı 1v1, gerçek para, enerji kapısı,
kalıcı savaş gücü ve özellik havuzundaki Komutan Sistemi bu sürümde bulunmaz.
