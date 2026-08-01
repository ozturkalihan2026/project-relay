# Project Relay Flutter İstemcisi — v0.8.0

İstemci; Ana Menü, Çevrimiçi Savaş, Antrenman, Kariyer, Koleksiyon,
İstatistikler, Sezon ve Kapalı Alfa, Sosyal ve Klan, Nasıl Oynanır ve Ayarlar
ekranlarını içerir.

## v0.8.0

- Sosyal profil durum mesajı ve favori modül
- Oyuncu arama ve arkadaşlık isteği akışı
- Gelen istekleri kabul/ret etme ve arkadaş listesi
- Açık klan keşfi, klan kurma, katılma ve ayrılma
- Klan üyeleri için lider/üye görünümü
- Ana menüde ayrı `SOSYAL VE KLAN` ekranı
- Sürüm: `0.8.0+42`

v0.7.0 sezon/alfa ekranı ve v0.6.2 rev1 kit, kozmetik ve ilerleme sistemleri
korunur.

## Yerel doğrulama

```powershell
.\tool\bootstrap_client.ps1
```

## Çalıştırma

```powershell
flutter run -d edge --dart-define=RELAY_API_URL=http://127.0.0.1:8000
```
