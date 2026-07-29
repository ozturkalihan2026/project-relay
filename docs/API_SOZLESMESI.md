# Project Relay — API Sözleşmesi v0.4.2

Bu sürüm, Flutter/Flame istemcisinin kullandığı kalıcı asenkron PvP
protokolüdür. Bütün yollar `/api/v1` altında sürümlenir. Etkileşimli Swagger
belgesi servis çalışırken `/docs` adresindedir.

## Uç noktalar

| Yöntem | Yol | Amaç |
|---|---|---|
| `GET` | `/healthz` | Sürüm ve çalışma durumu |
| `POST` | `/api/v1/auth/guest` | Güvenli adlı kalıcı misafir oluşturma |
| `POST` | `/api/v1/auth/refresh` | Yenileme JWT'sini döndürme |
| `GET` | `/api/v1/me` | Oyuncu ve kayıtlı kartı okuma |
| `PUT` | `/api/v1/me/board` | Geçerli oyuncu kartını ekleme/güncelleme |
| `GET` | `/api/v1/modules` | Sekiz başlangıç modülünün sunucu kataloğu |
| `GET` | `/api/v1/bots` | Kullanılabilir sabit bot düzenleri |
| `POST` | `/api/v1/boards/validate` | Kart ve enerji bağlantısı önizlemesi |
| `POST` | `/api/v1/matches/bot` | Sunucuda bot savaşı oluşturma |
| `POST` | `/api/v1/matches/async` | Kayıtlı kartla asenkron rakip bulma |
| `GET` | `/api/v1/matches/{match_id}` | Olaylar hariç maç sonucu |
| `GET` | `/api/v1/matches/{match_id}/replay` | Animasyon için olay akışı |
| `POST` | `/api/v1/replays/verify` | Tekrar SHA-256 özetini doğrulama |

## Kart örneği

```json
{
  "name": "Mavi Devre",
  "modules": [
    {
      "module_id": "P-GEN",
      "kind": "generator",
      "row": 0,
      "column": 1,
      "orientation": "south",
      "level": 1
    },
    {
      "module_id": "P-LASER",
      "kind": "laser",
      "row": 0,
      "column": 2,
      "orientation": "east",
      "level": 1
    }
  ]
}
```

Kart doğrulama:

```powershell
curl.exe -X POST http://localhost:8000/api/v1/boards/validate `
  -H "Content-Type: application/json" `
  --data-binary "@ornek-kart.json"
```

Bot maçı:

```powershell
curl.exe -X POST http://localhost:8000/api/v1/matches/bot `
  -H "Content-Type: application/json" `
  --data-binary '{"board":{"name":"Mavi Devre","modules":[{"module_id":"P-GEN","kind":"generator","row":0,"column":1,"orientation":"south","level":1},{"module_id":"P-LASER","kind":"laser","row":0,"column":2,"orientation":"east","level":1}]},"bot_id":"starter_laser"}'
```

## Misafir oturumu

İstemci kullanıcı adı istemez. İlk açılışta:

```powershell
$session = Invoke-RestMethod `
  -Method Post `
  -Uri http://localhost:8000/api/v1/auth/guest
$access = $session.tokens.access_token
$refresh = $session.tokens.refresh_token
```

Sunucu `MaviRole-4821` biçiminde yalnız izin verilen kelime ve rakamlardan
oluşan benzersiz bir ad döndürür. Erişim JWT'si 15 dakika, yenileme JWT'si
30 gün geçerlidir. Yenileme anahtarı her kullanımda değiştirilir; kullanılmış
anahtar yeniden kabul edilmez. Veritabanında yenileme anahtarının kendisi
değil, SHA-256 özeti saklanır.

Yenileme:

```powershell
$session = Invoke-RestMethod `
  -Method Post `
  -Uri http://localhost:8000/api/v1/auth/refresh `
  -ContentType application/json `
  -Body (@{refresh_token=$refresh} | ConvertTo-Json)
```

## Kalıcı kart ve asenkron savaş

Kart kaydı ve asenkron eşleştirme `Authorization: Bearer <access>` ister:

```powershell
Invoke-RestMethod `
  -Method Put `
  -Uri http://localhost:8000/api/v1/me/board `
  -Headers @{Authorization="Bearer $access"} `
  -ContentType application/json `
  -InFile .\ornek-kart.json

$match = Invoke-RestMethod `
  -Method Post `
  -Uri http://localhost:8000/api/v1/matches/async `
  -Headers @{Authorization="Bearer $access"}
```

Sunucu aynı modül sayısında, başka bir oyuncuya ait ve çağıran oyuncunun son
üç gerçek rakibi arasında olmayan en eski uygun kartı seçer. Yeni oyuncu kartı
yoksa eşit modül sayılı `balanced` sunucu düzeni kullanılır. Sonuçtaki
`source` alanı `async` veya `bot`; `opponent.kind` alanı `player` veya `bot`
değerini taşır.

## Sunucu yetkisi

İstemci maç tohumu, rakip kartı, hasar veya galibiyet göndermez. Asenkron
akışta istemci maç isteğine kart dahi eklemez; sunucu oyuncunun son kaydedilmiş
kartını ve uygun rakibi PostgreSQL'den alır. Tohum sunucuda üretilir ve motor
sonucu sunucuda hesaplar. Bot antrenmanında istemci yalnız kendi kartını ve
seçtiği bot kimliğini gönderir.

Sunucu hedeflemeyi de üç aşamada uygular: önce Jeneratör dışındaki canlı
modüller, sonra Jeneratör ve en son çekirdek. İstemci hedef sırasını belirlemez;
yalnız sunucunun ürettiği olayları canlandırır.

Kurallar `0.7` ile Jeneratör adım başına 8 enerji, Kalkan eylem başına 14
koruma üretir. Etkisiz destek eylemleri planlanmaz. Kesintisiz enerji
yetersizliğinin ilk `energy_starved` olayı `detail: "streak_started"` taşır;
aynı kesinti boyunca yinelenen olay gönderilmez.

Dokuz botun her biri için 1–6 modüllük sunucu varyantı bulunur.
`POST /matches/bot`
oyuncunun modül sayısına eşit varyantı seçer ve eşitliği sunucuda doğrular.
`GET /bots` yanıtındaki `available_module_counts` alanı desteklenen sayıları,
`GET /modules` yanıtındaki `description` alanı modüle özgü taktik açıklamasını
taşır.

Maç yanıtındaki `player_board` ve `opponent_board` alanları, savaş tekrarının
sunucunun gerçekten kullandığı iki düzeni 4×4 kartlar üzerinde göstermesini
sağlar. Sonuç ve tekrar olayları yine ayrı tutulur; kart alanları sonucu
istemcide yeniden hesaplama yetkisi vermez.

Asenkron maç; iki kartın anlık kopyasını, olaylar hariç sonucu ve replay
adresini `matches` tablosunda tutar. Olaylar ile kesin `state_frames`
PostgreSQL JSON alanındaki replay kaydında saklanır. Sunucu yeniden başlasa da
aynı maç ve checksum okunabilir. Asenkron maç/replay yalnız isteği oluşturan
oyuncu ve kartı rakip olarak kullanılan oyuncu tarafından okunabilir.

Kartın `(1,1)`, `(1,2)`, `(2,1)` ve `(2,2)` hücreleri pasif çekirdektir ve
yerleşime kapalıdır. Jeneratör yalnız `(0,1)`, `(1,3)`, `(3,2)` veya `(2,0)`
kapısına sırasıyla `south`, `west`, `north` veya `east` yönüyle
yerleştirilebilir. Bu kurallar hem doğrulama hem maç uç noktasında sunucu
tarafından uygulanır.

Replay yanıtındaki `state_frames`, `0` başlangıç adımı dâhil olmak üzere her
savaş adımının kesin sunucu durumunu taşır. Her kart karesinde çekirdek canı,
kalkan, enerji rezervi, üretim ve toplam harcama; her modülde can, ısı,
bekleme, enerji bağlantısı ve aşırı ısınma durumu bulunur. İstemci bu alanları
yalnızca görselleştirir, yeniden hesaplamaz.

Maç sonucundaki `decision` alanı, sunucu kararının açıklamasıdır:

```json
{
  "criterion": "module_hp_ratio",
  "metrics": [
    {
      "key": "core_hp_ratio",
      "left_value": 1.0,
      "right_value": 1.0,
      "preferred": "higher"
    },
    {
      "key": "module_hp_ratio",
      "left_value": 0.70,
      "right_value": 0.80,
      "preferred": "higher"
    }
  ]
}
```

Gerçek yanıtta altı ölçütün tamamı sırasıyla bulunur. `criterion`, süre
sonunda kararı veren ilk farklı ölçütü veya `core_destroyed`,
`mutual_core_destruction` ya da `exact_draw` sonucunu belirtir. İstemci bu
alanı açıklama için kullanır; kazananı yeniden hesaplamaz.

## Hata gövdesi

Alan doğrulama, oturum, kart kuralı, veritabanı, bulunamayan bot ve bulunamayan
maç hataları aynı üst sözleşmeyi kullanır:

```json
{
  "code": "board_validation_failed",
  "message": "Aynı hücrede birden fazla modül var: (1, 1)",
  "details": null
}
```

## Bilinçli sınırlar

- PostgreSQL şeması Alembic ile yönetilir; API kendiliğinden tablo oluşturmaz.
- CORS yalnızca `localhost` ve `127.0.0.1` üzerindeki HTTP/HTTPS geliştirme
  origin'lerine izin verir.
- Serbest oyuncu adı, parola, sohbet, ELO, haftalık lig ve oyuncuya dönük maç
  geçmişi uç noktası yoktur.
- Eşleştirme aynı modül sayısını zorunlu tutar; v0.5.0'a kadar derece aralığı
  kullanmaz.
- Tekrar özeti bütün olay akışından hesaplanır; dijital imza değildir.
- `rules_version` savaş kurallarının, API `version` ise HTTP paketinin sürümüdür.
