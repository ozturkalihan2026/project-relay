# Project Relay v0.8.9 — Kariyer Hazırlığı ve Kompakt Modül Paleti

Project Relay; oyuncuların merkezî çekirdek çevresine yönlü bağlantılarla modül
yerleştirip sunucu yetkili, deterministik devre savaşları yaptığı Flutter +
FastAPI projesidir.

## v0.8.9 odak noktası

- Kariyerde modül seçimi, oyuncu devresi ve koşu rakibi üç ayrı karttır.
- Oyuncu ve rakip devreleri aynı görsel ölçekte gösterilir.
- Kariyer yenilgisi doğrudan yeni koşu hazırlığına döner.
- Çevrimiçi ve Antrenman modül paletleri üçte bir daha kısa kartlar kullanır.

- Savaş hazırlıklarında **Menüye Dön** ile Oyna menüsüne, diğer ürün
  ekranlarında **Ana Menüye Dön** ile doğrudan ana merkeze dönüş
- Mağazada daha küçük kareye yakın kozmetik kartları ve yüksek yoğunluklu grid
- Profil > Kozmetik altında Modül, Devre Kartı ve Profil kategori sekmeleri
- Kariyerde solda tek sütun modül paleti, yanında oyuncu devresi ve aynı satırda
  eşit ölçekli koşu rakibi devresi
- Çevrimiçi, Antrenman ve Kariyer için ayrı devre durumlarının korunması
- Komutan Sistemi ile Oyuncu Tarzı Profilinin özellik havuzunda tutulması

Sunucu API sürümü değiştirilmedi; Flutter istemci sürümü `0.8.8+59`'dir.
PostgreSQL şeması, Alembic başı `20260801_0009`, savaş kuralları `0.8` ve oyun
dengesi değişmedi.

Güncel kapsam belgesi:
[docs/V0.8.8_MENU_MAGAZA_PROFIL_KARIYER.md](docs/V0.8.8_MENU_MAGAZA_PROFIL_KARIYER.md)

Güncel test raporu:
[docs/V0.8.8_TEST_RAPORU.md](docs/V0.8.8_TEST_RAPORU.md)

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
