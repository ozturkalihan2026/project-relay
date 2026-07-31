# Project Relay v0.6.1 — Kariyer Koşusu ve Rakip Ön İzlemesi

Project Relay, merkezî çekirdek çevresine en fazla altı modül yerleştirilen,
sunucu yetkili asenkron devre savaşıdır. v0.6.1, v0.6.0 ilerleme temelini
beş aşamalı oynanabilir kariyer koşusuna dönüştürür.

## v0.6.1 odak noktası

- Kariyer koşusu beş bağlantılı savaştan oluşur; beşinci aşama bölüm sonu
  devresidir.
- Oyuncu, her savaştan önce sunucunun gerçekten kullanacağı rakip devreyi tam
  yerleşim ve yönleriyle görür.
- **Devremi Düzenle** eylemi özel kariyer editörünü açar; oyuncu karşı
  kombinasyonunu kaydedip aynı aşamaya döner.
- İlk dört zaferden sonra üç geçici güçlendiriciden biri seçilir. Etkiler yalnız
  aktif koşuda çalışır ve koşu sonunda sıfırlanır.
- Beraberlik veya mağlubiyet koşuyu bitirir. Sonuç, XP ve Devre Kredisi ödülü
  sunucu tarafından ve yalnız bir kez işlenir.
- `career_runs` tablosu Alembic `20260731_0005` ile eklendi.
- API `0.6.1`, istemci `0.6.1+36`, savaş kuralları `0.8`dir.

Ayrıntılı karar ve kabul ölçütleri:
[docs/V0.6.1_KARIYER_KOSUSU_VE_RAKIP_ONIZLEME.md](docs/V0.6.1_KARIYER_KOSUSU_VE_RAKIP_ONIZLEME.md)

## Sonraki adım

v0.6.2; kozmetik mağaza, koleksiyon görünümü ve kontrollü sekizli kit sistemini
ekleyecek. Rekabetçi PvP için kısmi keşif ve sınırlı yeniden düzenleme ayrıca
ölçülüp planlanacaktır.

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
