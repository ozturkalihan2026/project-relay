# Codex Çalışma Devri

Bu belge, Project Relay üzerinde iş ve ev bilgisayarları arasında güvenli şekilde
devam etmek için tutulan kısa ve kalıcı bağlamdır. Tam sohbet dökümü değildir.

## Depo durumu

- Son güncelleme: 2026-08-15 (Europe/Istanbul)
- Depo: `https://github.com/ozturkalihan2026/project-relay.git`
- Aktif dal: `main` (`origin/main` takip ediliyor)
- Son doğrulanmış commit: `aaa24da` — `hotfix`
- Senkronizasyon: Bu güncelleme hazırlanırken yerel `main` ile `origin/main` aynı
  commit'i gösteriyordu.
- Çalışma ağacı: Güncelleme başlamadan önce temizdi.

## Aktif amaç

**v0.8.23 - Tek Savaş Sahnesi ve Fiziksel Devre Görünümü** paketini uygulamak.
Mevcut sunucu-otoriter ve kalıcı canlı kariyer oturumu korunacak; ancak savaş
tamamlandığında otomatik replay ekranına geçilmeyecek. Hazırlık, gerçek savaş,
kesintisiz raf müdahalesi ve sonuç tek sahnede birleşecek. Hazırlık/kariyer/savaş
kartları aynı fiziksel modül, çekirdek, port, kablo ve enerji akış sistemini
kullanacak. Araç seçimi Flutter, Flame, Rive veya `flutter_unity_widget`/Unity
etiketine göre değil, hedeflenen fiziksel görünüm ile ölçülen platform maliyetine
göre yapılacak.

## Tamamlananlar

- GitHub deposunun `origin` bağlantısı ve `main` takip durumu doğrulandı.
- Depo genelinde geçerli Codex çalışma kuralları `AGENTS.md` içine yazıldı.
- Oturum başlangıcı, doğrulama ve bilgisayar değiştirme protokolü tanımlandı.
- Kullanıcının kararıyla henüz entegre edilmemiş Rive taslak belgeleri kaldırıldı;
  Rive çalışması şimdilik kapsam dışı bırakıldı.
- Çevrimiçi hazırlıktaki doğrulama öncesi bilgi kartı ve Haftalık Protokol
  başlığındaki gereksiz simge kaldırıldı.
- Savaş ekranı uzun `ListView` yerine sahnenin kalan yüksekliği kullandığı tek
  görünüm düzenine geçirildi.
- Canlı savaş sırasında toplam adım sayısı gizlendi; durum `SİNYAL AKIŞI • CANLI`
  olarak gösteriliyor.
- Savaş sonu analiz düğmesi ve alt panel kaldırıldı. Kompakt sonuç, karar ölçütleri,
  metrikler ve savaşın yıldızı iki devre arasındaki merkez panelde otomatik
  gösteriliyor.
- Savaş müziği seviyesi `0.12` değerinden `0.20` değerine çıkarıldı. Ortam müziği
  eşzamanlaması aynı kaynağı tekrar başlatmak yerine yüklenmiş kaynağı sürdürür.
- Çevrimiçi hazırlık `PreparationWorkspace` altyapısını kullanıyor. Kariyer
  hazırlığı ise yalnız ekran bölgelerini görsel olarak eşleyen bağımsız
  `_CareerPreparationLayout` altyapısıyla yönetiliyor.
- Kariyerin büyük devre alanında oyuncu devresi ile koşu/rakip devresi birlikte
  gösteriliyor; durum ve seçili modül ayrıntıları ayrı sağ panelde, modül rafı
  altta kalıyor.
- Kompakt modül rafındaki sıkıştırılmış ad/istatistik satırları kaldırıldı;
  modüller 3B kasa, işlev glifi ve kalan adet rozetiyle gösteriliyor. Tam bilgiler
  tooltip ve sağ inceleyicide korunuyor.
- Hazırlık devresinin perspektif eğimi azaltıldı ve sahne sınırları kırpıldı;
  alt hücrelerin komşu arayüz alanlarına taşması engellendi.
- Uzun ve iç içe kaydırılan widget testleri için kaydırma yardımcısı doğrudan
  hedef ScrollPosition üzerinden ilerleyecek şekilde sağlamlaştırıldı.
- Devre bağlantıları düz çizgi yerine portlar arasında kıvrımlı kablo yolları ve
  jeneratörden dışarı yönlenen hareketli akış paketleri kullanıyor. Batarya
  bağlantıları çift yönlü; onarım, soğutma, kalkan ve güçlendirme akışları ayrı
  renk/işaretle çiziliyor.
- Kalkan modülü glifi klasik kalkan silueti, iç çerçeve ve enerji omurgasıyla
  yeniden çizildi.
- Yeni oyuncular için ana menü → çevrimiçi hazırlık → modül yerleştirme → savaş
  → ayarlar/ses yolunu izleyen, atlanabilir ve tamamlanma durumu güvenli depoda
  saklanan dört adımlı ilk kullanım turu eklendi.
- Menü ve savaş müzikleri depo içindeki `tool/generate_music.dart` ile üretilen
  24 saniyelik stereo özgün döngüler olarak yenilendi. Kaynak bilgisi
  `client/assets/sounds/README.md` içinde tutuluyor.
- Devre akış animasyonu bekleme boşluğu olmadan kesintisiz döngüye alındı ve
  sistemin “animasyonları azalt” tercihini destekliyor.
- Yeni `Öneri Düzenleme.docx` belgesindeki `_CareerDualBoardStage.key` analiz
  uyarısı, kullanılmayan kurucu parametresi kaldırılarak giderildi.
- Savaş temposu için yapılan ölçümde dokuz sunucu stratejisinin 21 tohumlu tüm
  1.701 eşleşmesinin %61,85'i 90. adım zaman aşımına ulaştı. Yalnız sınırı 300'e
  yükselten 405 savaşlık örnekte bile zaman aşımı %29,63 ve ortalama süre 204,44
  adım oldu; bu nedenle sınırsız döngü yerine kademeli ani-ölüm öneriliyor.
- Ana menü müziği `0.22` seviyesine indirildi. Seviye atlamaya 2,8 saniyelik havai
  fişek katmanı ile yerel olarak üretilen kısa kutlama/alkış efekti eklendi.
- Kariyer doğrulama, koşuyu başlatma/bırakma ve menüye dönme eylemleri sağ modül
  inceleyicisinin altına taşındı; kariyer yolu ve çift-devre alanı sıkıştırıldı.
- Hazırlık perspektifi ve port yerleşimleri eşlendi; kablolar sabit görünür portlar
  arasında çiziliyor ve çekirdek enerji akışı merkezin üzerinde görünür kalıyor.
- Modül gliflerine derinlik, savaş kartlarına aydınlık platform/kasa katmanları,
  imha olaylarına daha uzun yüzen etiket ve parçacık, çekirdek çöküşüne daha büyük
  patlama eklendi. Savaş temposu kare başına daha yavaş ve izlenebilir yapıldı.
- Yalnız `source == "async"` eşleşmelerde 90. adımdan sonra aşırı yük etkinleşiyor:
  91/106/121/136. adımlarda saldırı artıyor, destek etkileri azalıyor ve savaş en
  fazla 150. adıma uzuyor. Aşırı yük replay olayı, sistem etiketi ve görsel uyarısı
  istemciye eklendi.
- `InterventionPolicy` ve `ModuleHealthRack` çekirdeği eklendi. 60/90/120
  pencereleri, savaşta toplam iki değişim, pencerede en fazla bir değişim, ilk
  yedeğin tam canla girmesi ve raftaki/giren modülün korunmuş canla dönmesi testli.
- `LiveBattleSession` eklendi. Mevcut `simulate()` aynı sonuç sözleşmesini koruyarak
  bu tick bazlı oturumu kullanıyor; kesintisiz simülasyon ile adım adım ilerletilen
  oturum aynı seed için birebir aynı replay sonucunu üretiyor.
- Müdahale rafı 60–89, 90–119 ve 120–savaş sonu aralıklarında savaş durmadan açık
  kalıyor. Geçerli sürükleme isteği mevcut aralığı hemen tüketiyor, modül değişimi
  bir sonraki güvenli tick sınırında uygulanıyor ve `module_swap` replay olayı
  üretiliyor.
- Canlı oturum; güncel kartları, state frame'i, kalan hakları, aktif/yedek modül
  kimliklerini ve bekleyen değişimi taşıyan API'ye hazır bir snapshot üretiyor.
- Savaş merkez analizindeki `Scrollbar` için kalıcı ve hem `Scrollbar` hem içerik
  tarafından paylaşılan özel denetleyici eklendi; fare hover sırasında oluşan
  `ScrollController has no ScrollPosition` hatası regresyon testiyle kapatıldı.
- Hazırlık ve savaş kartı ölçüleri `CircuitPresentationSpec`, fiziksel kablo yolu,
  kaplaması, ışığı ve hareketli enerji paketleri `CircuitCableVisual` altında
  ortaklaştırıldı. Hazırlık kartının gereksiz vida/alt uç süsleri kaldırıldı.
- Modüller düz simge yerine kasası, iç plakası, bağlantı noktaları ve türe özgü
  mekanizması bulunan `ModuleHardware` donanımına geçirildi. Canlı değişimde yeni
  donanım `AnimatedSwitcher` ile bir sonraki tickte kartın üzerine oturuyor.
- Tekrarda merkezdeki yinelenen “Savaş Analizi” başlığı, tamamlanınca üstte kalan
  ikinci sonuç etiketi ve alt hız seçici kaldırıldı. Hız ayarlardaki kayıtlı değerle
  uygulanmaya devam ediyor; ana menü müziği `0.28` seviyesine çıkarıldı.
- `career_battle_sessions` tablosu ve `20260814_0016` Alembic göçü eklendi.
  Başlangıç kartları, seed, modifier'lar, yedekler, komut günlüğü, güncel tick ve
  kesin maç kimliği saklanıyor; servis yeniden başlasa da aynı savaş kuruluyor.
- Kariyer canlı savaş başlatma/okuma/ilerletme/değişim endpoint'leri ve Flutter
  istemci modelleri eklendi. Eski tek çağrılı kariyer savaş endpoint'i geriye
  uyumluluk için korunuyor.
- `CareerLiveBattleScreen` eklendi. İki devre ve enerji akışları savaş boyunca
  güncelleniyor; alt raf sürekli görünür, yalnız müdahale hakkı açıkken sürüklenir,
  tek değişimden sonra kilitlenir ve simülasyon isteği hiçbir modal/pause olmadan
  sürer. Mevcut uygulamada savaş tamamlanınca kesin replay ekranına geçilir;
  v0.8.23'ün ilk işi bu ikinci oynatımı kaldırmaktır.
- `module_swap` replay olayı artık tekrar yerleşimini de güncelliyor; yeni modül
  olaydan önce değil, değişimin uygulandığı tickten itibaren doğru hücre ve yönde
  çiziliyor.

## Mevcut kullanıcı çalışması

- Önceki canlı savaş, müdahale, Alembic, API ve Flutter değişiklikleri `aaa24da`
  commit'inde yer alıyor ve `origin/main` üzerine gönderilmiş durumda.
- Bu belge güncellenmeden önce izlenen veya izlenmeyen kullanıcı değişikliği yoktu.
- Yeni v0.8.23 iş paketi henüz kodlanmaya başlanmadı. İlk kod değişikliği,
  `CareerLiveBattleScreen` tamamlanma akışından otomatik replay geçişini kaldırıp
  sonucu aynı canlı sahnede göstermelidir.

## Alınan kararlar

- Kod ve belgeler için tek doğruluk kaynağı GitHub'dır.
- Kalıcı proje kuralları `AGENTS.md` içinde tutulur.
- Oturumlar arası kısa teknik bağlam bu dosyada tutulur.
- Gizli bilgiler ve tam sohbet geçmişi depoya yazılmaz.
- Rive doğrudan seçilmiş mimari değildir. Flame ve `flutter_unity_widget`/Unity ile
  birlikte yalnız kısa bir görsel/performans prototipinde değerlendirilir;
  prototip ihtiyacı kanıtlamadan bağımlılık, asset veya platform yapılandırması
  eklenmez.
- Canlı savaş ekranı toplam tur/adım süresini göstermeyecek; ayrıntılı teknik adım
  bilgisi yalnız savaş sonu analizinde bulunabilir.
- Savaş analizi ayrı bir düğme veya alt panel açmadan, savaş tamamlandığında iki
  devre arasındaki merkez alanda gösterilecek.
- Bilgisayar değiştirmeden önce test, devir güncellemesi, commit ve push;
  diğer bilgisayarda işe başlamadan önce `git pull --ff-only` yapılır.
- Yeni savaş modu yönü: mevcut asenkron eşleştirme 90. adımdan sonra kademeli
  aşırı yük kullanacak. Kariyer ve kurulacak canlı oyuncu eşleştirmesi ise savaş
  durmadan 60. adımdan itibaren toplam iki modül değişimiyle sınırlı müdahale hakkı
  verecek.
  Rafa alınan modül mevcut canını koruyacak; ilk kez giren yedek tam canla,
  daha önce kullanılmış bir modül ise rafta saklanan canıyla dönecek.
- Müdahale pencereleri 60, 90 ve 120. adımlarda açılacak; savaş ve replay oynatımı
  durmayacak. Raf 60–89, 90–119 ve 120–savaş sonu aralıklarında, o aralıkta değişim
  yapılana kadar aktif kalacak. Savaş genelinde toplam iki değişim hakkı var ve her
  aralıkta en fazla bir değişim yapılabilir. Geçerli seçim rafı anında kilitler,
  sunucu değişimi sonraki tick sınırında uygular. Kullanılmayan hak sonraki aralığa
  taşınır; raftaki modül korunmuş canıyla geri çağrılabilir.
- Kariyer ve canlı savaş sunumu mevcut varsayılandan daha yavaş, sabit ve iki
  oyuncu arasında senkron bir taktik temposuna geçirilecek. Kesin hız katsayısı
  görsel kabul sırasında ayarlanacak; başlangıç adayı `0.65×`.
- Kariyer savaşının gerçek canlı sahnesi sonuç ekranına kadar kesintisiz sürer;
  savaş sonunda otomatik ikinci replay oynatılmaz. Replay yalnız maç geçmişinden
  kullanıcı isterse açılabilir.
- Hazırlık/kariyer/savaş kartlarının görsel doğruluk kaynağı ortak sunum
  bileşenleridir. Kablolar ve enerji parçacıkları görünür porttan görünür porta
  bağlanır; batarya akışı çift yönlü kalır.
- Hazırlık alanındaki yinelenen `6/6 modül enerjili` kartı, dikey kaydırma çubuğu,
  `KAPI`/`ÇEKİRDEK KAPISI` yazıları ve kırpılan alt sınırlar kaldırılacaktır.
  Bağlantı doğrulaması kısa süreli merkez bildirimi olarak gösterilecektir.
- Modüller ikon kutusu değildir. Her tür hacimli ve işlevi okunabilen fiziksel
  bir gövdeye sahip olur; saldırı görünür namlu/emitörden çıkar ve her savaş
  kaydının eş zamanlı görsel karşılığı bulunur.

## v0.8.23 kabul ölçütleri

- Canlı kariyer savaşı sonunda otomatik ikinci replay başlamaz.
- Raf 60/90/120. adım pencerelerinde savaşı durdurmadan açılır, geçerli bir
  değişiklikten sonra kilitlenir ve değişim sonraki sunucu tick'inde görünür.
- Hazırlık, kariyer ve savaş aynı kart/çekirdek/modül tasarım sistemini kullanır.
- Kablo ve enerji animasyonları gerçek porttan gerçek porta gider.
- Lazer/mermi görünür namludan çıkar; kalkan, hasar, onarım ve enerji olaylarının
  metin kaydıyla eş zamanlı görsel geri bildirimi vardır.
- Kısa ekran yüksekliğinde kart altı kırpılmaz ve istenmeyen kaydırma oluşmaz.
- Web ve Android testlerinde yeni giriş, ses, kare hızı veya yaşam döngüsü sorunu
  oluşmaz.

## Doğrulama

- `git rev-parse --show-toplevel`: `D:/Projects/project-relay`
- Python test paketi: Başarılı, 204 test ve 514 alt test geçti.
- Canlı kariyer API, kalıcı oturum, müdahale aralığı, süreç yeniden başlatma ve
  göç testleri: Başarılı, hedefli paket 45 test geçti.
- `flutter analyze`: Başarılı, sorun bulunmadı.
- `flutter test`: Başarılı, 92 test geçti.
- Son modül oturtma animasyonu sonrası canlı raf/devre hedefli testleri:
  Başarılı, 12 test geçti.
- Hedefli tekrar/oynatma ve dinamik `module_swap` testleri: Başarılı, 11 test
  geçti.
- İlk kullanım turu durum testleri: Başarılı, 2 test geçti.
- `git diff --check`: Başarılı; yalnız çalışma ağacının mevcut LF/CRLF dönüşüm
  uyarıları görüldü.

## Sıradaki işler

Kesin uygulama sırası aşağıdadır; sonraki oturum ilk tamamlanmamış maddeden devam
etmelidir:

1. **Tek canlı savaş akışı (P0):** Kariyer tamamlanınca otomatik replay'e geçişi
   kaldır; sonuç/analizi aynı canlı sahnede göster. Sunucu kesin sonucu ve replay
   kaydı korunacak.
2. **Canlı müdahale rafı kabulü (P0):** Mevcut 60/90/120 ve iki hak davranışını
   gerçek tarayıcıda doğrula; raf bir geçerli değişiklikten sonra kilitlenmeli,
   savaş durmamalı ve donanım sonraki tickte oturmalı.
3. **Savaş olayı-görsel senkronu (P0):** Ateş, kalkan, hasar, onarım ve enerji
   günlüklerini görünür olaylarla birebir eşle; boş ve açıklamasız beklemeyi azalt.
4. **Ortak sahne sunumu (P1):** Hazırlık, kariyer ve savaşın kart, çekirdek,
   perspektif, ışık ve fiziksel modül bileşenlerini tek doğruluk kaynağına bağla.
5. **Port/kablo doğruluğu (P1):** Tüm kablo ve enerji paketlerini gerçek portlar
   arasında üret; batarya çift yönünü ve döndürülmüş modülleri test et.
6. **Hazırlık ekranı temizliği (P1):** Yinelenen enerji kartını, scrollbar'ı ve
   kapı etiketlerini kaldır; doğrulamayı merkez toast yap; alt sınır kırpılmasını
   düzelt. Aynı kabulü kariyer hazırlığında uygula.
7. **Fiziksel modül gövdeleri (P2):** Sekiz modül türünü ikon kutusundan çıkar;
   işlevi silüet/mekanizma/port üzerinden okunan tutarlı donanıma dönüştür.
8. **Namlu ve darbe sistemi (P2):** Lazer ve darbe topu çıkışını fiziksel
   emitöre bağla; ateşleme durumu, hareket ve çarpma geri bildirimi ekle.
9. **Teknoloji prototipi (P2):** Bir jeneratör, lazer, kalkan, enerji akışı ve
   tek atışla Flutter/CustomPainter + Flame tabanını; gerekirse Rive ve
   `flutter_unity_widget` + Unity seçeneğini ölç. Görsel kalite, kare süresi,
   açılış, bellek, paket boyutu, web/Android uyumu ve bakım maliyetine göre en
   küçük yeterli yığını seç.
10. **Ses ve son kabul (P3):** Menü müziğini daha sakin seviyede ve daha az
    kasvetli içerikle doğrula; web ses kilidi, Android yaşam döngüsü, kısa ekran,
    sürükleme ve performans kabulünü tamamla.
11. Yukarıdakiler geçince sürüm numaralarını birlikte `v0.8.23` olarak güncelle,
    test raporunu yaz ve kullanıcı isterse commit/push kapsamını hazırla.

## Riskler ve engeller

- Gerçek `.env` dosyası yerelde bulunuyor; içeriği hiçbir belgeye veya commit'e
  alınmamalıdır.
- Yerel Flutter web sunucusu ve API açıldı ancak bu Codex oturumundaki uygulama
  içi tarayıcı bağlantısı `C:\Users\S-A\AppData` okuma izni nedeniyle kurulamadı. Gerçek
  tarayıcı görsel/işitsel kabulü hâlâ manuel olarak yapılmalıdır.
- Kariyer canlı oturumu HTTP tick çağrılarıyla ilerliyor; tarayıcı sekmesi arka
  plana alındığında timer kısıtlaması savaş temposunu yavaşlatabilir. Gerçek zamanlı
  PvP aşamasında tempo WebSocket üzerinden sunucu saatine bağlanmalıdır.
- `flutter_unity_widget`/Unity seçeneği gerçek 3D görünümü güçlendirebilir; ancak
  Flutter web uyumu, platform görünümü katmanlama, açılış/bellek/paket maliyeti ve
  iki ayrı asset/derleme hattı önemli risktir. Ölçümlü prototipten önce ana
  mimari kararı verilmemelidir.
- Hazırlık ve savaşın ortak bileşene taşınması görsel tutarlılığı artırırken
  widget testlerinin finder/scroll varsayımlarını bozabilir; geçiş küçük adımlarla
  ve hedefli regresyon testleriyle yapılmalıdır.
- Olay metni ile görsel efektin ayrı zaman kaynaklarından beslenmesi yeniden
  eşzamansızlık üretebilir; ikisi aynı replay/snapshot olayından türetilmelidir.

## Sonraki oturuma başlangıç istemi

> AGENTS.md, docs/CODEX_HANDOFF.md, git status ve son 10 commit'i incele. Mevcut
> kullanıcı değişikliklerini koruyarak sıradaki işten devam et.
