# Project Relay — Sürüm Yol Haritası

Bu yol haritası [bağlayıcı ürün hedefini](URUN_HEDEFI.md) uygulama sırasına
dönüştürür.

| Sürüm | Amaç | Durum |
|---|---|---|
| v0.1.0 | Deterministik savaş motoru ve sekiz modül | Tamamlandı |
| v0.2.0 | FastAPI, bot maçı ve replay sözleşmesi | Tamamlandı |
| v0.3.0 | Flutter/Flame oynanabilir bot prototipi | Tamamlandı |
| v0.3.1 | Flutter bootstrap ve analiz yaması | Tamamlandı |
| v0.3.2 | PowerShell platform argümanı yaması | Tamamlandı |
| v0.3.3 | Sürükle-bırak düzenleyici ve oyun anlatımı | Tamamlandı |
| v0.3.4 | Oyun el kitabı, port görünürlüğü ve dolu hücre işlemleri | Tamamlandı |
| v0.3.5 | Tam kart bağlantısı, öğretici simülasyon ve canlı savaş kartları | Tamamlandı |
| v0.3.6 | Savaş durumları, ortalanmış olay akışı ve özgün ses kimliği | Tamamlandı |
| v0.3.7 | Enerji animasyonu, tam olay günlüğü ve karşı-strateji dengesi | Tamamlandı |
| v0.3.8 | Olay günlüğü kaydırma ve eşzamanlı ses kararlılığı | Tamamlandı |
| v0.3.9 | Eşit modül eşleşmesi, günlük içi sonuç ve taktik ipuçları | Tamamlandı |
| v0.3.10 | Dört kapılı pasif merkezî çekirdek ve 12 hücreli çevre | Tamamlandı |
| v0.3.11 | Modüller → Jeneratör → çekirdek hedefleme sırası | Tamamlandı |
| v0.3.12 | Aktif enerji ekonomisi, akıllı destek ve adil eylem sırası | Tamamlandı |
| v0.3.13 | Porttan porta bağlantı çizgileri ve kompakt ana ekran | Tamamlandı |
| v0.3.14 | Sonuç kartına bağlı kompakt savaş oynatma kontrolleri | Tamamlandı |
| v0.4.0 | Kalıcı misafir hesap ve asenkron PvP temeli | Tamamlandı |
| v0.4.1 | Flutter UTF-8 oturum testi yaması | Tamamlandı |
| v0.4.2 | PostgreSQL 63 bit maç tohumu yaması | Tamamlandı |
| v0.4.3 | Dört portlu destek kavşakları ve savaş eylem düzeni | Tamamlandı |
| v0.4.4 | Ana menü, ayrık oyun kipleri ve kompakt modül bilgileri | Tamamlandı |
| v0.4.5 | Sabit savaş sonucu/kontrolleri ve bağlamsal arayüz uyarıları | Tamamlandı |
| v0.4.6 | Flutter sabit `double` hız listesi analiz uyumluluğu | Tamamlandı |
| v0.4.7 | Sabit savaş paneli ve kaydırılabilir bildirim widget test yaması | Tamamlandı |
| v0.4.8 | Ana menü el kitabı, dönüş düğmeleri ve modül etiketi okunabilirliği | Tamamlandı |
| v0.4.9 | Geniş modül paleti, sade devre hücreleri, savaş başlangıcı ve menü dönüşü | Hazır |
| v0.4.10 | Kompakt editör, 4×2 modül paleti ve büyük simgeli savaş kartları | Hazır |
| v0.4.11 | Modül paleti sonlu yükseklik ve Oyna ekranı açılış yaması | Hazır |
| v0.4.12 | Tek ekran editör/savaş yerleşimi ve orta panel genişliği | Hazır |
| v0.4.13 | Kompakt modül paleti ve güçlü savaş etiketleri | Hazır |
| v0.5.0 | Derece, haftalık lig ve maç geçmişi | Hazır |
| v0.6.0 | Koşu, mağaza, kit ve geçici yükseltme döngüsü | Sıradaki |
| v0.7.0 | Kapalı alfa, dengeleme ve kötüye kullanım koruması | Planlandı |
| v0.8.0 | Kozmetik/ödüllü reklam için kapalı gelir altyapısı | Planlandı |
| v1.0.0 | Android ve web açık beta | Hedef |

## Şimdiye kadar yapılanlar

### v0.1.0

- 4×4 kart doğrulama
- sekiz başlangıç modülü
- yönlü enerji bağlantısı
- enerji, ısı, aşırı ısınma, hasar, kalkan, soğutma ve onarım
- sabit tohumla aynı sonucu üreten motor
- sunucu tekrarına uygun olay kaydı
- gerçek beraberlik ve süre sonu ölçütleri

### v0.2.0

- FastAPI uygulaması ve kararlı JSON sözleşmesi
- modül/bot katalogları
- kart ve bağlantı doğrulama
- sunucu yetkili bot maçı
- ayrı maç ve replay yanıtları
- SHA-256 replay doğrulaması
- Swagger, Docker ve süreç içi prototip depo

### v0.3.0

- Flutter/Riverpod kart düzenleyici
- sekiz modül paleti
- yerleştirme, döndürme, kaldırma ve kablo çizimi
- API enerji önizlemesi
- üç bot seçimi
- match/replay checksum koruması
- Flame tick oynatıcı ve savaş efektleri
- sonuç ekranı ve tekrar hızı
- web geliştirme CORS politikası

### v0.3.1

- Flutter'ın varsayılan `widget_test.dart` dosyasını temizleyen bootstrap
- PowerShell ve Bash için kaynak/test dizinlerini tam geri yükleme
- temiz Flutter analizi için dört statik analiz düzeltmesi
- bootstrap davranışını koruyan sözleşme testi
- değişmeden korunan motor, API ve oynanış kapsamı

### v0.3.2

- PowerShell'de platform listesini tek argüman olarak aktaran açık dizi
- `android web` birleşme hatasını engelleyen gerileme testi
- temiz dağıtım arşivi
- değişmeden korunan motor, API ve oynanış kapsamı

### v0.3.3

- paletten 4×4 karta sürükle-bırak modül yerleştirme
- sürükleme geri bildirimi ve boş hücre bırakma önizlemesi
- korunmuş dokunarak yerleştirme, döndürme ve kaldırma
- geniş ve dar ekrana uyarlanan dört adımlı **Nasıl Oynanır?** kartı
- sürükle-bırak durum ve arayüz gerileme testleri
- değişmeden korunan sunucu yetkili savaş ve replay bütünlüğü

### v0.3.4

- amaç, enerji, yön, sekiz modül, ısı ve savaş kurallarını içeren oyun el kitabı
- hücre kenarlarında gerçek port noktaları ve belirgin bağlantı çizgileri
- dört yönde uç modül ve aktarma zinciri bağlantı testleri
- enerjisiz modüller için Türkçe ad ve hücre koordinatı
- kart modülünü boş hücreye taşıma ve dolu hücreyle yer değiştirme
- paletten dolu hücreye bırakıldığında eski modülü değiştirme
- değişmeden korunan savaş dengesi, sunucu yetkisi ve replay bütünlüğü

### v0.3.5

- Bataryayı dört yönlü enerji kavşağına dönüştüren kurallar v0.2
- dolu 4×4 kartın 16 modülünü birlikte enerjileyen motor ve API testleri
- kart modülünü palete geri bırakarak kaldırma
- çalışan örnek devre simülasyonu, özellik sözlüğü ve modül karşılaştırmaları
- oyuncu motivasyonu ile adil ilerleme hedeflerinin oyun içinde açıklanması
- oyuncu ve rakip düzenlerini içeren maç yanıtı
- iki gerçek kart üzerinde modül/hedef vurgulu savaş animasyonu
- duraklatma, 0.25× hız, tamamen Türkçe canlı olay akışı ve gizlenen erken sonuç
- on replay olay türünün her biri için ayrı yerel ses efekti
- sonuç ekranında geri oku yerine **Yeni Oyun** eylemi

### v0.3.6

- geniş ekranda iki kart arasına taşınan canlı olay akışı
- dar ekran için korunan tam genişlik olay paneli
- her savaş adımında sunucudan gelen kesin kart ve modül durum kareleri
- hücrelerde canlı can, enerji, ısı ve bekleme bilgileri
- kart başlıklarında kalkan, enerji rezervi ve üretim bilgileri
- Lazer ve Darbe Topu için modül türüne göre ayrı saldırı sesleri
- Kalkan dolumu ve hasar emme için ayrı savunma sesleri
- bütün savaş seslerini yeniden üreten yerel ses üretim betiği
- oyun el kitabının sonunda **Devre Laboratuvarına Dön** düğmesi
- değişmeden korunan savaş kuralları `0.2`, denge ve sunucu yetkisi

### v0.3.7

- jeneratörden bağlı modüllere ilerleyen canlı enerji iletim parçacıkları
- olay günlüğünün üst katmanında çizilen saldırı ışınları
- geniş ekranda son yedi olay sınırı olmadan bütün savaşı saklayan günlük
- kart başına altı modüllük sunucu yetkili denge sınırı
- Darbe Topunun enerji, hasar ve ısı değerlerini dengeleyen kurallar `0.3`
- sekiz farklı sunucu rakibi
- 21 tohum ve iki taraflı maçlarla her sunucu düzeni için kazanan karşı düzen
- Darbe Topu yığınına karşı Kalkan duvarını koruyan kritik gerileme testi

## v0.4.0 — Tamamlanan kalıcı çevrimiçi temel

Amaç gerçek asenkron oyuncu rekabetinin kalıcı, güvenli temelini kurmaktır.

- PostgreSQL 17 bağlantısı, bağlantı havuzu ve sağlık kontrolü
- Alembic `20260729_0001` ilk şeması
- otomatik güvenli ad taşıyan kalıcı misafir oyuncu
- 15 dakikalık erişim ve kullanımda döndürülen 30 günlük yenileme JWT'si
- yenileme anahtarının sunucuda yalnız SHA-256 özetiyle saklanması
- oyuncunun tek geçerli kartını sunucuda ekleme/güncelleme
- eşit modül sayılı gerçek oyuncu düzeni havuzu
- kendi kartıyla eşleşmeme ve son üç rakibi dışlama
- yeni oyuncu bulunamazsa dengeli sunucu rakibine dönüş
- deterministik motorla gerçek oyuncu düzenine karşı savaş
- kartlar, sonuç, olaylar ve durum kareleriyle kalıcı maç/replay
- yalnız katılımcıların asenkron replay erişimi
- Flutter güvenli oturum saklama, otomatik yenileme ve asenkron maç düğmesi
- kapalı Bot Antrenmanı alanında korunan eski prototip akışı
- migration, servis, API ve yeniden başlatma uçtan uca testleri

Tamamlanan kararlılık yamaları:

- v0.4.1, Flutter sahte JSON yanıtlarını UTF-8 kodlayarak Türkçe kart adının
  oturum yenileme testinde bozulmasını engelledi.
- v0.4.2, 63 bit savaş tohumunu PostgreSQL'de güvenle saklamak için
  `matches.seed` alanını Alembic `20260729_0002` ile `BIGINT` yaptı.
- v0.4.3, Batarya ile Güçlendiriciyi dört portlu enerji kavşakları olarak
  birleştirdi. Batarya yönsüz rezerv, Güçlendirici ise okla seçilen tek
  komşuya yönlü etki rolünü korudu. Savaş ekranındaki **Yeni Oyun** eylemi
  oynatma kontrollerinin altına taşındı.
- v0.4.4, açılışı ana menüye taşıdı; Çevrimiçi Savaş ile Antrenmanı ayrı
  ekranlara böldü. Kariyer kapsamı görünür fakat gerçek görev sistemi
  v0.6.0'a bırakıldı. Kart hücreleri Can ve role özgü gerçek katalog
  değerlerini kompakt olarak gösterir.
- v0.4.5, canlı olay panelindeki taşmayı giderdi; Sunucu Sonucunu savaş
  boyunca güncellenen sabit alana, oynatma düğmelerini sabit alt bölüme aldı.
  Doğrulama mesajlarını renk kodlu saydam karta taşıdı. Dört yönlü Batarya ve
  Güçlendirici kuralları korunurken yalnız kullanılabilir portlar çizilir ve
  Güçlendiricinin yön oku döndürme eyleminden ayrılır.
- v0.4.6, Ayarlar denetleyicisindeki sabit `double` kümesini değişmez listeye
  çevirerek Dart analizörünün `const_set_element_not_primitive_equality`
  hatasını giderdi. Tekrar hızları ve oynanış değişmedi.
- v0.4.7, oynatma kontrollerinin Sunucu Sonucu altındaki gerçek konumunu
  doğrulayan testi widget ağacındaki eski ebeveyn varsayımından ayırdı. Küçük
  ekran testinde kartın altındaki bildirimin kapatma düğmesi önce görünür alana
  kaydırılır. Arayüz ve oynanış değişmedi.
- v0.4.8, oyun el kitabını ana menüye taşıdı; Oyna ve Ayarlar ekranlarına
  görünür dönüş eylemleri ekledi. Çekirdek kapısı hücrelerinde modül adı ile
  özellik rozetlerini ayırdı ve Yeni Oyun artı simgesini kaldırdı. Oyun dengesi
  ve veri tabanı şeması değişmedi.

v0.4.0'a alınmayacaklar:

- ELO ve haftalık lig
- serbest oyuncu adı ve sohbet
- kalıcı modül istatistik artışı
- mağaza, reklam ve satın alma
- klan veya canlı 1v1

## v0.5.0 — Sıradaki paket

Kalıcı asenkron akış kanıtlandığı için sıradaki amaç rekabet sonucunu görünür
ve sürdürülebilir hâle getirmektir:

1. başlangıç derecesi ve sunucu yetkili ELO benzeri puan
2. eşleştirmede derece aralığı ve bot sonucunun dereceyi etkilememesi
3. haftalık lig bölümleri
4. oyuncuya dönük maç geçmişi
5. kalıcı replay listesinden tekrar izleme
6. sezon/hafta sınırı ve güvenli puan güncelleme işlemi
7. eşleştirme bulunurluğu ile rakip tekrar oranı ölçümleri

v0.5.0'da da mağaza, reklam, satın alma, sohbet, klan, canlı 1v1 veya
kalıcı ham güç artışı bulunmayacaktır.

## Değişmeyen karar kapıları

- Sunucu dışında hiçbir taraf maç sonucuna karar veremez.
- Kalıcı ilerleme rekabetçi ham güç vermez.
- İlk asenkron PvP kanıtlanmadan lig ve gelir katmanı eklenmez.
- Redis ancak PostgreSQL tabanlı akış ölçüldükten sonra değerlendirilir.
- Canlı 1v1, asenkron model dengelenmeden geliştirilmez.


## v0.5.0 — Hazır derece ve haftalık lig temeli

- Gerçek oyuncuya karşı asenkron maçlarda sunucu yetkili ELO benzeri derece
- Kesin beraberlikte sıfır derece değişimi; haftalık 1 puan
- Galibiyette haftalık 3 puan, mağlubiyette 0 puan
- Bot ve antrenman maçlarında sıfır derece etkisi
- Maç başına tek seferlik ve yeniden denemeye dayanıklı derece kaydı
- ISO haftasına bağlı lig sıralaması ve liderlik tablosu
- Katılımcı açısından maç/replay görünümü ve checksum doğrulaması
- Flutter Kariyer ekranında gerçek derece, lig ve maç geçmişi
- Değişmeden korunan kurallar `0.8`, modül dengesi ve kalıcı güç adaleti

Sonraki sürüm v0.6.0, bu rekabet temelini bozmadan koşu, mağaza, kontrollü
sekizli kit ve yalnız koşu içinde geçerli yükseltme döngüsünü kuracaktır.
