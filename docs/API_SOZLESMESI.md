# Project Relay — API Sözleşmesi v0.6.1

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
| `GET` | `/api/v1/me/career` | Derece, haftalık lig ve son maçlar |
| `GET` | `/api/v1/me/matches` | Sayfalı maç geçmişi |
| `GET` | `/api/v1/league/current` | Güncel haftalık lig ve liderlik tablosu |
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

Kurallar `0.8` ile Jeneratör adım başına 8 enerji, Kalkan eylem başına 14
koruma üretir. Etkisiz destek eylemleri planlanmaz. Kesintisiz enerji
yetersizliğinin ilk `energy_starved` olayı `detail: "streak_started"` taşır;
aynı kesinti boyunca yinelenen olay gönderilmez.

Batarya ve Güçlendirici katalogda dört portla döner. Batarya yönsüz enerji
kavşağı ve 20 birim rezervdir. Güçlendiricinin yön alanı bağlantı noktalarını
değiştirmez; yalnız okun gösterdiği bağlı komşuya uygulanacak `1,35×` etki ve
`1,25×` ısı çarpanını seçer.

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
- Serbest oyuncu adı, parola, sohbet, canlı 1v1 ve klan uç noktaları yoktur.
- Eşleştirme aynı modül sayısını zorunlu tutar; mevcut sürüm derece aralığını
  henüz eşleştirme filtresi olarak kullanmaz.
- Tekrar özeti bütün olay akışından hesaplanır; dijital imza değildir.
- `rules_version` savaş kurallarının, API `version` ise HTTP paketinin sürümüdür.


## v0.5.0 rekabet yanıtları

İki gerçek oyunculu asenkron maç yanıtı katılımcının bakış açısından şu alanı
taşır:

```json
{
  "rating_change": {
    "outcome": "win",
    "rating_before": 1000,
    "rating_after": 1016,
    "rating_delta": 16,
    "week_key": "2026-W31"
  }
}
```

Bot dönüşünde ve antrenmanda `rating_change` değeri `null` olur. Kesin
beraberlikte `rating_before` ile `rating_after` eşit ve `rating_delta` sıfırdır.

`GET /api/v1/me/career`, genel profil, haftalık lig girdisi, liderlik tablosu,
son maçlar ve o haftanın insan/bot eşleşme oranını birlikte döndürür.
`GET /api/v1/me/matches` `limit` (1–50) ve `offset` parametreleriyle sayfalanır.

## v0.6.0 ilerleme yanıtları

`GET /api/v1/me/statistics`, v0.5.0 derece/lig/geçmiş yanıtının yeni adıdır.
`GET /api/v1/me/career` geriye uyumluluk için aynı yanıtı vermeye devam eder.

`GET /api/v1/me/progression` aşağıdaki grupları döndürür:

- `profile`: toplam XP, seviye içi XP, sonraki seviye gereksinimi ve Devre Kredisi
- `daily_missions`: günlük ilerleme, tamamlanma ve ödül durumu
- `achievements`: kalıcı başarım ilerlemesi ve ödül durumu
- `boosters`: seviye ile açılan, yalnız koşu içinde geçerli geçici kademe bilgisi

İki gerçek oyunculu veya bot yedekli asenkron maç yanıtı aktif istek sahibi için
`progression_reward` taşır. Doğrudan antrenman maçında bu alan `null` olur.

```json
{
  "progression_reward": {
    "source_type": "match",
    "source_id": "match-id",
    "reason": "Asenkron savaş: win",
    "xp": 50,
    "credits": 30,
    "level_before": 1,
    "level_after": 1,
    "level_up": false,
    "total_xp_after": 50,
    "credits_after": 30,
    "granted_at": "2026-07-31T09:00:00+00:00"
  }
}
```

Ödül alma uçları:

- `POST /api/v1/me/daily-missions/{mission_id}/claim`
- `POST /api/v1/me/achievements/{achievement_id}/claim`

Her ödül kaynağı oyuncu, kaynak türü ve kaynak kimliğiyle benzersizdir. Aynı
isteğin yinelenmesi ikinci kez XP veya Devre Kredisi eklemez.



## v0.6.1 kariyer koşusu yanıtları

Bütün kariyer uçları erişim belirteci ister.

- `GET /api/v1/me/career-run`: son/aktif koşu durumu ve mevcut rakip ön izlemesi
- `POST /api/v1/me/career-run/start`: kayıtlı kartla temiz koşu başlatır
- `POST /api/v1/me/career-run/booster`: sunulan üç seçenekten birini seçer
- `POST /api/v1/me/career-run/battle`: mevcut aşamayı hesaplar, maç ve yeni koşu
  durumunu birlikte döndürür
- `POST /api/v1/me/career-run/abandon`: koşuyu bırakır ve geçici etkileri kapatır

Aktif durum örneği:

```json
{
  "run_id": "run-id",
  "status": "active",
  "stage_index": 0,
  "total_stages": 5,
  "wins": 0,
  "selected_boosters": [],
  "offered_boosters": [],
  "opponent": {
    "stage_number": 1,
    "total_stages": 5,
    "title": "İlk Temas",
    "briefing": "Lazer hattını okuyup temel karşı devreyi kur.",
    "is_boss": false,
    "opponent_id": "starter_laser",
    "display_name": "Başlangıç Lazeri",
    "description": "...",
    "board": {"name": "...", "modules": []}
  },
  "last_match_id": null,
  "reward": null,
  "board_required": false,
  "can_battle": true,
  "can_choose_booster": false,
  "started_at": "2026-07-31T12:00:00+00:00",
  "ended_at": null
}
```

`opponent.board`, aynı aşamadaki `career-run/battle` çağrısında sunucunun
kullanacağı rakip kartın tam karşılığıdır. İstemci rakip kartı, aşama sonucu,
güçlendirici etkisi veya ödül hesaplayamaz.

Zaferden sonra durum `awaiting_booster` olur ve `offered_boosters` tam üç öğe
taşır. Terminal durumda `completed`, `failed` veya `abandoned` döner; ödül varsa
`reward` alanı v0.6.0 `RewardGrantResponse` sözleşmesini kullanır.
