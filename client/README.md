# Project Relay Flutter İstemcisi — v0.8.5 rev2

İstemci; Ana Merkez, Çevrimiçi Savaş, doğrudan devre düzenlemeli Kariyer,
Antrenman, sade Klan, Koleksiyon, Mağaza, birleşik Profil, Nasıl Oynanır ve
Ayarlar akışlarını içerir.

## v0.8.5 rev2

- Profil; Genel, Arkadaşlar, Derece ve Sezon, Maç Geçmişi, Günlük Görevler ve
  Başarımlar bölümlerini içerir.
- Profil Genel bölümünde yalnız sosyal kimlik ve küçük düzenleme eylemi kalır;
  yinelenen oyuncu/seviye/kredi çubuğu ve Klan düğmesi bulunmaz.
- Arkadaşlık istekleri, arkadaş listesi ve oyuncu araması Profil içindeki ayrı
  Arkadaşlar sekmesindedir.
- Klan ekranı yalnız Klan Özeti, Üyeler, Klan Etkinliği ve Ayarlar alanlarını
  taşır.
- Günlük görev ve başarım ödülleri Profil içinden alınır; Kariyer ekranında
  yinelenmez.
- Ortak `AppHeaderActions`, oyun ekranlarında etkin Profil, Ayarlar ve Nasıl
  Oynanır erişimi sağlar.
- Kariyer hazırlığında oyuncu devresi doğrudan düzenlenir; koşu rakibi aynı
  ekranda gösterilir. Koşu veya savaş eylemi öncesinde devre doğrulanır ve
  sunucuya kaydedilir.
- Çevrimiçi, Antrenman ve Kariyer editörleri ayrı devre durumları kullanır.
- Mağaza Tümü, Modül, Devre Kartı ve Profil sekmeleriyle tek sayfada çalışır.
- Ana merkez widget testi, editör başlıklarındaki gerçek `v0.8.5` metnini doğrular.
- İstemci sürümü: `0.8.5+53`
- Sunucu API sürümü: `0.8.4`
- Savaş kuralları: `0.8`

Komutan seçimi ve oyuncu tarzı unvanı uygulanmaz; özellik havuzunda korunur.

## Yerel kabul

```powershell
.\tool\bootstrap_client.ps1
```

Bu komut Flutter proje iskeletini hazırlar, `flutter pub get`,
`flutter analyze` ve `flutter test` çalıştırır.

## Çalıştırma

```powershell
flutter run -d edge --dart-define=RELAY_API_URL=http://127.0.0.1:8000
```
