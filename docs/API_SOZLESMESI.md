# Project Relay — API Sözleşmesi v0.8.4

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
| `GET` | `/api/v1/me/collection` | Koleksiyon, kredi, aktif kit ve kuşanılanları okuma |
| `POST` | `/api/v1/me/collection/cosmetics/{id}/purchase` | Devre Kredisiyle kozmetik satın alma |
| `PUT` | `/api/v1/me/collection/equipped` | Sahip olunan kozmetiği kuşanma |
| `PUT` | `/api/v1/me/kit` | Kontrollü sekizli kiti kaydetme |
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
  "criterion": "total_damage",
  "metrics": [
    {
      "key": "surviving_modules",
      "left_value": 5,
      "right_value": 5,
      "preferred": "higher"
    },
    {
      "key": "total_damage",
      "left_value": 126.0,
      "right_value": 118.0,
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

Gerçek yanıtta altı ölçütün tamamı `surviving_modules`, `total_damage`,
`module_hp_ratio`, `core_hp_ratio`, `damage_efficiency`, `total_heat` sırasıyla
bulunur. `criterion`, süre sonunda kararı veren ilk farklı ölçütü veya `core_destroyed`,
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

İlk üç zaferden sonra koşu doğrudan bir sonraki rakip hazırlığına ilerler.
Dördüncü zaferden sonra durum `awaiting_booster` olur ve boss öncesi satın
alınabilir güçlendiriciler döner; oyuncu birini Devre Kredisiyle alabilir veya
mağazayı atlayabilir. Terminal durumda `completed`, `failed` veya `abandoned`
döner; ödül varsa `reward` alanı v0.6.0 `RewardGrantResponse` sözleşmesini kullanır.


## Koleksiyon ve kontrollü kit

`GET /api/v1/me/collection`, oyuncunun Devre Kredisi, sahiplikleri,
kuşanılan üç kozmetik kategorisi ve aktif sekizli kitini döndürür.

Kit kaydı örneği:

```json
{
  "name": "Dengeli Sekizli",
  "module_kinds": [
    "generator", "battery", "laser", "pulse_cannon",
    "shield", "cooler", "amplifier", "repair"
  ]
}
```

Kit tam sekiz yuva ve tam bir Jeneratör içermelidir. Jeneratör dışındaki aynı
modül en fazla üç kez bulunabilir. `PUT /api/v1/me/board` ve
`PUT /api/v1/me/career-board`, karttaki modül adetlerini aktif kite göre
sunucu tarafında yeniden doğrular.

Mağaza yalnız kozmetiktir. Satın alma aynı işlem içinde Devre Kredisini düşürür,
sahipliği ekler ve kozmetiği kuşanır; ham savaş değeri değiştirmez.

## v0.7.0 sezon ve kapalı alfa uçları

### `GET /api/v1/me/season`

Aktif takvim sezonunu, oyuncunun puan/kayıt özetini, dört ödül kademesini ve
sezon sıralamasını döndürür.

### `POST /api/v1/me/season/tiers/{tier}/claim`

Açılmış sezon kademesinin XP ve Devre Kredisi ödülünü tek seferlik verir.
Yinelenen istek aynı ödül kaydını döndürür; ikinci kez bakiye yazmaz.

### `GET /api/v1/me/alpha-safety`

Savaş/geri bildirim istek sayaçlarını ve sunucu yetkisi, idempotent ödül ile
kart doğrulama korumalarının durumunu döndürür.

### `POST /api/v1/alpha/feedback`

`category`, `message` ve `client_version` alanlarıyla kapalı alfa geri bildirimi
kaydeder. Oyuncu başına saatlik sınır aşılırsa `429` döndürür.

### `POST /api/v1/matches/async`

v0.7.0'da mevcut akış korunur. Oyuncu başına dakikalık istek sınırı aşılırsa
`429`; gerçek oyuncu maçı tamamlanırsa iki katılımcı için idempotent sezon puanı
kaydı oluşturulur. Bot geri dönüşü sezon puanı üretmez.

### Asenkron maçta `season_change`

Gerçek oyuncu eşleşmesinde maç yanıtı aşağıdaki alanı içerir:

```json
{
  "season_change": {
    "season_key": "2026-08",
    "outcome": "win",
    "points_gained": 5,
    "total_points": 18
  }
}
```

Bot geri dönüşünde `season_change` değeri `null`dır. İstemci bu özeti savaş
ödülü bildiriminde gösterir ve sezon ekranını yeniler.


## v0.8.0 sosyal ve klan uçları

### `GET /api/v1/me/social`

Oyuncunun sosyal profilini, gelen/giden arkadaşlık isteklerini, arkadaşlarını ve
varsa mevcut klanını döndürür.

### `PUT /api/v1/me/social/profile`

`status_message` ve `favorite_module` alanlarını günceller. Favori modül sekiz
temel modülden biri olmalıdır.

### `GET /api/v1/social/players?query=...`

En az iki karakterlik ad araması yapar. Sonuçlarda mevcut ilişki `none`,
`incoming`, `outgoing` veya `friend` olarak döner.

### Arkadaşlık işlemleri

- `POST /api/v1/me/friends/requests/{target_player_id}`
- `POST /api/v1/me/friends/requests/{request_id}/accept`
- `POST /api/v1/me/friends/requests/{request_id}/decline`
- `POST /api/v1/me/friends/{friend_player_id}/remove`

Aynı oyuncuyla yinelenen bekleyen istek veya kabul edilmiş arkadaşlık sunucu
tarafından reddedilir.

### Klan işlemleri

- `GET /api/v1/clans`
- `POST /api/v1/clans`
- `POST /api/v1/clans/{clan_id}/join`
- `POST /api/v1/me/clan/leave`

Bir oyuncu aynı anda yalnızca bir klana üye olabilir. Açık klanlar en fazla 20
üyeye sahiptir. Lider, başka üyeler varken klanı terk edemez. Klan üyeliği
savaş gücü, derece veya ödül çarpanı vermez.


## v0.8.1 uyumluluk notu

v0.8.1 bir QA ve paketleme hotfix'idir. HTTP yolları, istek/yanıt alanları,
PostgreSQL şeması ve Alembic başı değişmemiştir. Sağlık ve OpenAPI sürüm alanı
`0.8.1`, Flutter istemci bildirimi `0.8.1` olur; savaş `rules_version` değeri
`0.8` olarak kalır.


## v0.8.2 uyumluluk notu

v0.8.2 sosyal istemciyi ürünleştirir; HTTP yolları, istek/yanıt alanları,
PostgreSQL şeması ve Alembic başı değişmemiştir. Sağlık ve OpenAPI sürüm alanı
`0.8.2`, Flutter istemci bildirimi `0.8.2` olur; savaş `rules_version` değeri
`0.8` olarak kalır. Raporlama, engelleme ve liderlik devri için yeni uç eklenmez.


## v0.8.3 uyumluluk notu

v0.8.3 istemci gezinmesini ve ekran gruplamasını değiştirir. HTTP yolları,
veritabanı tabloları, sosyal/klan sözleşmeleri, koleksiyon işlemleri ve savaş
kuralları değişmez. İstemci sürüm bildirimi `0.8.3`, API sağlık sürümü `0.8.3`
olur.


## v0.8.4 uyumluluk notu

v0.8.4 Profil/Klan yerleşimini ve Kariyer hazırlık arayüzünü değiştirir. HTTP
yolları, istek/yanıt alanları, PostgreSQL şeması, Alembic başı ve savaş
kuralları değişmez. Kariyer ekranı mevcut `/career-board` doğrulama/kaydetme ve
`/career-run/start` uçlarını aynı çalışma alanından çağırır. İstemci sürüm
bildirimi `0.8.4`, API sağlık sürümü `0.8.4`, `rules_version` değeri `0.8` olur.
