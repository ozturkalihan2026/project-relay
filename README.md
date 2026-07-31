# Project Relay v0.5.0 — Derece, Haftalık Lig ve Maç Geçmişi

Project Relay, merkezî çekirdek çevresine en fazla altı modül yerleştirilen,
sunucu yetkili asenkron devre savaşıdır. Oyuncu kartını kurar; sunucu benzer
modül sayısındaki kayıtlı gerçek oyuncu düzenini seçer, deterministik savaşı
hesaplar ve sonucu animasyonlu tekrar olarak istemciye gönderir.

## v0.5.0 odak noktası

- Gerçek oyuncuya karşı tamamlanan asenkron maçlar için ELO benzeri derece
  puanı eklendi. İlk puan 1000, K katsayısı 32'dir.
- Kesin beraberlik iki oyuncunun derecesini değiştirmez. Beraberlik kariyer ve
  haftalık lig kaydında sayılır; haftalık lige 1 puan verir.
- Galibiyet haftalık lige 3 puan verir. Mağlubiyet puan vermez.
- Antrenman maçları ve gerçek rakip bulunamadığında kullanılan güvenli sunucu
  botu dereceyi etkilemez.
- Maç derecesi `match_id` ile yalnız bir kez işlenir; aynı isteğin yinelenmesi
  çift puan oluşturmaz.
- Kariyer ekranı derece, zirve puanı, galibiyet/beraberlik/mağlubiyet kaydı,
  haftalık sıra, gerçek rakip oranı, liderlik tablosu ve maç geçmişini gösterir.
- Her iki gerçek katılımcı maçı kendi perspektifinden açabilir. Kartlar, sonuç,
  replay tarafları ve checksum oyuncu bakışına göre güvenli biçimde çevrilir.
- PostgreSQL şemasına `player_ratings`, `league_entries` ve
  `match_rating_changes` tabloları Alembic `20260731_0003` ile eklendi.
- Savaş kuralları `0.8`, sekiz temel modül, enerji ekonomisi ve denge değerleri
  değiştirilmedi. Kalıcı hesap gücü artışı eklenmedi.

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

Swagger belgesi servis çalışırken `http://127.0.0.1:8000/docs` adresindedir.
