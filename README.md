# Project Relay v0.8.3 — Ana Merkez ve Menü Düzeni

Project Relay; oyuncuların merkezî çekirdek çevresine yönlü bağlantılarla modül
yerleştirip sunucu yetkili, deterministik devre savaşları yaptığı Flutter +
FastAPI projesidir.

## v0.8.3 odak noktası

- Ana ekranın üst oyuncu çubuğu ve beş ürün alanıyla sadeleştirilmesi
- Üst çubukta profil, seviye, Devre Kredisi, Ayarlar ve Nasıl Oynanır erişimi
- Ödülü alınabilir günlük görev veya başarım olduğunda profil bildirim noktası
- **Oyna** altında Çevrimiçi Savaş, Kariyer ve Antrenmanın birleştirilmesi
- **Profil** altında Genel, Derece ve Sezon, Maç Geçmişi, Günlük Görevler ve
  Başarımların toplanması
- **Klan** alanında özet, üyeler, etkinlik ve ayarlar alt bölümleri
- **Koleksiyon** alanının Kit ve Kozmetik olarak ayrılması
- Satın alınmamış kozmetikler için ayrı **Mağaza** girişi
- Komutan Sistemi ile Oyuncu Tarzı Profilinin uygulanmadan özellik havuzunda
  korunması

API ve istemci sürümleri `0.8.3` / `0.8.3+47` olarak güncellendi. PostgreSQL
şeması, Alembic başı `20260801_0009`, savaş kuralları `0.8` ve oyun dengesi
değişmedi.

**rev1 hotfix:** Yerel Flutter analizinde bulunan gereksiz null-aware erişimler
ve klan alt bölümündeki ad çakışması giderildi. İstemci yapı numarası
`0.8.3+46` oldu.

**rev2 hotfix:** 800×600 widget test yüzeyinde profil yatay sekmeleri ve
Koleksiyon geri düğmesi doğru kaydırma alanları kullanılarak görünür hâle
getirildi. İstemci yapı numarası `0.8.3+47` oldu.

Ayrıntılı sürüm belgesi:
[docs/V0.8.3_ANA_MERKEZ_VE_MENU_DUZENI.md](docs/V0.8.3_ANA_MERKEZ_VE_MENU_DUZENI.md)

Test raporu:
[docs/V0.8.3_TEST_RAPORU.md](docs/V0.8.3_TEST_RAPORU.md)

rev2 widget test hotfix raporu:
[docs/V0.8.3_REV2_WIDGET_TEST_KAYDIRMA_HOTFIX.md](docs/V0.8.3_REV2_WIDGET_TEST_KAYDIRMA_HOTFIX.md)

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
