# Plan: 3D Devre Kartı Canlı Savaş + Sınırsız Modül Değişimi

## Amaç

1. `CircuitBoard(presentation3d: true)` widget'ını canlı savaş ekranında Flame GameWidget yerine kullan
2. Modül değişimini sınırsız yap (6 modül sınırı korunarak)
3. Değişim rafında kit'teki tüm kullanılmayan modülleri göster

---

## Mevcut Durum

- Canlı savaş ekranı (`career_live_battle_screen.dart`): Flame `GameWidget` ile board render ediyor
- Müdahale sistemi: 3 pencere (60/90/120), toplam 2 hak, pencerede 1 hak
- Yedek rafı: Yalnızca server'ın hesapladığı `session.reserves` modüllerini gösteriyor
- Online savaş: Müdahale yok, async replay

---

## Değişiklik Planı

### Faz 1: Müdahale Politikası Değişiklikleri (Server)

**Dosya: `relay_engine/intervention.py`**
- `InterventionPolicy`: `max_swaps` = 999 (sınırsız), `max_swaps_per_window` = 999
- `window_for_tick()`: Pencereyi 0. tick'tan itibaren aktif yap (tick < 0 olmasın)
- `ModuleHealthRack.swap()`: `swap_limit_reached` ve `window_already_used` hatalarını kaldır

**Dosya: `relay_api/career.py`**
- `_career_reserves()`: Tüm kit modüllerini reserve olarak ekle (sadece board'da olmayanları değil, tümünü — çünkü swap sınırsız, herhangi bir modül tekrar gelebilir)
- Snapshot oluşturma: `reserves` listesini tüm kit modüllerinden oluştur

### Faz 2: Canlı Savaş Ekranı Yeniden Yazımı (Client)

**Dosya: `career_live_battle_screen.dart`**

#### 2a. Flame'i Kaldır, CircuitBoard Ekle

- `import 'package:flame/game.dart'` kaldır
- `import '../game/replay_game.dart'` kaldır
- `RelayReplayGame _game` kaldır
- `_createLiveGame()` kaldır
- `_feedSession()` → artık `_game.feedLiveFrame` çağırmıyor, sadece `setState` ile board güncelleniyor

**`_LiveBattleStage` yeniden yazımı:**
- `GameWidget<RelayReplayGame>` → İki adet `CircuitBoard(presentation3d: true)`
  - Sol: oyuncu board'u (sürükle-bırak aktif müdahale penceresinde)
  - Sağ: rakip board'u (read-only, `moduleDraggingEnabled: false`)
- `ReplayAttackOverlay` korunuyor (saldırı/kalkan görselleri Flame'den bağımsız)
- `BattleArenaAtmosphere` ve `BattleCameraRig` korunuyor
- `DragTarget` overlay kaldırıldı — CircuitBoard'un kendi DragTarget'ı kullanılıyor

**Yeni layout:**
```
┌─────────────────────────────────────────────┐
│  Header (durum + çekirdek canı)             │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────┐    vs    ┌──────────┐        │
│  │ Oyuncu   │          │ Rakip    │        │
│  │ Board    │          │ Board    │        │
│  │ (3D)     │          │ (3D)     │        │
│  └──────────┘          └──────────┘        │
│                                             │
│  [ReplayAttackOverlay - saldırılara göre]   │
├─────────────────────────────────────────────┤
│  Müdahale Rafı (tüm kit modülleri)          │
└─────────────────────────────────────────────┘
```

#### 2b. Müdahale Rafını Genişlet

**`_InterventionShelf` güncellemesi:**
- `session.reserves` yerine `widget.modules` (tüm kit modülleri) + board'da olmayanları göster
- Swap sayacı kaldır (`2/2 değişim hakkı` → `savaş duraklatılmaz` kalır)
- Etiket: `state.swapsRemaining == 0` kontrolü kaldırıldı, sadece aktif/pasif/bekleme durumları
- Raf her zaman görünür (intervention aktif olmasa bile modüller görünür, ama sürükleme kapalı)

#### 2c. Müdahale Kapısını Aç

**`_interventionUsable` güncellemesi:**
```dart
bool get _interventionUsable =>
    _session.intervention.active &&
    !_session.intervention.pending &&
    !_swapping &&
    !_session.complete;
```
`swapsRemaining > 0` kaldırıldı.

#### 2d. `_queueSwap` Güncellemesi
- Mevcut akış korunuyor: outgoing/incoming ID, API çağrısı, session güncelleme
- Başarı mesajı: `Değişim bir sonraki sinyalde uygulanacak` korunuyor

### Faz 3: Rakip Board Gösterimi

- Rakip board'u `CircuitBoard(presentation3d: true, moduleDraggingEnabled: false)` olarak render ediliyor
- Rakip board'u için `EquippedVisuals` farklı tema ile gösterilebilir (düşman rengi)
- `_session.opponentBoard` modülleri placedModules olarak iletiliyor
- Rakip board'u için `onCellTap`, `onModuleDropped` boş callback

### Faz 4: Frame/Event Besleme

Mevcut `_feedSession` → artık Flame'e frame beslemiyor:
- `setState()` ile board modülleri ve frame verisi güncelleniyor
- `_attackOverlayEvents` beslenmeye devam ediyor (attack overlay bağımsız)
- Sound player beslenmeye devam ediyor
- Frame verisi (HP, shield, energy) header'da gösteriliyor

### Faz 5: Online Savaş Canlı Oturum

**Dosya: `relay_api/online.py`**
- Yeni endpoint: `POST /api/v1/me/online-battle/start-live` → canlı online savaş oturumu başlatır
- Yeni endpoint: `POST /api/v1/me/online-battle/advance` → tick ilerletir
- Yeni endpoint: `POST /api/v1/me/online-battle/swap` → modül değişimi

**Dosya: `client/lib/src/api/relay_api.dart`**
- `startOnlineBattleSession()`, `advanceOnlineBattleSession()`, `swapOnlineBattleModule()` ekle

**Dosya: `editor_screen.dart`**
- Online savaş başlangıcı: `ReplayScreen` yerine yeni `OnlineLiveBattleScreen` aç

**Dosya: Yeni `online_live_battle_screen.dart`**
- `CareerLiveBattleScreen`'i extends/ortak component olarak yeniden düzenle
- Ortak: `_LiveBattleStage`, `_InterventionShelf`, `_queueSwap`
- Fark: API çağrıları (career yerine online endpoint), başlatma akışı

### Faz 6: Sözleşme Testleri

**Dosya: `tests/test_client_contract.py`**
- `_PortMarker` → `portFill.color` (zaten yapıldı)
- Flame importkontrolü kaldır veya güncelle
- CircuitBoard(presentation3d: true) beklentisi ekle

---

## Dosya Değişiklik Özeti

| Dosya | Değişiklik |
|-------|-----------|
| `relay_engine/intervention.py` | max_swaps=999, pencere 0'dan başla |
| `relay_api/career.py` | reserve = tüm kit modülleri |
| `career_live_battle_screen.dart` | Flame→CircuitBoard, raf genişlet |
| `relay_api/online.py` | Canlı savaş endpoint'leri |
| `client/lib/src/api/relay_api.dart` | Online canlı savaş API'leri |
| `client/lib/src/screens/editor_screen.dart` | Online savaş akışı |
| `tests/test_client_contract.py` | Güncel beklentiler |

---

## Doğrulama

```powershell
.\.venv\Scripts\python.exe -m pytest tests/test_client_contract.py -v
.\.venv\Scripts\python.exe -m pytest tests/test_engine.py -v
cd client
flutter analyze
flutter test
```
