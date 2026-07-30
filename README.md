# Project Relay v0.4.13 — Dengeli Modül Paleti ve Güçlü Savaş Etiketleri

Project Relay, merkezî çekirdek çevresine en fazla altı modül yerleştirilen,
sunucu yetkili asenkron devre savaşı prototipidir.

## v0.4.13 odak noktası

- Editördeki 4×2 modül seçim kartları 82 px'ten 74 px'e indirildi. Kartların
  simge, ad ve özellik bilgisi korunurken gereksiz dikey boşluk azaltıldı.
- Kartlar arasındaki yatay/dikey boşluk ve palet dış dolgusu küçük ölçüde
  sıkılaştırıldı. Geniş ekranda kart genişliği 255 px ile sınırlandırılıp palet
  içinde ortalandı; v0.4.11'deki sonlu `Stack` yüksekliği korundu.
- Savaş devrelerinin üstündeki **SEN** ve rakip adı 11 px'ten 14 px'e
  çıkarılıp daha kalın gösterildi. Uzun rakip adları devre genişliğinde
  güvenli biçimde kısaltılır.
- **Yeni Oyun** eylemi aynı 220×40 px kutuyu korurken **YENİ OYUN** olarak,
  14 px kalın ve harf aralığı artırılmış biçimde yeniden tasarlandı.
- v0.4.12 tek ekran savaş yerleşimi, orta olay paneli genişliği ve devre
  ölçüleri değişmedi.

Sunucu motoru, PostgreSQL şeması, enerji ekonomisi, eşleşme ve hedefleme
kuralları değişmemiştir.

## Çalıştırma

Docker Desktop açıkken proje kökünde:

```powershell
docker compose up --build
```

Ayrı terminalde:

```powershell
cd client
flutter pub get
flutter run -d chrome --dart-define=RELAY_API_URL=http://127.0.0.1:8000
```
