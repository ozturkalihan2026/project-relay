# Project Relay Flutter İstemcisi

Bu dizin v0.5.0 ana menüsü, bağımsız Nasıl Oynanır akışı, kalıcı misafir
oturumu, dereceli asenkron oyuncu eşleştirmesi, haftalık lig ve maç geçmişi,
sürükle-bırak kart düzenleyici, etkileşimli oyun el kitabı ve Flame savaş
tekrarı uygulamasıdır. Modül paleti adı ve sunucu özelliklerini doğrudan
kartlarda gösterir; devre hücreleri yerleşimden sonra yalnız modül simgesini,
portları ve yön bilgisini taşır. Palet modülü boş hücreye yerleşir, dolu
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
**YENİ OYUN** bu dört düğmenin hemen altındaki ortalanmış, güçlü ana eylemdir.
Sunucu sonucu savaş başından itibaren görünür ve canlı replay değerleriyle
güncellenir; olay listesi esnerken bu kontrol grubu panelin altında sabit kalır.

Batarya ve Güçlendirici dört portlu enerji kavşağıdır. Batarya yönsüzdür ve
20 enerji depolar; bu nedenle döndürme düğmesi gösterilmez. Güçlendirici
enerjiyi bütün bağlı komşulara taşır, fakat yalnız okun gösterdiği tek komşuyu
güçlendirir.
Kartın dışına veya kapısız çekirdek alanına bakan kullanılamayan port
işaretleri çizilmez. Güçlendiricinin yön oku sağ üstte sürekli görünür;
döndürülebilen modüllerin döndürme düğmesi sol üstte sürekli görünür.

Bağlantı doğrulama, yerleşim ve API hataları ekranın altına yayılan SnackBar
yerine devre kartının altında saydam ve durum rengine sahip bağlamsal kartta
gösterilir.

Uygulama **Oyna**, **Kariyer**, **Nasıl Oynanır** ve **Ayarlar** seçenekli ana menüyle açılır. Kariyer gerçek dereceyi, haftalık ligi, liderlik tablosunu ve replay açılabilen maç geçmişini gösterir.
Oyna altındaki **Çevrimiçi Savaş** yalnız asenkron oyuncu eşleştirmesini,
**Antrenman** yalnız dokuz sabit rakibi gösterir. Modül adı ile Can ve role
özgü değerler seçim paletinde görünür; devre hücreleri savaş alanını sade
tutmak için bu metinleri tekrar etmez.
Çevrimiçi karttaki ana düğme **Savaşa Başla** olarak görünür; hemen altındaki
**Menüye Dön** düğmesi bir önceki Oyna menüsüne güvenli dönüş sağlar.

Çevrimiçi ekran ilk açıldığında sunucudan güvenli adlı misafir oyuncu alır. Yenileme
anahtarı `flutter_secure_storage` ile saklanır; sonraki açılışta aynı oyuncu
oturumu döndürülür. Ana ekrandaki **Savaşa Başla** eylemi
geçerli kartı sunucuya kaydeder ve asenkron gerçek oyuncu eşleştirmesini
başlatır. Uygun yeni oyuncu yoksa sunucu botu kullanılır. Dokuz sabit rakip
ayrı **Antrenman** ekranında korunur.

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
