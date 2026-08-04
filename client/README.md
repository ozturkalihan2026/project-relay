# Project Relay Flutter İstemcisi — v0.8.3

İstemci; sade Ana Merkez, Çevrimiçi Savaş, Kariyer, Antrenman, Klan,
Koleksiyon, Mağaza, Profil, Nasıl Oynanır ve Ayarlar akışlarını içerir.

## v0.8.3 rev1

- `flutter analyze` ile bulunan null-aware erişim uyarıları giderildi.
- Klan alt bölüm durum değişkeninin `_clanSection` metoduyla ad çakışması
  kaldırıldı.
- İstemci yapı numarası `0.8.3+46` oldu.

## v0.8.3

- Üst oyuncu çubuğu profil, seviye ve Devre Kredisini gösterir.
- Ayarlar ve Nasıl Oynanır ana ekranın üst simgelerindedir.
- Ana merkez beş alana ayrılır: Oyna, Klan, Koleksiyon, Mağaza ve Profil.
- Oyna ekranı Çevrimiçi Savaş, Kariyer ve Antrenmanı birlikte sunar.
- Profil; Genel, Derece ve Sezon, Maç Geçmişi, Günlük Görevler ve Başarımlar
  bölümlerini içerir.
- Alınabilir görev veya başarım ödülü olduğunda profil üzerinde bildirim noktası
  görünür.
- Koleksiyon Kit ve Kozmetik bölümlerine ayrılır.
- Mağaza yalnız satın alınmamış görsel içerikleri gösterir.
- Klan alanı özet, üyeler, etkinlik ve ayarlar olarak ayrılır.
- İstemci sürümü: `0.8.3+46`
- Sunucu API sürümü: `0.8.3`
- Savaş kuralları: `0.8`

Komutan seçimi ve oyuncu tarzı unvanı bu sürümde uygulanmaz; özellik havuzunda
korunur.

## Yerel kabul

```powershell
.\tool\bootstrap_client.ps1
```

Bu komut sırasıyla Flutter proje iskeletini hazırlar, `flutter pub get`,
`flutter analyze` ve `flutter test` çalıştırır.

## Çalıştırma

```powershell
flutter run -d edge --dart-define=RELAY_API_URL=http://127.0.0.1:8000
```
