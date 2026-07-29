# Project Relay v0.4.7 — Flutter Widget Test Uyumluluğu

Project Relay, oyuncuların 4×4 yönlü devre kartına modüller yerleştirip
sunucu tarafından hesaplanan asenkron savaşlara katıldığı rekabetçi oyun
prototipidir.

v0.1.0 deterministik savaş motorunu, v0.2.0 HTTP savaş API'sini kanıtladı.
v0.3.0 aynı motor ve API sözleşmesini kullanan ilk Flutter/Flame istemcisini
ekler. Artık kart kurma, bağlantıları görme, bot seçme, savaş başlatma ve
olay tabanlı tekrarı izleme tek akışta çalışır.

v0.3.1, Flutter'ın ürettiği varsayılan `widget_test.dart` dosyasını temizleyen
ve analiz uyarılarını gideren yama sürümüdür. Oynanış kapsamını ve savaş
kurallarını değiştirmez.

v0.3.2, PowerShell'in virgüllü platform listesini iki ifadeye ayırmasını
önler. `android,web` değeri Flutter'a tek argüman olarak aktarılır. Oynanış
kapsamını ve savaş kurallarını değiştirmez.

v0.3.3, modülleri paletten devre kartına sürükleyip bırakarak yerleştirmeyi
ve düzenleyicinin üstündeki uyarlanabilir **Nasıl Oynanır?** kartını ekler.
Mevcut dokunarak yerleştirme davranışı korunur.

v0.3.4, bu etkileşimi tamamlar: kart modülleri taşınabilir ve dolu hücrelerle
yer değiştirebilir; paletten dolu hücreye bırakılan modül eskisinin yerini
alır. Portlar hücre kenarlarında görünür, dört yönlü bağlantı matrisi motor,
API ve istemci testleriyle doğrulanır. **Nasıl Oynanır?** kartı sekiz modülü,
enerji akışını, yönleri, ısıyı ve savaş kurallarını anlatan tam ekran oyun el
kitabına açılır.

v0.3.5, oyuncu gözlemlerindeki kritik boşlukları kapatır. Batarya dört yönlü
enerji kavşağına dönüştüğü için doğru kurulan dolu 4×4 kartın 16 modülü de
enerji alabilir. El kitabı örnek devre simülasyonu, özellik sözlüğü,
avantaj/dezavantajlar ve ilerleme hedefleri içerir. Savaş tekrarı artık iki
gerçek kart üzerinde oynar; duraklatılabilir Türkçe olay akışı ve olay türüne
özel sesler hangi modülün ne yaptığını görünür kılar.

v0.3.6 savaş tekrarının okunabilirliğini geliştirir. Canlı olay akışı geniş
ekranda iki kart arasına yerleşir. Sunucunun her adımda gönderdiği kesin durum
kareleri; modül canı, enerjisi, ısısı ve bekleme süresi ile kart kalkanı ve
enerji rezervini canlı gösterir. Lazer, Darbe Topu ve Kalkan sesleri eyleme
özgü yeni efektler kullanır. Oyun el kitabının sonunda geri dönüş düğmesi
bulunur. Oynanış dengesi ve savaş kuralları değişmez.

v0.3.7 modüller arasındaki enerji iletimini hareketli olarak gösterir, saldırı
ışınlarını olay günlüğünün üst katmanına taşır ve geniş ekrandaki günlüğün
savaşta gerçekleşmiş bütün olaylarını kaydırılabilir biçimde korur. Kritik
denge denetimi, sınırsız kart doldurmanın ve eski Darbe Topu veriminin baskın
strateji üretebildiğini gösterdi. Kurallar v0.3 ile kart başına 6 modül sınırı,
dengelenmiş Darbe Topu ve sekiz farklı sunucu rakibi getirildi.

v0.3.8, oynanışı ve dengeyi değiştirmeyen istemci kararlılığı sürümüdür. Canlı
olay günlüğünün özel kaydırma denetleyicisi savaş başlangıcı ve yeniden
başlatmada sürekli bağlı kalır; masaüstü/web otomatik ikinci kaydırma çubuğu
engellenir. Sabit ses havuzu yerine her eşzamanlı efekt için bağımsız ve
tamamlanınca serbest bırakılan ses kanalı kullanılır.

v0.3.9, başlangıçtaki modül sayısı avantajını kaldırır. Sekiz rakip stilinin
her biri 1–6 modüllük sunucu varyantına sahiptir; sunucu oyuncu kartıyla eşit
sayıdaki varyantı seçip eşitliği tekrar doğrular. Sunucu sonucu olay günlüğünün
altına taşınmış, modül ipuçları sunucu kaynaklı taktik açıklamalarla yenilenmiş
ve oyuncuya dönük geliştirme yol haritası el kitabından çıkarılmıştır.

v0.3.10, kartın ortasındaki 2×2 alanı dört kapılı pasif çekirdeğe ayırır.
Çevredeki 12 hücrenin en fazla altısı kullanılır. Jeneratör yalnız bir çekirdek
kapısına, çekirdeğe dönük yerleşebilir; üç portunun ikisi halkayı, biri
çekirdeği besler. Çekirdek enerji üretmez veya depolamaz, yalnız diğer üç
kapıya enerji taşır. Merkezî topolojinin dengeye etkisi dokuz rakip ve 1.512
tohumlu savaşla karşılaştırılmıştır.

v0.3.11, savaş hedeflerini kesin bir savunma sırasına bağlar. Saldırılar önce
Jeneratör dışındaki bütün modülleri, ardından Jeneratörü ve en son çekirdeği
hedefler. Aynı adımdaki yedek hedef seçimi de bu sırayı korur. Ana ekran
yüksekliğe uyumlu daha küçük kart ve kaydırılabilir rakip seçici kullanır.
Savaş sonucu, kararı veren ilk süre sonu ölçütünü açıklar; tekrar kartları
Can, Enerji, Isı ve Bekleme değerlerini anlık değişimlerle gösterir.

v0.3.12, Jeneratör üretimini 5'ten 8'e ve Kalkan etkisini 12'den 14'e
çıkarır. Etkisiz destek eylemleri enerji harcamaz; enerji alamayan hazır
modüller sonraki adımlarda öncelik kazanır. Kesintisiz enerji yetersizliği
tek günlük uyarısında birleştirilir. Kalkanlar saldırı modüllerinden önce
hedef çekerek dört Darbe Topulu yığına karşı Siper karşılığını korur.

v0.3.13, düzenleyicideki bütün kablo uçlarını görünen port merkezlerine
bağlar. Çekirdek kapısı hattı artık modülün veya çekirdeğin merkezinden
geçmez. Aynı porttan porta çizim hareketli savaş enerji iletiminde de
kullanılır. Ana ekrandaki dört büyük anlatım kutusu, ayrıntıları oyun el
kitabında bırakan tek satırlık yardım şeridine dönüştürülür; palet, doğrulama
ve rakip alanlarının boşlukları kartın yeni ölçeğiyle dengelenir.

v0.3.14, savaş ekranındaki yinelenen **Savaş Tekrarı** başlığını ve alttaki
bağımsız kontrol şeridini kaldırır. Duraklatma, yeniden oynatma, ses ve hız
eylemleri canlı olay akışındaki **Sunucu Sonucu** bölümünün en altına
ortalanmış düğmeler olarak yerleşir. Dar ekranlarda düğmeler satıra sarılır;
oynanış ve denge kuralları değişmez.

v0.4.0, kanıtlanmış bot prototipini ilk kalıcı çevrimiçi ürüne dönüştürür.
PostgreSQL ve Alembic şeması; otomatik güvenli adlı misafir oyuncu; kısa
ömürlü erişim ve her kullanımda döndürülen yenileme JWT'si; sunucuda saklanan
geçerli kart; gerçek oyuncu düzeni havuzu ve kalıcı maç/replay kaydı eklenir.
İstemci güvenli yenileme anahtarını saklar, açılışta oturumu geri yükler ve
kartı kaydedip asenkron rakip arar. Bot savaşları antrenman seçeneği olarak
korunur.

v0.4.3, çekirdek kapısında karşılıklı iki port yüzünden boşa çıkan destek
yerleşimini düzeltir. Batarya ile Güçlendirici dört portlu kavşaktır. Batarya
yönsüz biçimde enerji depolar; Güçlendirici bütün bağlı komşulara enerji
taşırken yalnız okun gösterdiği tek komşuyu güçlendirir. Savaş ekranındaki
**Yeni Oyun** eylemi üst köşeden kaldırılıp oynatma düğmelerinin altına
ortalanır.

v0.4.4, uygulamayı doğrudan devre düzenleyicide açmak yerine **Oyna**,
**Kariyer** ve **Ayarlar** seçenekli ana menüyle başlatır. Oyna ekranındaki
**Çevrimiçi Savaş** ile **Antrenman** tamamen ayrı düzenleyici akışlarıdır;
çevrimiçi ekranda bot seçimi, antrenmanda oyuncu eşleştirmesi görünmez.
Devre kartındaki her modül gerçek katalog değerlerinden üretilen kompakt
`C 30` ve role özgü ikinci etiketi gösterir. Ayrıntı fare/dokunma ipucunda
korunur. Kariyer ekranı görev sistemi tamamlanana kadar sahte ilerleme
üretmez; Ayarlar yeni savaş tekrarlarının ses ve hız başlangıcını belirler.

v0.4.5, savaş ekranındaki taşma ve hareketli kontrol sorunlarını giderir.
**Sunucu Sonucu** savaş başından itibaren görünür; çekirdek canı, kalan modül,
oynatılan hasar ve olay sayısı replay ilerledikçe güncellenir. Olay listesi
esnek/kaydırılabilir alanda, oynatma ve **Yeni Oyun** düğmeleri panelin sabit
alt bölümünde kalır. Doğrulama ve yerleşim mesajları okunamayan alt şerit
yerine devre kartına bağlı saydam, renk kodlu bildirimlerde gösterilir.
Batarya ile Güçlendiricinin dört yönlü oynanış yeteneği korunurken kart dışına
ve kapısız çekirdek kenarına bakan kullanılamayan port işaretleri gizlenir;
Güçlendiricinin yön oku döndürme düğmesi seçiliyken de görünür kalır.

v0.4.6, Ayarlardaki dört tekrar hızını tanımlayan sabit `double` kümesini
Dart analizörüyle uyumlu değişmez listeye dönüştürür. `0.25×`, `0.5×`, `1×`
ve `2×` seçenekleri değişmez; savaş paneli, bildirimler, port görünümü,
PostgreSQL şeması ve oyun dengesi v0.4.5 ile aynıdır.

v0.4.7, savaş panelinin sabit sonuç/kontrol düzenini eski widget hiyerarşisine
bağlayan testi gerçek ekrandaki düşey konuma göre doğrular. Küçük test
görünümünde kartın altında kalan bağlamsal bildirimin kapatma düğmesi tıklanmadan
önce görünür alana kaydırılır. Uygulama arayüzü, savaş kuralları ve veritabanı
şeması değişmez.

## v0.4.x kapsamı

- PostgreSQL bağlantısı, sağlık durumu ve Docker Compose geliştirme ortamı
- Alembic `20260729_0001` ilk şeması
- Otomatik güvenli adlı kalıcı misafir oyuncu
- 15 dakikalık erişim ve kullanımda döndürülen 30 günlük yenileme JWT'si
- Yenileme anahtarının yalnız SHA-256 özetiyle sunucuda tutulması
- Oyuncu başına tek geçerli, güncellenebilir sunucu kartı
- Aynı modül sayısındaki başka oyuncuların eşleştirme havuzu
- Kendi düzeniyle eşleşmeme ve son üç rakibi tekrar seçmeme
- Yeni gerçek oyuncu yoksa dengeli sunucu rakibine güvenli dönüş
- Gerçek oyuncu kartına karşı deterministik, sunucu yetkili savaş
- Oyuncu ve rakip kartı, sonuç, olaylar ve durum kareleriyle kalıcı replay
- Yalnız maç katılımcılarının erişebildiği asenkron maç/replay
- Güvenli depolanan Flutter yenileme anahtarı ve otomatik oturum geri yükleme
- Ana eylem olarak **Kartı Kaydet ve Oyuncu Bul**
- Ayrı **Antrenman** ekranında korunan dokuz sabit rakip
- Çevrimiçi ve antrenman içeriklerini birbirinden ayıran ana menü
- Kariyer hazırlık ekranı ve işlevsel savaş tekrarı ayarları
- Kart üstünde Can ile role özgü değeri gösteren kompakt bilgi etiketleri
- Savaş boyunca güncellenen sabit **Sunucu Sonucu** ve sabit oynatma kontrolleri
- Saydam, renk kodlu ve devre kartına bağlı doğrulama/yerleşim bildirimleri
- Yalnız kullanılabilir kart portlarını gösteren sade bağlantı görünümü

- Sekiz başlangıç modüllü Flutter arayüzü
- Ortasında 2×2 pasif çekirdek bulunan 4×4 devre kartı
- 12 yerleşim hücresi, dört simetrik çekirdek kapısı ve 6 modül sınırı
- Bir iç ve iki yan portlu, çekirdeğe dönük üç portlu Jeneratör
- Çekirdek üzerinden üç uzak kapı ve halka üzerinden iki yan kola dağıtım
- Paletten boş hücreye yerleştirme ve dolu hücredeki modülü değiştirme
- Kart modülünü boş hücreye taşıma ve dolu hücreyle yer değiştirme
- Kart modülünü palete geri bırakarak devreden kaldırma
- Sürükleme sırasında eyleme göre hücre vurgusu ve modül önizlemesi
- Modül seçme, dokunarak yerleştirme, döndürme ve kaldırma
- Tek satırlık, uyarlanabilir **Nasıl Oynanır?** yardım şeridi
- Amaç, enerji, yönler, sekiz modül ve savaş için ayrıntılı oyun el kitabı
- Çalışan örnek devre simülasyonu ve özellik sözlüğü
- Her modül için avantaj, dezavantaj ve faydalı kullanım açıklaması
- Dört yönlü Batarya kavşağı ve 6/6 savaş kartı bağlantı doğrulaması
- Kart başına 6 modüllük sunucu yetkili denge sınırı
- Gerçek bağlantı portlarını gösteren hücre kenarı işaretleri
- Modül ve çekirdek port merkezlerini birleştiren istemci kablo çizimi
- Sunucudan gelen enerjili/enerjisiz modül önizlemesi ve Türkçe modül adları
- Her biri 1–6 modüle ölçeklenen dokuz saldırı, savunma ve destek rakibi
- Dört Darbe Topulu yığına karşı üç Kalkanlı **Siper** düzeni
- Adım başına 8 enerji üreten Jeneratör ve 14 koruma üreten Kalkan
- Uzun süredir enerji alamayan hazır modüle deterministik eylem önceliği
- Dolu Kalkan, ısısız Soğutucu ve hedefsiz Onarım için enerji harcamama
- Kesintisiz enerji yetersizliğini tek uyarıda birleştiren olay günlüğü
- Saldırı modüllerinden önce hedef çeken savunma Kalkanları
- Sunucuda doğrulanan eşit modül sayılı eşleşme
- Sunucu yetkili bot maçı
- Match/replay checksum eşleşmesi
- İki 4×4 kart üzerinde tick tabanlı savaş tekrarı
- Savaş kartlarında görünür port noktaları ve porttan porta enerji parçacıkları
- Saldırı, çekirdek hasarı, kalkan, soğutma, onarım ve ısınma efektleri
- Sunucuda zorunlu modüller → Jeneratör → çekirdek hedefleme sırası
- Süre sonundaki altı ölçütü ve kararı veren ilk farkı gösteren sunucu sonucu
- Geniş ekranda yüksekliğe uyumlu, en fazla 460 px devre kartı
- Seçilen modül hücresinde beliren döndürme düğmesi
- Sabit yükseklikte, kendi kaydırma çubuklu dokuz rakip listesi
- Tam yazılan Can, Enerji, Isı ve `Hazır / Doluyor` etiketleri
- Anlık can/ısı kazanç ve kayıpları için renkli `+ / −` göstergeleri
- Olay günlüğünü tekrarlamayan sade savaş kartı alt alanı
- Duraklatılabilir, tamamen Türkçe canlı olay akışı
- Geniş ekranda iki kartın arasına yerleşen canlı olay akışı
- Savaşta gerçekleşen bütün olayları koruyan kaydırılabilir tam günlük
- Savaş sonunda aynı günlük alanında açılan sunucu sonucu
- Başlangıç, yeniden oynatma ve fare etkileşiminde kararlı tek kaydırma çubuğu
- Günlük panelinin üstünden geçen saldırı ışınları
- Jeneratörden enerjili modüllere ilerleyen hareketli iletim parçacıkları
- Modül hücresinde canlı can, enerji, ısı ve bekleme bilgisi
- Kart başlığında canlı kalkan, enerji rezervi ve üretim bilgisi
- Lazer, Darbe Topu, Kalkan ve diğer olaylar için özgün yerel ses efektleri
- Birbirini kesmeden eşzamanlı çalabilen bağımsız efekt kanalları
- Oyun el kitabının sonunda **Devre Laboratuvarına Dön** düğmesi
- Sunucu kataloğundan gelen modüle özgü taktik araç ipuçları
- 0.25×, 0.5×, 1× ve 2× tekrar hızı
- Sonuç açılmadan önce tamamlanan savaş akışı ve **Yeni Oyun** düğmesi
- Flutter web için sınırlı yerel geliştirme CORS desteği
- Güvenli ve tekrarlanabilir Flutter bootstrap betikleri
- Dört yönü ve tüm bağlantı tiplerini kapsayan motor, API ve Flutter testleri

## Gereksinimler

- Python 3.12
- Flutter 3.44 kararlı kanal
- Dart 3.11 veya üzeri
- PostgreSQL 17 veya Docker Desktop
- İlk istemci kurulumu için internet bağlantısı

Android ve web önceliklidir. Bu pakette platform iskeletleri bilinçli olarak
üretilmez; `bootstrap_client` betiği kurulu Flutter sürümünüzle güncel Android
ve web dosyalarını oluşturur, kaynak kodu geri yükler ve kontrolleri çalıştırır.

## 1. Sunucuyu çalıştırma

Önerilen geliştirme yolu Docker Compose'tur. Proje kökünde:

```powershell
Copy-Item .env.example .env
notepad .env
docker compose up --build
```

`.env` içindeki `RELAY_JWT_SECRET` değerini en az 32 karakterli rastgele bir
değerle değiştirin. Compose PostgreSQL sağlıklı olduktan sonra Alembic
migration'ını çalıştırır ve API'yi `http://127.0.0.1:8000` adresinde açar.

Yerel Python ve mevcut bir PostgreSQL ile çalıştırmak için:

PowerShell:

```powershell
cd project-relay
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -e ".[dev]"
Copy-Item .env.example .env
$env:RELAY_DATABASE_URL="postgresql+psycopg://relay:relay@127.0.0.1:5432/project_relay"
$env:RELAY_JWT_SECRET="yerel-gelistirme-icin-en-az-32-karakterli-gizli-deger"
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
.\.venv\Scripts\python.exe -m uvicorn relay_api.app:app --reload
```

Swagger:

```text
http://127.0.0.1:8000/docs
```

## 2. Flutter istemcisini hazırlama

Yeni bir PowerShell penceresinde:

```powershell
cd project-relay\client
Set-ExecutionPolicy -Scope Process Bypass
.\tool\bootstrap_client.ps1
```

Betik sırasıyla platform dosyalarını oluşturur, paketleri indirir,
`flutter analyze` ve `flutter test` çalıştırır.

## 3. Web'de oynatma

FastAPI açıkken:

```powershell
cd project-relay\client
flutter run -d edge --dart-define=RELAY_API_URL=http://127.0.0.1:8000
```

Akış:

1. Uygulama güvenli adlı misafir oyuncuyu otomatik oluşturur veya saklanan
   yenileme anahtarıyla aynı oturumu geri yükler.
2. **Oyun El Kitabı** ile amaç, enerji ve modül kurallarını inceleyin.
3. Paletten bir modülü boş hücreye sürükleyin; dolu hücreye bırakarak
   üzerindeki modülü değiştirin.
4. Karttaki modülü boş hücreye taşıyın veya dolu hücreyle yer değiştirin.
5. Modülü seçip döndürün; ok ön tarafı, noktalar gerçek portları gösterir.
6. **Bağlantıları Doğrula** ile enerji akışını sunucudan alın.
7. **Kartı Kaydet ve Oyuncu Bul** ile gerçek oyuncu düzeni havuzuna katılın
   ve asenkron savaşı başlatın.
8. İsterseniz **Bot Antrenmanı** bölümünü açıp sabit rakip seçin.
9. İki karttaki modül eylemlerini izleyin; akışı duraklatıp Türkçe olayları
   okuyun.

## Android emülatörü

Android emülatörü, bilgisayarın `localhost` adresine `10.0.2.2` üzerinden
ulaşır:

```powershell
flutter run -d emulator-5554 `
  --dart-define=RELAY_API_URL=http://10.0.2.2:8000
```

Fiziksel cihazda bilgisayarın yerel ağ IP adresini kullanın. Güvenlik duvarında
yalnızca geliştirme ağı için port izni verin.

## Tasarım sınırı

Bu sürüm kalıcı çevrimiçi temeldir. Aşağıdakiler v0.4.0'da yoktur:

- ELO, haftalık lig ve maç geçmişi,
- koşu içi mağaza ve geçici yükseltmeler,
- serbest oyuncu adı, sohbet, klan ve canlı 1v1,
- kalıcı rekabetçi modül gücü artışı,
- reklam veya satın alma.

Bu sınır, lig ve gelir katmanından önce kalıcı asenkron eşleştirmenin güvenli
ve kararlı çalışmasını doğrulamamızı sağlar. Ürün hedefi ve değiştirilemez
adalet kararları [ürün hedefi belgesinde](docs/URUN_HEDEFI.md), ayrıntılı
sürüm sırası ise [yol haritasında](docs/YOL_HARITASI.md) tutulur.

## Sonraki paket: v0.5.0

v0.5.0 rekabet görünürlüğünü ekleyecektir:

- ELO benzeri puan
- haftalık lig
- oyuncuya dönük maç geçmişi ve kayıtlı replay listesi
- rakip bulunurluğu ve eşleştirme ölçümleri

Kalıcı ham güç artışı, serbest oyuncu adı, sohbet ve canlı 1v1 yine
eklenmeyecektir.
