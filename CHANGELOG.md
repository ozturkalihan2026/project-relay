## v0.8.3 rev2 — Widget test kaydırma hotfix'i

- Profilin yatay bölüm seçicisindeki ekran dışında kalan Günlük Görevler ve
  Başarımlar seçenekleri, testte açık yatay kaydırma ile görünür hâle getirilir.
- Koleksiyon Kozmetik bölümündeki geç oluşturulan Ana Menüye Dön düğmesi,
  `collection-scroll-view` üzerinde `scrollUntilVisible` ile bulunur.
- Uyarıları `warnIfMissed: false` ile gizlemek yerine gerçek kullanıcı
  etkileşimi taklit edilir.
- Flutter istemci yapı numarası `0.8.3+47` oldu; API, veritabanı, savaş
  kuralları ve ürün davranışı değişmedi.

## v0.8.3 rev1 — Flutter analiz hotfix'i

- Profil ve üst oyuncu çubuğundaki gereksiz ikinci null-aware erişimler kaldırıldı.
- Klan alt bölüm durum değişkeni, `_clanSection` ekran oluşturma metoduyla ad
  çakışmayacak biçimde `_selectedClanSection` olarak yeniden adlandırıldı.
- Flutter istemci yapı numarası `0.8.3+46` oldu; API, veritabanı şeması, savaş
  kuralları ve ürün davranışı değişmedi.
- Analyzer regresyonlarını kaynak sözleşmesinde tekrar oluşmayacak şekilde
  koruyan kontroller eklendi.

## v0.8.3 — Ana Merkez ve Menü Düzeni

- Ana menü Oyna, Klan, Koleksiyon, Mağaza ve Profil alanlarında toplandı.
- Ayarlar ile Nasıl Oynanır üst çubuk simgelerine taşındı.
- Profil alanı derece, sezon, maç geçmişi, günlük görev ve başarımları birleştirdi.
- Alınabilir görev veya başarım ödülü için profil bildirim noktası eklendi.
- Kariyer, Oyna ekranındaki savaş türleri arasına taşındı.
- Koleksiyon Kit/Kozmetik olarak ayrıldı; satın alınmamış içerikler Mağazaya taşındı.
- Klan ekranı özet, üyeler, etkinlik ve ayarlar alt bölümlerine ayrıldı.
- Komutan Sistemi ve Oyuncu Tarzı Profili yalnız özellik havuzunda kaldı.
- API `0.8.3`, istemci `0.8.3+45`; şema ve savaş kuralları değişmedi.

## v0.8.2 — Sosyal Arayüz Ürünleştirme

- Sosyal Merkez Profil, Arkadaşlar ve Klan çalışma alanlarına ayrıldı.
- Sosyal özet kartı, giden istekler ve boş arama sonucu eklendi.
- Oyuncu profil özeti ile arkadaş/klan işlemlerine onay adımları eklendi.
- Klan kapasitesi ve liderin ayrılamama kuralı arayüzde görünür hâle geldi.
- Herkese açık metinler için kişisel bilgi paylaşmama uyarıları eklendi.
- Raporlama/engelleme henüz yokken Alfa Geri Bildirimi yönlendirmesi eklendi.
- Komutan Sistemi ve Oyuncu Tarzı Profili özellik havuzuna kaydedildi.
- API `0.8.2`, istemci `0.8.2+44`; şema ve savaş kuralları değişmedi.

## v0.8.1 — Flutter kabul ve paketleme hotfix'i

- Ana menü gezinme widget testinde görünür olmayan **Oyna** düğmesi tıklanmadan
  önce `ensureVisible` ile kaydırılır ve yerleşimin tamamlanması beklenir.
- Oyna ekranındaki geri düğmesi için `findsOneWidget` doğrulaması ve ek
  `pumpAndSettle` adımı eklendi.
- Windows PowerShell 5.1 uyumluluğu için `bootstrap_client.ps1` UTF-8 BOM ile
  paketlenir; Türkçe hata metinleri bozulmadan gösterilir.
- API `0.8.1`, istemci `0.8.1+43`; Alembic başı `20260801_0009`, savaş
  kuralları `0.8`, modül dengesi ve ürün davranışı değişmedi.
- 138 normal Python testi ile uzun stres testi hariç 5 denge regresyonu geçti.
- Gerçek `flutter analyze` ve `flutter test`, Flutter SDK bulunmadığı için paketleme
  ortamında çalıştırılamadı; Windows kabul komutu belgede korunur.

## v0.8.0 — Sosyal yapı ve klan temeli

- Oyuncu sosyal profili, durum mesajı ve favori modül
- Oyuncu arama, arkadaşlık isteği, kabul/ret ve arkadaşlıktan çıkarma
- Açık klan listesi, klan kurma, katılma ve ayrılma
- Tek klan üyeliği, 20 üye sınırı ve lider ayrılma koruması
- Yeni `SOSYAL VE KLAN` Flutter ekranı ve ana menü bağlantısı
- Nasıl Oynanır bölümünde sosyal/klan kuralları
- Alembic `20260801_0009` sosyal ve klan şeması
- API `0.8.0`, istemci `0.8.0+42`; savaş kuralları ve denge `0.8` olarak korundu
- Gelir sistemi, gerçek para ve kalıcı savaş gücü kapalı tutuldu

## v0.7.0 — Sezon, kapalı alfa ve kötüye kullanım koruması

- Takvim ayına bağlı Alfa Sezonu, sezon puanı ve sıralama eklendi.
- Yalnız gerçek oyuncuya karşı Asenkron PvP savaşları sezon puanı üretir;
  galibiyet 5, beraberlik 3, mağlubiyet 1 puandır. Bot ve antrenman hariçtir.
- Dört sezon ödül kademesi eklendi. Ödüller sezon + kademe anahtarıyla tek
  seferlik ve sunucu yetkilidir.
- Gerçek oyuncu maçı sonrası kazanılan sezon puanı ve yeni toplam, ortak savaş
  ödülü bildiriminde gösterilir; bot geri dönüşünde bu alan boş kalır.
- Aynı maçın iki kez sezon puanı vermesini engelleyen `season_match_points`
  kaydı eklendi.
- Kapalı alfa ekranına güvenlik durumu, istek sayaçları, sezon sıralaması ve
  geri bildirim formu eklendi.
- Oyuncu başına bir dakikada 20 Asenkron PvP isteği ve saatte 3 geri bildirim
  sınırı sunucuda kalıcı olarak uygulanır.
- `season_entries`, `season_match_points`, `alpha_feedback` ve `player_safety`
  tablolarını oluşturan Alembic `20260801_0008` geçişi eklendi.
- API `0.7.0`, istemci `0.7.0+41`; savaş kuralları `0.8`, modül dengesi ve
  kalıcı güç adaleti değişmedi.

## v0.6.2 rev1 — Görsel kozmetikler, dengeli ekonomi ve seviye kutlaması

- Kuşanılan devre kartı temaları editör ve oyuncunun savaş kartına uygulandı.
- Modül kaplamaları modül/port vurgularına ve saldırı darbelerinin rengine bağlandı.
- Profil çerçeveleri üst oyuncu bilgi çubuğunun çerçeve, parıltı ve avatarını değiştirir.
- Güçlendirici Ustalığı, kalıcı güçle karışmaması için **Boss Güçlendirici
  Kademeleri** olarak açıklandı; K2/K3/K4/K5 eşikleri 10/20/30/40'tır.
- İlk beş seviye korunurken üst seviye XP eğrisi uzun vadeli ilerleme için
  yavaşlatıldı. Savaş, günlük görev, başarım ve kariyer ödülleri yeniden dengelendi.
- Ücretli kozmetik kataloğunun toplam maliyeti 4.450 Devre Kredisine çıkarıldı.
- Asenkron savaş, görev/başarım ve tamamlanan kariyer koşusunda seviye atlanırsa
  yeni seviye ile kilit açılımını gösteren merkezî kutlama rozeti eklendi.
- Daha önce yerel Flutter doğrulamasında bulunan v0.6.2 const, kontrollü kit ve
  widget kaydırma gerileme düzeltmeleri tam pakete işlendi.
- İstemci `0.6.2+40`; API şeması `0.6.2`, savaş kuralları `0.8` olarak korundu.

## v0.6.2 — Koleksiyon ve kontrollü sekizli kit

- Ana menüye ayrı **Koleksiyon** ekranı eklendi.
- Oyuncuya sunucuda saklanan, adı değiştirilebilen sekiz yuvalı kontrollü kit
  verildi. Kit tam bir Jeneratör içerir; diğer türler en fazla üç kez seçilir.
- Savaş kartı altı modülle sınırlı kalırken kitteki iki ek yuva karşı devreye
  göre kullanılabilecek yedek seçeneklerdir.
- Çevrimiçi, Kariyer ve Antrenman editör paletleri aktif kitte kalan adetleri
  gösterir; tükenen modüller seçilemez veya sürüklenemez.
- Çevrimiçi ve Kariyer kartı kayıtları aktif kit sınırına göre sunucuda yeniden
  doğrulanır.
- Modül kaplaması, devre kartı teması ve profil çerçevesi koleksiyonu eklendi.
- Devre Kredisiyle çalışan kozmetik mağaza eklendi; kalıcı savaş gücü satılmaz.
- `player_cosmetics` ve `player_loadouts` tablolarını ekleyen Alembic
  `20260731_0007` geçişi oluşturuldu.
- Koleksiyon, satın alma, kuşanma ve kit uçları API'ye eklendi.
- API `0.6.2`, istemci `0.6.2+39`; savaş motoru ve denge değerleri değişmedi.

## v0.6.1 rev3 — Ayrı kariyer savaş akışı ve merkezî PvP ödülü

- Kariyer koşusu için `CareerBattleScreen` eklendi. Savaş motoru ve replay
  bileşenleri ortak kalırken kariyer yönlendirmesi normal, antrenman ve
  Asenkron PvP akışından ayrıldı.
- Kariyer savaş ekranındaki birincil düğme savaş bitene kadar pasiftir. Sonuca
  göre **Sonraki Savaş**, **Boss Hazırlığına Geç**, **Koşuyu Tamamla** veya
  **Kariyer Sonucuna Dön** metnini gösterir.
- **Sonraki Savaş** yeni maçı otomatik başlatmaz; oyuncuyu bir sonraki rakibin
  tam devre ön izlemesine ve kariyer devresini yeniden düzenleyebileceği ekrana
  geri götürür.
- Asenkron PvP savaşının XP ve Devre Kredisi kartı sayfa akışından kaldırıldı.
  Ödül, replay tamamlandığında oyunun ortak yarı saydam merkez bildiriminde
  gösterilir.
- Ortak replay kontrolleri farklı oyun modlarının kendi birincil düğme metni,
  anahtarı ve tamamlanma koşulunu kullanabileceği şekilde genelleştirildi.
- Nasıl Oynanır bölümü ayrı kariyer savaş ekranı, sonraki rakip hazırlığı ve
  merkezî PvP ödül bildirimiyle güncellendi.
- İstemci `0.6.1+38` oldu. API `0.6.1`, PostgreSQL şeması, savaş motoru ve
  denge değerleri değiştirilmedi.

## v0.6.1 rev2 — Birleşik bildirimler ve ayrılmış kariyer devresi

- Oyun genelindeki geçici mesajlar, kaydırmadan bağımsız olarak ekran ortasında
  görünen yarı saydam `RelayNotice` katmanına bağlandı; eski alt bar uyarıları
  kaldırıldı.
- Editör sayfasına sürekli görünen kaydırma çubuğu eklendi ve bildirimlerin
  yerleşim alanı tüketmesi engellendi.
- Kariyer kartı `career_boards` tablosu ve `/api/v1/me/career-board` uçlarıyla
  Asenkron PvP kartından ayrıldı. Mevcut oyuncular için ilk kullanımda tek
  seferlik kopyalama yapılır; sonraki düzenlemeler tamamen bağımsızdır.
- Tek portlu Lazer, Darbe Topu, Kalkan, Soğutucu ve Onarım Ünitesi okları gerçek
  enerji bağlantı portuna bakacak şekilde görsel olarak düzeltildi. Motorun port
  ve yön kuralları değiştirilmedi.
- Kariyer düğmeleri aşamaya göre **İlk Savaşa Başla**, **Sonraki Savaşa İlerle**
  ve **Boss Savaşına İlerle** olarak ayrıldı.
- Güçlendirici mağazası yalnız dördüncü zaferden sonra açılır. Oyuncu Devre
  Kredisi ile tek güçlendirici satın alabilir veya güçlendiricisiz boss'a
  ilerleyebilir.
- Nasıl Oynanır; ayrı kariyer/PvP kartları, tam rakip ön izlemesi, boss mağazası,
  yeni ok anlamları ve ortak bildirim sistemiyle güncellendi.
- Alembic `20260731_0006`, istemci `0.6.1+37`; API `0.6.1` ve savaş kuralları
  `0.8` olarak korundu.

## v0.6.1 — Kariyer koşusu ve tam rakip devre ön izlemesi

- Beş bağlantılı kariyer savaşı ve son aşamada bölüm sonu devresi eklendi.
- Savaş öncesi ön izleme ile gerçek savaş rakibinin aynı devre olması sunucu
  tarafında garanti edildi.
- Kariyer editörü ile oyuncu ön izlemeye göre karşı devresini kaydedebilir.
- İlk dört zaferden sonra üç geçici güçlendiriciden birini seçme akışı eklendi.
- Koşu içi jeneratör, başlangıç kalkanı, modül Canı ve enerji rezervi etkileri
  savaş motoruna taraf bazlı `BattleModifiers` olarak eklendi.
- Koşu sonucu XP/Devre Kredisi ödülü `run_id` ile idempotent hâle getirildi.
- `career_runs` tablosunu ekleyen Alembic `20260731_0005` geçişi eklendi.
- API `0.6.1`, istemci `0.6.1+37`; savaş kuralları `0.8` ve rekabetçi temel
  modül dengesi değişmedi.

## v0.6.0 UI rev1 — Kompakt editör ve oyuncu bilgi çubuğu

- Modül seçim kartları 74 px'ten 66 px'e indirildi; kart genişliği ve boşlukları
  sıkılaştırıldı. Modül adı, özellik yazısı ve simge boyutları değişmedi.
- Antrenman ekranında **Seçili Botla Savaş** alanının altına çevrimiçi kiptekiyle
  aynı ayrı **Menüye Dön** kartı eklendi.
- Ana menü, Oyna, Kariyer, İstatistikler ve her iki editör kipinde oyuncu adı,
  seviye, XP ilerlemesi ve Devre Kredisi gösteren ortak üst bilgi çubuğu eklendi.
- İstemci yapı numarası `0.6.0+35` oldu. Sunucu API'si, PostgreSQL şeması,
  savaş kuralları ve oyun dengesi değişmedi.

## v0.6.0 — İlerleme Temeli

- Kariyer ve İstatistikler ekranları ayrıldı.
- XP, seviye, Devre Kredisi ve tek seferlik maç ödülleri eklendi.
- Üç günlük görev, beş başarım ve ödül talep akışı eklendi.
- Oyuncu seviyesine bağlı geçici güçlendirici ustalık kademeleri eklendi.
- Replay sonuna XP/Kredi/seviye artışı kartı eklendi.
- Alembic `20260731_0004` ilerleme şeması eklendi.
- Kurallar `0.8`, derece sistemi ve temel modül dengesi değişmedi.

## v0.5.0 rev4 — Kesin 220×40 Yeni Oyun Düğmesi

- Tekrar ekranındaki **YENİ OYUN** düğmesi dış `SizedBox` ile kesin olarak
  220×40 px ölçüsüne sabitlendi.
- `VisualDensity.compact` nedeniyle minimum genişliğin 220 px'ten 212 px'e
  düşmesi engellendi.
- Piksel merkezi testi toleranslı kalırken düğme boyutu testi kesin 220×40
  kabul kriterini doğrulamaya devam eder.
- v0.4.9–v0.4.13 toplu regresyon sözleşmesine gerçek render ölçüsü koruması
  eklendi.

## v0.5.0

## v0.5.0 test hotfix rev3

- Replay kontrol hizalama testi, `FittedBox` dönüşümünün ürettiği makine
  hassasiyetindeki `double` farklarına karşı `closeTo(..., 0.001)` kullanır.
- v0.4.9–v0.4.13 arayüz kararları tek bir toplu regresyon sözleşmesine alındı.
- Üretim davranışı, oyun dengesi, API ve veritabanı şeması değiştirilmedi.


- Gerçek oyuncu asenkron maçlarına 1000 başlangıç puanlı, K=32 ELO benzeri
  derece sistemi eklendi. Kazanç/kayıp iki oyuncu arasında korunur ve maç
  sonucu `match_id` ile yalnız bir kez işlenir.
- Kesin beraberlik dereceyi değiştirmez; iki oyuncunun beraberlik kaydını ve
  haftalık 1 puanını işler. Galibiyet 3 haftalık puan, mağlubiyet 0 puan verir.
- Bot antrenmanı ile gerçek rakip bulunamadığındaki güvenli bot dönüşü derecesiz
  kalır; satın alınabilir veya kalıcı ham güç artışı eklenmedi.
- Haftalık ISO lig tablosu, oyuncu sırası, katılımcı sayısı ve gerçek oyuncu
  eşleşme oranı sunucu tarafında hesaplanır.
- `/api/v1/me/career`, `/api/v1/me/matches` ve `/api/v1/league/current`
  uçları eklendi. Maç yanıtı katılımcıya göre `rating_change` taşır.
- Rakip kartı kullanılan oyuncu maç ve replay'i kendi perspektifinden açar;
  kartlar, sonuç tarafları, olaylar, durum kareleri ve checksum birlikte çevrilir.
- Flutter Kariyer ekranı gerçek derece, haftalık lig, liderlik tablosu, rakip
  bulunurluğu ve tekrar açılabilir maç geçmişine dönüştürüldü.
- Alembic `20260731_0003` ile `player_ratings`, `league_entries` ve
  `match_rating_changes` tabloları eklendi.
- API `0.5.0`, istemci `0.5.0+33`, kurallar `0.8` oldu. Savaş motoru ve denge
  değerleri değişmedi.
- Flutter analizinde `career_screen.dart` içindeki kullanılmayan hata yığını
  parametresi Dart joker parametresi `_` ile değiştirildi;
  `no_leading_underscores_for_local_identifiers` uyarısı giderildi.
- Yerel Flutter kabul testlerinde eski maç fixture'larına zorunlu `created_at`
  alanı eklendi; ses ve replay testlerindeki zincirleme `Null` dönüşüm hataları
  giderildi.
- Çekirdek kapısı widget testi, v0.4.9'dan beri geçerli olan “kartta yalnız
  simge” sözleşmesine uyarlandı; kaldırılmış modül adı/özellik rozetlerini artık
  beklemiyor.
- Tekrar kontrolleri 500 px ve üzerindeki alanda tek satırda tutuldu; dar alanda
  mevcut satıra sarılma davranışı korundu.
- Widget testleri kaydırılabilir editör ve Kariyer ekranlarında görünmeyen
  düğme/bölümlere dokunmadan önce kaydırma yapacak şekilde sağlamlaştırıldı.

## v0.4.13

- Editör modül kartları 82 px'ten 74 px'e indirildi; 4×2 düzen, simge, ad ve
  sunucu özellikleri korunurken gereksiz dikey alan azaltıldı.
- Modül paleti dış dolgusu ve kartlar arası boşluk küçük ölçüde sıkılaştırıldı;
  geniş masaüstü kartları 255 px ile sınırlandırılıp ortalandı. Sonlu `Stack`
  yüksekliği korunarak Oyna ekranı donma düzeltmesi gerilemedi.
- Savaş devreleri üzerindeki **SEN** ve rakip adı 11 px'ten 14 px'e çıkarıldı,
  kalınlaştırıldı ve devre genişliğine sınırlandı.
- **Yeni Oyun** düğmesi aynı 220×40 px ölçüde bırakıldı; metin **YENİ OYUN**,
  14 px, kalın ve artırılmış harf aralığıyla yeniden tasarlandı.
- İstemci sürümü `0.4.13+32` oldu; sunucu kuralları, PostgreSQL şeması, savaş
  yerleşimi ve oyun dengesi değişmedi.

## v0.4.12

- Savaş devre kartlarının üst sınırı 520 px'ten 488 px'e indirildi; canlı olay
  akışına daha fazla yatay alan bırakıldı.
- Savaş sahnesi sabit 680 px yerine ekran yüksekliğine göre 540–620 px arasında
  hesaplanır; masaüstü savaş görünümü kaydırma gereksinimini azaltır.
- Canlı olay panelinin üst genişliği 540 px'e çıkarıldı ve sahne iç boşlukları
  dengelendi; hız kontrolünün aynı satırda kalması için alan genişletildi.
- Yeni Oyun düğmesi 220×40 px taban ölçüsüne çıkarıldı.
- Editör modül kartları 92 px'ten 82 px'e, palet satır aralığı 8 px'ten 6 px'e
  indirildi; 4×2 düzen ve içerik okunabilirliği korundu.
- İstemci sürümü `0.4.12+31` oldu; sunucu kuralları, PostgreSQL şeması ve oyun
  dengesi değişmedi.

## v0.4.11

- **Oyna** ekranını kilitleyen modül paleti yerleşim hatası giderildi.
- Modül seçim kartları 92 px kesin yüksekliğe bağlandı; `Stack` ve
  `Positioned.fill` artık sonlu genişlik/yükseklik kısıtlarıyla yerleşir.
- `Cannot hit test a render box with no size` ve `size.isFinite` hata zincirinin
  kök nedeni ortadan kaldırıldı.
- Flutter widget testine Oyna → Çevrimiçi Savaş açılışında istisna oluşmadığını
  ve palet kartının 92 px yüksekliğe sahip olduğunu doğrulayan gerileme kontrolü
  eklendi.
- İstemci sürümü `0.4.11+30` oldu; sunucu, PostgreSQL şeması, savaş kuralları ve
  denge değişmedi.

## v0.4.10

- Editördeki oyuncuya gereksiz **Sunucu Yetkili Savaş** kartı kaldırıldı.
- Bölüm numaraları 1, 2, 3 ve 4 olarak sadeleştirildi.
- Sağ işlem sütunu sağa taşındı; modül paleti geniş ekranda 4×2 düzene geçti.
- Modül simgesi, adı ve özellikleri seçim kartlarında ortalanıp büyütüldü.
- **Menüye Dön** düğmesi ayrı bir karta taşındı.
- Savaş devreleri editörle aynı 520 px üst sınıra çıkarıldı.
- Savaş modüllerinde metin kodları kaldırıldı; gerçek simgeler ve canlı durum
  değerleri korundu.
- İstemci sürümü `0.4.10+29` oldu; sunucu kuralları ve denge değişmedi.

# Değişiklik Günlüğü

## v0.4.9

- **Modül Seç** kartları büyütüldü. Oyuncu modül adıyla birlikte Can, enerji,
  depo, maliyet, hasar, kalkan, soğutma veya onarım değerlerini doğrudan
  palet üzerinde görür.
- Devre kartına yerleştirilen modüllerde ad ve kompakt özellik rozetleri
  kaldırıldı; hücrede yalnız büyütülmüş modül simgesi, gerçek portlar, yön
  göstergesi ve gerekli durum işaretleri kaldı.
- Döndürülebilen modüllerin döndürme düğmesi seçim beklemeden her zaman hücrenin
  sol üst köşesinde görünür. Jeneratör çekirdeğe kilitli, Batarya yönsüz olduğu
  için bu iki modülde döndürme düğmesi gösterilmez.
- Geniş ekran devre kartı üst sınırı 460 px'ten 520 px'e çıkarıldı; küçük
  ekran uyarlaması korunur.
- Çevrimiçi eşleşme ana eylemi **Savaşa Başla** olarak sadeleştirildi;
  kartı kaydetme ve rakip bulma işlemleri aynı sunucu akışında korunur.
- Ana eşleşme düğmesinin altına bir önceki Oyna menüsüne dönen görünür
  **Menüye Dön** düğmesi eklendi.
- Yeni görünüm Flutter ve Python sözleşme testlerine alındı.
- PostgreSQL şeması, API uçları ve oyun dengesi değişmedi. API `0.4.8`,
  istemci `0.4.9+28`, kurallar `0.8` olarak korunur.

## v0.4.8

- Ana menüye **Kariyer** ile **Ayarlar** arasına **Nasıl Oynanır** eklendi.
  Oyun el kitabı modül kataloğunu kendi yükleyen bağımsız menü akışına taşındı;
  kart düzenleyicinin üstündeki eski kısa yardım alanı kaldırıldı.
- **Oyna** ve **Ayarlar** ekranlarının altına görünür **Ana Menüye Dön**
  düğmeleri eklendi. Kariyer ekranındaki mevcut dönüş davranışıyla aynı gezinme
  sözleşmesi kullanıldı.
- Çekirdek kapısı hücrelerinde modül adı, kompakt özellik etiketleri ve
  **Çekirdek Kapısı** yazısı için birbirinden ayrılmış dikey alanlar oluşturuldu.
  Uzun modül adları ölçeklenerek görünür kalır ve özellik rozetleri adı kapatmaz.
- Savaş ekranındaki **Yeni Oyun** düğmesinin daire içindeki artı simgesi
  kaldırıldı; düğmenin konumu ve davranışı değişmedi.
- Menü sırası, dönüş düğmeleri, el kitabının yeni konumu, çekirdek kapısı
  okunabilirliği ve simgesiz Yeni Oyun düğmesi Flutter/Python sözleşme
  testlerine alındı.
- PostgreSQL şeması ve oyun dengesi değişmedi. API `0.4.8`, istemci
  `0.4.8+27`, kurallar `0.8` olarak korundu.

## v0.4.7

- Oynatma kontrolleri sabit **Sunucu Sonucu** alanının hemen altındaki bağımsız
  sabit bölüm olarak doğrulanır; gerileme testi artık kontrollerin sonuç
  kutusunun widget çocuğu olmasını beklemez.
- 800×600 widget testinde devre kartının altında kalan bağlamsal bildirimin
  kapatma düğmesi tıklanmadan önce görünür alana kaydırılır. Test artık
  ekrandaki gerçek kullanıcı etkileşimini izler ve boşa tıklama uyarısı üretmez.
- v0.4.6 arayüzü, tekrar hızları, PostgreSQL şeması ve oyun dengesi değişmedi.
  API `0.4.7`, istemci `0.4.7+26`, kurallar `0.8` olarak korundu.

## v0.4.6

- Ayarlar denetleyicisindeki desteklenen tekrar hızları `const Set<double>`
  yerine değişmez `List<double>` olarak tanımlandı. Dart analizörünün
  `const_set_element_not_primitive_equality` hatası giderildi.
- `0.25×`, `0.5×`, `1×` ve `2×` seçeneklerinin tamamının kabul edildiğini,
  desteklenmeyen hızların reddedilmeye devam ettiğini doğrulayan gerileme
  testleri eklendi.
- v0.4.5 savaş paneli, bağlamsal uyarı ve port görünümü düzeltmelerinin tamamı
  korunur. PostgreSQL şeması ve savaş dengesi değişmedi. API `0.4.6`,
  istemci `0.4.6+25`, kurallar `0.8` olarak korundu.

## v0.4.5

- `ReplayEventFeed` içindeki sabit olay listesi yüksekliği esnek/kaydırılabilir
  alana dönüştürüldü; 402 px yüksekliğindeki geniş ekran panelinde görülen
  `RenderFlex overflowed by 12 pixels` taşması giderildi.
- **Sunucu Sonucu** savaş başından itibaren görünür. Replay sürerken çekirdek
  canı, kalan modül, oynatılan hasar ve olay sayısı her adımda güncellenir;
  savaş bitince aynı sabit alan kesin karar tablosuna dönüşür.
- Sonuç alanına sabit yükseklik ayrıldığı için Duraklat/Devam Et, Yeniden
  Oynat, Ses, Hız ve **Yeni Oyun** kontrolleri savaş boyunca aynı alt konumda
  kalır.
- Yerleşim, doğrulama ve API mesajları okunamayan tam genişlikli alt
  SnackBar'dan çıkarılıp devre kartının altında saydam, kapatılabilir ve
  info/başarı/uyarı/hata renkli bağlamsal karta taşındı.
- Batarya ve Güçlendirici dört yönlü enerji kavşağı olarak kalır; yalnız kart
  içinde gerçekten kullanılabilecek veya çekirdek kapısına bağlanabilecek port
  işaretleri çizilir. Kart dışına ve kapısız çekirdek kenarına bakan ölü
  işaretler hem düzenleyicide hem savaş kartında gizlenir.
- Güçlendiricinin yön oku sağ üstte sürekli görünür; döndürme düğmesi sol üste
  taşındı ve okla çakışmaz.
- PostgreSQL şeması ve savaş dengesi değişmedi. API `0.4.5`, istemci
  `0.4.5+24`, kurallar `0.8` olarak korundu.

## v0.4.4

- Uygulama ilk açılışta doğrudan kart düzenleyici yerine **Oyna**,
  **Kariyer** ve **Ayarlar** seçenekli ana menüyü gösterir.
- **Oyna** altında **Çevrimiçi Savaş** ve **Antrenman** ayrı ekranlar ve ayrı
  düzenleyici kipleri olarak uygulanmıştır. Çevrimiçi ekranda bot listesi,
  antrenmanda misafir oyuncu/eşleştirme kartı görünmez.
- Kariyer, görev sistemi tamamlanana kadar sahte ödül veya ilerleme üretmeyen
  hazırlık ekranıdır.
- Ayarlar, yeni savaş tekrarlarının başlangıç sesi ve oynatma hızını belirler;
  savaş ekranındaki kontroller bu tercihleri güncellemeye devam eder.
- Kart hücreleri sunucu kataloğundaki gerçek Can değerini ve role özgü ikinci
  değeri kompakt etiketlerle gösterir: enerji, depo, hasar, kalkan, soğutma,
  güçlendirme veya onarım.
- PostgreSQL şeması ve savaş dengesi değişmedi. API `0.4.4`, istemci
  `0.4.4+23`, kurallar `0.8` olarak korunmuştur.

## v0.4.3

- Batarya ve Güçlendirici dört portlu enerji kavşakları olarak birleştirildi.
  Çekirdek kapısına yerleştirildiklerinde kenara bakan ölü bir uç nedeniyle
  işlevsiz kalmaz; halka üzerindeki iki kola da enerji taşıyabilir.
- Batarya yönsüz çalışmaya devam eder, kullanılmayan enerjiyi 20 birime kadar
  saklar ve istemcide gereksiz döndürme düğmesi göstermez.
- Güçlendiricinin oku bağlantı portlarını değil, güçlenecek tek komşu modülü
  seçer. Etki `1,35×`, ek ısı `1,25×` ve çarpan üst sınırları korunur.
- Savaş ekranının sağ üstündeki ayrı **Yeni Oyun** eylemi kaldırıldı.
  **Yeni Oyun**, Duraklat/Devam Et, Yeniden Oynat, Ses ve Hız kontrollerinin
  hemen altında ortalanmış düğme olarak sonuç alanına taşındı.
- Çekirdek kapısından iki kolu besleyen Batarya/Güçlendirici yerleşimleri,
  yalnız okun gösterdiği komşunun güçlenmesi, Bataryanın yönsüz davranışı ve
  yeni düğme konumu gerileme testlerine alındı.
- PostgreSQL şeması değişmedi. API sürümü `0.4.3`, istemci sürümü
  `0.4.3+22`, kurallar sürümü `0.8` oldu.

## v0.4.2

- PostgreSQL `matches.seed` alanı 32 bit `INTEGER` yerine 64 bit `BIGINT`
  olarak güncellendi. Savaş motorunun ürettiği 63 bit deterministik tohumlar
  artık kalıcı maç kaydı sırasında sayı sınırını aşmıyor.
- Mevcut v0.4.0/v0.4.1 veritabanlarını veri kaybetmeden güncelleyen Alembic
  `20260729_0002` migration'ı eklendi.
- PostgreSQL çevrimdışı DDL denetimi alanın `BIGINT` olduğunu; kalıcı maç
  gerileme testi de 32 bit sınırını aşan bir tohumun yazılıp tekrar
  okunabildiğini doğruluyor.
- Kart, eşleştirme, savaş ve replay sözleşmeleri ile oyun dengesi değişmedi.
  API sürümü `0.4.2`, istemci sürümü `0.4.2+21`; kurallar sürümü `0.7`
  olarak korundu.

## v0.4.1

- Flutter oturum API testlerindeki sahte JSON yanıtları açıkça UTF-8 olarak
  kodlanıyor. Böylece `Kalıcı Devre` gibi Latin-1 dışında kalan Türkçe
  karakterler `http.Response` oluşturulurken hata vermiyor.
- Erişim anahtarı yenilendikten sonra isteğin yalnız bir kez yinelenmesi ve
  Türkçe kart adının bozulmadan ayrıştırılması aynı gerileme testinde
  doğrulanıyor.
- Çevrimiçi oyun akışı, veritabanı şeması ve savaş kuralları değişmedi.
  API sürümü `0.4.1`, istemci sürümü `0.4.1+20`; kurallar sürümü `0.7`
  olarak korundu.

## v0.4.0

- PostgreSQL/SQLAlchemy kalıcı veri katmanı ve bağlantı sağlık kontrolü
  eklendi.
- Alembic `20260729_0001` migration'ı oyuncu, yenileme oturumu, kart ve
  maç/replay tablolarını oluşturuyor.
- Sunucu otomatik güvenli ad taşıyan kalıcı misafir oyuncu oluşturuyor.
- 15 dakikalık erişim JWT'si ve kullanımda döndürülen 30 günlük yenileme
  JWT'si eklendi; yenileme anahtarları veritabanında yalnız SHA-256 özetiyle
  tutuluyor ve eski anahtar yeniden kullanılamıyor.
- Oyuncu başına tek geçerli kart ekleme/güncelleme ve profil okuma uç
  noktaları eklendi.
- Asenkron eşleştirme aynı modül sayısındaki başka oyuncuyu seçiyor, oyuncunun
  kendi kartını ve son üç gerçek rakibini dışlıyor.
- Uygun yeni oyuncu düzeni bulunmazsa eşit modül sayılı dengeli sunucu rakibi
  kullanılıyor.
- Gerçek oyuncu kartına karşı savaş yine deterministik sunucu motorunda
  çalışıyor; hedefleme ve enerji kuralları `0.7` olarak değişmeden korunuyor.
- Asenkron maç; iki kartın anlık kopyası, sonuç, olaylar, durum kareleri ve
  checksum ile kalıcı kaydediliyor ve API yeniden başlatıldıktan sonra
  okunabiliyor.
- Özel asenkron maç/replay yalnız isteği oluşturan oyuncu ve rakip kartın
  sahibi tarafından okunabiliyor.
- Flutter yenileme anahtarını güvenli depoda tutuyor, açılışta oturumu
  döndürüyor ve süresi dolan erişim anahtarından sonra isteği bir kez
  yineliyor.
- Ana ekrana güvenli misafir rozeti ve **Kartı Kaydet ve Oyuncu Bul** eylemi
  eklendi; dokuz bot varsayılan kapalı **Bot Antrenmanı** alanına taşındı.
- Docker Compose PostgreSQL geliştirme ortamı, `.env.example`, migration,
  servis, API, yeniden başlatma ve istemci oturum testleri eklendi.
- API sürümü `0.4.0`, istemci sürümü `0.4.0+19`; savaş kuralları `0.7`
  olarak korundu.

## v0.3.14

- Sol üstteki ayrı **Savaş Tekrarı** başlığı kaldırıldı; ekranın tekrar
  niteliği canlı olay akışı, adım durumu ve oynatma eylemleriyle anlatılıyor.
- Alt taraftaki bağımsız geniş kontrol şeridi kaldırıldı.
- Duraklat/Devam Et, Yeniden Oynat, Ses ve Hız eylemleri olay günlüğündeki
  **Sunucu Sonucu** alanının en altına ortalanmış düğmeler olarak taşındı.
- Düğmeler dar ekranlarda taşmadan birden çok satıra sarılır; hız seçimi de
  diğer eylemlerle aynı düğme görünümünü kullanır.
- Olay listesinin kompakt yüksekliği yeni kontrollerin sonuç kartına
  sığabilmesi için ayarlandı; bütün olaylar kaydırma çubuğunda korunur.
- Yerleşim ve düğme davranışını doğrulayan üç yeni Flutter widget testi
  eklendi.
- Oynanış ve denge değişmedi. Kurallar sürümü `0.7`, API sürümü `0.3.14`,
  istemci sürümü `0.3.14+18` oldu.

## v0.3.13

- Düzenleyici bağlantı çizgileri hücre merkezlerinden türetilen yaklaşık
  noktalardan çıkarıldı; modüllerde görünen port işaretlerinin merkezleri
  ortak geometri hesabıyla kullanılıyor.
- Dört çekirdek kapısının hattı `kapı hücresi merkezi → çekirdek merkezi`
  yerine `modül portu → çekirdek portu` arasında çiziliyor.
- Kablo çizim katmanı modül kartlarının arkasına taşındı; kablo port
  işaretlerinin üzerinden geçmiyor ve modül içini kapatmıyor.
- Savaş tekrarındaki hareketli enerji iletimleri de merkezden merkeze çizimden
  çıkarıldı. Savaş modüllerine ve çekirdeğe görünür port noktaları eklendi;
  iletim çizgisi ile parçacığı bu iki port arasında hareket ediyor.
- Dört büyük adım kutulu **Nasıl Oynanır?** alanı, üç kısa eylem ve oyun el
  kitabı düğmesi içeren kompakt yardım şeridine dönüştürüldü.
- Ana ekranın azami genişliği, iki sütun aralığı, sağ panel genişliği, palet
  aralıkları, doğrulama kartı ve rakip seçici yüksekliği küçülen devre
  kartıyla yeniden oranlandı.
- Düzenleyici ve savaş kartlarındaki görünür port merkezlerinin kesin
  koordinatlarını doğrulayan beş Flutter geometri testi ve kompakt yardım
  şeridi yükseklik testi eklendi.
- Kurallar sürümü `0.7` olarak korundu; API sürümü `0.3.13`, istemci sürümü
  `0.3.13+17` oldu.

## v0.3.12

- Jeneratör üretimi adım başına `5 → 8` enerjiye çıkarıldı. Tek Darbe Topu
  artık Bataryasız çalışabilir; çoklu yaylım için Batarya rezervi önemini
  korur.
- Kalkan etkisi `12 → 14` oldu. Kalkanın savunma hedef önceliği silahların
  üzerine çıkarılarak kırılgan saldırı modüllerini koruması sağlandı.
- Enerji alamayan hazır modül bekleme puanı kazanır ve sonraki adımda öncelik
  alır; sabit hücre sırasının aynı modülü sürekli aç bırakması engellendi.
- Dolu Kalkan, ısısız devredeki Soğutucu ve hasarlı canlı hedef bulamayan
  Onarım artık enerji harcamaz, ısı üretmez veya beklemeye girmez.
- Aynı modülün kesintisiz enerji yetersizliği yalnız bir günlük olayı üretir;
  modül yeniden çalıştıktan sonraki yeni kesinti tekrar bildirilir.
- Savaş kartındaki `Bekleme: 0` gösterimi `Hazır`, pozitif değerler
  `Doluyor: N` olarak değiştirildi.
- `event_sound_player_test.dart` maç örneğine zorunlu sunucu `decision`
  alanı eklendi; `MatchResult.fromJson` içindeki null harita dönüşüm hatası
  giderildi.
- Dokuz rakibin 36 ikili eşleşmesi 21 tohumda iki taraflı oynatıldı. 1.512
  savaşta yenilmez sunucu düzeni oluşmadı; dört Darbe Topulu yığın Siper'e
  `0–42` kaybetti.
- Kurallar sürümü `0.7`, API sürümü `0.3.12`, istemci sürümü `0.3.12+16`
  oldu.

## v0.3.11

- Saldırılar, yaşayan Jeneratör dışı modül bulunduğu sürece Jeneratörü hedef
  alamaz.
- Diğer bütün modüller imha edildikten sonra Jeneratör hedefe açılır.
- Çekirdek yalnız Jeneratör de imha edildikten sonra hedef alınabilir.
- Aynı savaş adımında önceki saldırının yok ettiği hedefler için kullanılan
  yedek seçim de aynı aşamalı sırayı korur.
- Maç sonucu artık sunucunun altı süre sonu ölçütünü taşır ve arayüz kararı
  veren ilk farklı ölçütü **KARAR** etiketiyle gösterir. Eşit hasar ve kalan
  modül durumunda modül canı, enerji verimi veya toplam ısı farkı görünürdür.
- Eski geniş `Adım / Sen / Rakip / sonuç` özet şeridi kullanılmaz; merkezî
  çekirdek göstergeleri ve olay günlüğü aynı bilgiyi tekrar etmez.
- Ana ekrandaki devre kartı görünüm yüksekliğine göre 340–460 px arasında
  uyarlanır. Seçili modülün alt ayrıntı/silme kartı kaldırıldı ve döndürme
  düğmesi doğrudan seçilen hücreye taşındı.
- Dokuz rakip, sayfayı uzatmayan sabit yükseklikli ve kendi kaydırma çubuklu
  seçicide gösterilir.
- Savaş kartının altında olay günlüğünü tekrarlayan son olay metni kaldırıldı.
  Modül hücrelerinde `Can`, `Enerji`, `Isı` ve `Bekleme` açık yazılır; can ve
  ısı değişimleri renkli `+ / −` değerleriyle güncellenir.
- Hedef sırası motor davranışı, oyun el kitabı, API sözleşmesi ve savaş
  kuralları belgesinde birleştirildi.
- Kurallar sürümü `0.6`, API sürümü `0.3.11`, istemci sürümü `0.3.11+15`
  oldu.

## v0.3.10

- 4×4 kartın ortasındaki 2×2 alan, enerji üretmeyen ve depolamayan pasif
  çekirdeğe ayrıldı; çevrede 12 yerleşim hücresi kaldı.
- Çekirdeğe yalnız dört simetrik kapı hücresi bağlandı.
- Jeneratör yalnız çekirdek kapısına, çekirdeğe dönük yerleşir. Bir iç ve iki
  yan porttan oluşan üç portu çekirdeği ve halkanın iki yönünü besler.
- Çekirdek, jeneratörden aldığı enerjiyi diğer üç kapıya iletir. Böylece iki
  halka koluyla birlikte beş paralel uç beslenebilir; sistem tek seri halkaya
  dönüşmez.
- Çekirdek, kapılar ve canlı çekirdek canı düzenleyici ile savaş kartının
  ortasında gösterilir; eski alt savaş metrik kartı kaldırıldı.
- Bütün rakipler merkezî topolojiye taşındı. Üç Kalkanlı **Siper** eklendi;
  toplam dokuz rakibin 1–6 modüllük 54 varyantı bulunur.
- v0.3.9 ve v0.3.10 düzenleri aynı 21 tohumlu iki taraflı yöntemle
  karşılaştırıldı. 1.512 merkezî-topoloji savaşında yenilmez düzen bulunmadı.
  En güçlü düzenin kazandığı ikili eşleşme oranı `6/7`den `7/8`e çıktı; iki
  sürümde de bu düzeni çoğunlukla yenen en az bir karşı düzen bulunuyor.
- Dört Darbe Topulu riskli yığın **Siper** karşısında 42 savaşın tamamını
  kaybetti.
- Kurallar sürümü `0.5`, API sürümü `0.3.10`, istemci sürümü `0.3.10+14`
  oldu.

## v0.3.9

- Sunucu rakiplerinin her biri için 1–6 modüllük, tamamen enerjili eşleşme
  varyantları eklendi.
- Sunucu, oyuncu modül sayısına uygun rakip varyantını kendisi seçiyor ve iki
  tarafın modül sayısını simülasyondan önce doğruluyor.
- Eşit modül sayısı 48 rakip varyantı ve 336 çoklu savaşla gerileme testine
  alındı; altı modüllük karşı-strateji matrisi korundu.
- Sunucu sonucu ayrı karttan kaldırılıp olay günlüğünün alt bilgi alanına
  taşındı; savaş sırasında aynı alan durum kısaltmalarını gösteriyor.
- Modül kataloğuna taktik `description` alanı eklendi; araç ipuçlarındaki
  genel sürükleme metni kaldırıldı.
- Oyuncuya dönük **İlerleme Yolu** el kitabından çıkarıldı; proje yol haritası
  belgelerde korunuyor.
- Merkezî 2×2 çekirdek ve 12 hücrelik çevre topolojisi için kodlamadan önce
  uygulanacak dört kapılı enerji omurgası kararı belgelendi.

## v0.3.8

- Canlı olay günlüğü, savaş başlangıcında olay yokken dahi aynı
  `ScrollController` ve `ListView` örneğini bağlı tutacak şekilde düzenlendi.
- Açık kaydırma çubuğu ile liste aynı özel denetleyiciye bağlandı,
  `primary: false` kullanıldı ve masaüstü/web otomatik ikinci kaydırma çubuğu
  bu alan için kapatıldı.
- Savaş yeniden başlatılırken ve günlük üzerinde fareyle gezinirken oluşan
  `Scrollbar has no ScrollPosition attached` hatasına karşı widget testi
  eklendi.
- Sabit beşli ses havuzu kaldırıldı. Her eşzamanlı efekt bağımsız bir ses
  kanalı kullanıyor ve kanal yalnız efekt tamamlandığında serbest bırakılıyor.
- Hızlı olay akışı ile savaş ekranından çıkışta ses kanallarının yeniden
  kullanılmamasını ve güvenle kapatılmasını doğrulayan testler eklendi.
- Savaş motoru, kurallar `0.3`, modül dengesi ve sekiz rakip düzeni
  değiştirilmedi.

## v0.3.7+11

- Saldırı efekt katmanındaki `ValueListenable` türü için eksik Flutter
  Foundation içe aktarımı eklendi.
- Aynı eksikliğin dağıtım paketine yeniden girmesini önleyen istemci sözleşme
  testi eklendi.

## v0.3.7

- Savaş kartlarındaki Jeneratör bağlantılarında enerjinin modüllere ilerleyişini
  gösteren hareketli iletim parçacıkları eklendi.
- Saldırı ışınları olay günlüğünün üstünde çizilen etkileşimsiz bir efekt
  katmanına taşındı.
- Geniş ekran günlüğündeki son yedi olay sınırı kaldırıldı; gerçekleşmiş bütün
  savaş olayları kalıcı kaydırma çubuğuyla okunabilir hâle getirildi.
- Kritik denge denetimi, sınırsız kart doldurma ve eski Darbe Topu veriminin
  baskın stratejiye dönüşebildiğini gösterdi.
- Kurallar `0.3` ile kart başına altı modül sınırı getirildi.
- Darbe Topu 8 enerji, 16 hasar ve 30 ısı değerleriyle dengelendi.
- Sunucu rakip havuzu üç düzenden sekiz farklı kombinasyona çıkarıldı.
- 21 tohumda iki taraflı karşılaşmalar çalıştıran, her sunucu düzeni için en az
  bir kazanan karşı düzen şartı koyan denge testleri eklendi.

## v0.3.6

- Geniş savaş ekranındaki canlı olay akışı, iki rakip devre kartı arasındaki
  boş alana taşındı; dar ekranlarda okunabilir alt panel korunuyor.
- Sunucu replay yanıtına her savaş adımı için kesin kart ve modül durum
  kareleri eklendi.
- Modül hücrelerinde canlı can, enerji rolü/maliyeti, ısı ve bekleme süresi
  gösteriliyor; kart başlığında kalkan, enerji rezervi ve üretim izleniyor.
- Lazer ve Darbe Topu saldırıları modül türüne göre ayrı seslere bağlandı.
- Kalkan dolumu ve hasar emme için savunma hissi veren iki ayrı efekt eklendi.
- Bütün yerel savaş sesleri katmanlı ve yeniden üretilebilir özgün WAV
  efektleriyle yenilendi.
- Oyun el kitabının sonuna **Devre Laboratuvarına Dön** düğmesi eklendi.
- Replay durum kareleri için motor, API, model ve istemci sözleşme testleri
  eklendi. Savaş kuralları `0.2` olarak korundu.

## v0.3.5

- Batarya, enerjiyi döndürebilen ve birden fazla kola dağıtabilen dört yönlü
  kavşağa dönüştürüldü; savaş kuralları `0.2` oldu.
- Doğru düzenlenmiş dolu 4×4 kartta 16 modülün tamamının enerji aldığını
  doğrulayan motor ve API gerileme testleri eklendi.
- Kart modülünü palete geri bırakarak devreden kaldırma eklendi.
- Oyun el kitabına çalışan örnek devre simülasyonu, on özellik için sözlük,
  sekiz modül için avantaj/dezavantaj ve adil ilerleme yolu eklendi.
- Maç yanıtına oyuncu ve rakibin gerçek kart düzenleri eklendi.
- Savaş tekrarı iki 4×4 kartı, modül canlarını, eylem/hedef vurgularını ve
  imha durumlarını gösterir hâle getirildi.
- Replay duraklatma, `0.25×` hız ve sonuç tamamlanana kadar gizleme eklendi.
- Bütün replay olayları Türkçe modül adlarıyla canlı ve kaydırılabilir akışta
  gösteriliyor; teknik kimlikler kullanıcı metninden kaldırıldı.
- On replay olay türü için ayrı yerel WAV sesleri ve ses açma/kapama eklendi.
- Savaş ekranındaki geri oku **Yeni Oyun** düğmesiyle değiştirildi.

## v0.3.4

- **Nasıl Oynanır?** kartından açılan tam ekran oyun el kitabı eklendi.
- El kitabına oyunun amacı, enerji akışı, ok/port farkı, sekiz başlangıç
  modülünün bağlantıları ve etkileri, ısı, doğrulama ve savaş kuralları
  eklendi.
- Modül portları devre hücrelerinin gerçek bağlantı kenarlarında görünür
  hâle getirildi; kablo çizgileri hücrelerin üzerinde belirginleştirildi.
- Tek portlu uç modüllerin ve iki portlu aktarma modüllerinin dört yönlü
  bağlantıları motor, API ve Flutter model testleriyle doğrulandı.
- Enerjisiz modüller doğrulama kartında teknik İngilizce kimlikleri yerine
  Türkçe adları ve hücre koordinatlarıyla gösteriliyor.
- Karttaki modül boş hücreye sürüklendiğinde taşınıyor; dolu hücreye
  sürüklendiğinde iki modül yer değiştiriyor.
- Paletten dolu hücreye bırakılan modül, hücredeki eski modülün yerini alıyor.
- Taşıma, yer değiştirme, palet değişimi, tek jeneratör kuralı ve doğrulama
  temizliği için gerileme testleri eklendi.
- Savaş motorunun sayısal denge değerleri ve sunucu yetkili replay kuralları
  değiştirilmedi.

## v0.3.3

- Sekiz modül paletinden 4×4 devre kartındaki boş hücrelere sürükle-bırak
  yerleştirme eklendi.
- Sürüklenen modül için imleç geri bildirimi ve kart üzerinde canlı bırakma
  önizlemesi eklendi.
- Dolu hücrelerin bırakmayı reddetmesi ve tek jeneratör kuralı korundu.
- Seçip hücreye dokunarak yerleştirme erişilebilir yedek yöntem olarak
  korunmaya devam ediyor.
- Düzenleyicinin üstüne, geniş ve dar ekranlara uyarlanan dört adımlı
  **Nasıl Oynanır?** kartı eklendi.
- Doğru `RelayApp` açılışını sınayan `widget_test.dart` dağıtım paketine
  dâhil edildi.
- Sürükle-bırak durum yönetimi ve arayüz sözleşmesi için gerileme testleri
  eklendi.
- Savaş motoru, sunucu yetkili sonuç ve replay checksum kuralları
  değiştirilmedi.

## v0.3.2

- PowerShell bootstrap çağrısındaki `android,web` platform listesi açık bir
  dize dizisine taşındı.
- Platform listesi artık Flutter'a tek
  `--platforms=android,web` argümanı olarak aktarılıyor.
- Windows'a özgü argüman ayrıştırma hatasını koruyan istemci sözleşme testi
  eklendi.
- Paketleme sırasında oluşan Python `egg-info` ve önbellek artıkları dağıtım
  arşivinden çıkarıldı.
- Oynanış, savaş kuralları ve v0.4.0 yol haritası değiştirilmedi.

## v0.3.1

- `flutter create` tarafından üretilen varsayılan `test/widget_test.dart`
  dosyasının paket testleriyle karışması önlendi.
- PowerShell ve Bash hazırlama betikleri, üretilen `lib` ve `test` dizinlerini
  paket kaynaklarıyla artık tamamen değiştiriyor.
- PowerShell betiği her Flutter komutunun çıkış kodunu denetliyor; analiz veya
  test başarısızsa başarı mesajı vermeden duruyor.
- Flame `render` üst sınıf çağrısı eklendi.
- Kullanılmayan yerel değişken ve kullanılmayan kurucu parametresi kaldırıldı.
- Nullable widget koleksiyon öğesi güncel Dart sözdizimine taşındı.
- Bootstrap temizleme davranışını koruyan istemci sözleşme testi eklendi.
- Oynanış, savaş kuralları ve v0.4.0 yol haritası değiştirilmedi.

## v0.3.0

- Flutter 3.44 ve Riverpod 3 tabanlı ilk istemci eklendi.
- Sekiz modüllü 4×4 kart düzenleyici oluşturuldu.
- Modül yerleştirme, seçme, döndürme, kaldırma ve sıfırlama eklendi.
- Yönlü portlar ve enerji kabloları görselleştirildi.
- API doğrulamasından gelen enerjili/enerjisiz modüller kartta işaretlendi.
- Üç sunucu botu için rakip seçimi ve maç başlatma akışı eklendi.
- Maç ve replay checksum eşleşmesi istemcide zorunlu hâle getirildi.
- Flame ile tick tabanlı sade savaş tekrar ekranı eklendi.
- Tekrar hızı, sonuç özeti ve replay kimliği gösterildi.
- Yerel Flutter web geliştirmesi için sınırlı CORS politikası eklendi.
- İstemci model, kart durumu ve replay zaman çizelgesi testleri eklendi.

## v0.2.0

- Deterministik motor FastAPI katmanına bağlandı.
- Kart doğrulama ve enerji bağlantısı önizleme uç noktası eklendi.
- Sekiz modüllük sunucu kataloğu eklendi.
- Kolay, orta ve zor üç sabit bot düzeni eklendi.
- Bot maçı, maç sonucu ve ayrı tekrar uç noktaları eklendi.
- Sunucu tarafından üretilen maç tohumu kullanıldı.
- Tekrar checksum hesaplama ve doğrulama API'si eklendi.
- Süreç içi, kilit korumalı prototip maç deposu eklendi.
- Tek biçimli `404` ve `422` hata sözleşmeleri eklendi.
- Docker çalıştırma yapısı ve API testleri eklendi.

## v0.1.0

- 4×4 yönlü devre ve sekiz başlangıç modülü oluşturuldu.
- Deterministik enerji, ısı, hasar, kalkan, soğutma ve onarım motoru eklendi.
- Olay tabanlı savaş tekrarı ve süre sonu eşitlik bozma kuralları eklendi.
