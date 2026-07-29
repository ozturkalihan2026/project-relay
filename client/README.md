# Project Relay Flutter İstemcisi

Bu dizin v0.4.2 kalıcı misafir oturumu, asenkron oyuncu eşleştirmesi,
sürükle-bırak kart düzenleyici, etkileşimli oyun el kitabı ve Flame savaş
tekrarı uygulamasıdır. Palet modülü boş hücreye yerleşir, dolu
hücredeki modülü değiştirir. Kart modülü boş hücreye taşınır, dolu hücreyle
yer değiştirir veya palete geri bırakılarak kaldırılır. Savaş iki gerçek 4×4
kart üzerinde, aradaki tam Türkçe olay günlüğü, canlı enerji iletimleri, üst
katman saldırı ışınları, modül durumları ve eyleme özgü yerel ses efektleriyle
oynatılır.

Kartın ortasındaki 2×2 alan pasif çekirdektir. Çevredeki 12 hücrenin en fazla
altısına modül yerleştirilir. Jeneratör dört çekirdek kapısından birine
çekirdeğe dönük yerleşir; iki yan portuyla halkayı, iç portuyla çekirdek
üzerinden diğer üç kapıyı besler.

Bağlantı kabloları modül veya hücre merkezleri arasında değil, ekranda
görünen port noktalarının merkezleri arasında çizilir. Ana ekrandaki kısa
yardım şeridi yalnız temel akışı gösterir; ayrıntılı kurallar **Oyun El
Kitabı** ekranındadır. Aynı port noktaları ve porttan porta hareketli enerji
iletimi savaş kartlarında da kullanılır.

Savaş ekranındaki ayrı **Savaş Tekrarı** başlığı kaldırılmıştır. Duraklatma,
yeniden oynatma, ses ve hız eylemleri canlı olay akışının altındaki sunucu
sonucuna bağlanan, ortalanmış ve dar ekranda satıra sarılan düğmelerdir.

Uygulama ilk açılışta sunucudan güvenli adlı misafir oyuncu alır. Yenileme
anahtarı `flutter_secure_storage` ile saklanır; sonraki açılışta aynı oyuncu
oturumu döndürülür. Ana ekrandaki **Kartı Kaydet ve Oyuncu Bul** eylemi
geçerli kartı sunucuya kaydeder ve asenkron gerçek oyuncu eşleştirmesini
başlatır. Uygun yeni oyuncu yoksa sunucu botu kullanılır. Dokuz sabit rakip
varsayılan kapalı **Bot Antrenmanı** alanında korunur.

## Hazırlama

PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\tool\bootstrap_client.ps1
```

Bash:

```bash
chmod +x tool/bootstrap_client.sh
./tool/bootstrap_client.sh
```

Betik Android/web platform dosyalarını kurulu Flutter SDK ile üretir, `lib`,
`test`, `assets`, `pubspec.yaml` ve `analysis_options.yaml` kaynaklarını geri
yükler.
Flutter'ın ürettiği örnek kaynak ve testleri önce tamamen kaldırır; ardından
paket çözümleme, analiz ve test çalıştırır. Bu komutlardan biri başarısızsa
betik başarı mesajı vermeden hata koduyla durur.

## Web çalıştırma

```powershell
flutter run -d edge --dart-define=RELAY_API_URL=http://127.0.0.1:8000
```

FastAPI ve PostgreSQL'in ayrı terminalde 8000 portunda çalışıyor olması
gerekir. Proje kökündeki `docker compose up --build` ikisini birlikte başlatır.
