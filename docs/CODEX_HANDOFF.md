# Codex Çalışma Devri

Bu belge, Project Relay üzerinde iş ve ev bilgisayarları arasında güvenli şekilde
devam etmek için tutulan kısa ve kalıcı bağlamdır. Tam sohbet dökümü değildir.

## Depo durumu

- Son güncelleme: 2026-08-14 (Europe/Istanbul)
- Depo: `https://github.com/ozturkalihan2026/project-relay.git`
- Aktif dal: `main` (`origin/main` takip ediliyor)
- Son doğrulanmış commit: `1bc2805` — `a comprehensive visual overhaul of the project`
- Senkronizasyon: Belge oluşturulurken yerel `main` ile `origin/main` aynı
  commit'i gösteriyordu.

## Aktif amaç

Kullanıcının `Öneri Düzenleme.docx` belgesinde onayladığı arayüz, ses ve savaş
mekaniği iyileştirmelerini aşamalı olarak uygulamak. Görsel paket ile asenkron
aşırı yük tamamlandı; 60/90/120 müdahale pencerelerinin kural ve can-rafı çekirdeği
hazır. Sıradaki geliştirme, bu çekirdeği kariyer için kalıcı durdur/sürdür savaş
oturumuna ve daha sonra canlı WebSocket eşleştirmesine bağlamaktır.

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

## Mevcut kullanıcı çalışması

- `client/pubspec.lock` çalışma öncesinde değiştirilmiş görünüyordu; anlamlı diff
  göstermeyen bu dosya kullanıcıya ait kabul edilmeli ve korunmalıdır.
- Mevcut öneri paketi değişiklikleri henüz commit edilmedi. `AGENTS.md` ve bu devir
  dosyası da henüz takip edilmeyen dosyalardır.

## Alınan kararlar

- Kod ve belgeler için tek doğruluk kaynağı GitHub'dır.
- Kalıcı proje kuralları `AGENTS.md` içinde tutulur.
- Oturumlar arası kısa teknik bağlam bu dosyada tutulur.
- Gizli bilgiler ve tam sohbet geçmişi depoya yazılmaz.
- Rive entegrasyonu şimdilik yapılmayacak; yeniden gündeme gelirse bağımlılık,
  kaynak kodu, asset kaydı ve testleri ayrı bir çalışma olarak ele alınacak.
- Canlı savaş ekranı toplam tur/adım süresini göstermeyecek; ayrıntılı teknik adım
  bilgisi yalnız savaş sonu analizinde bulunabilir.
- Savaş analizi ayrı bir düğme veya alt panel açmadan, savaş tamamlandığında iki
  devre arasındaki merkez alanda gösterilecek.
- Bilgisayar değiştirmeden önce test, devir güncellemesi, commit ve push;
  diğer bilgisayarda işe başlamadan önce `git pull --ff-only` yapılır.
- Yeni savaş modu yönü: mevcut asenkron eşleştirme 90. adımdan sonra kademeli
  aşırı yük kullanacak. Kariyer ve kurulacak canlı oyuncu eşleştirmesi ise 60.
  adımdan itibaren toplam iki modül değişimiyle sınırlı müdahale hakkı verecek.
  Rafa alınan modül mevcut canını koruyacak; ilk kez giren yedek tam canla,
  daha önce kullanılmış bir modül ise rafta saklanan canıyla dönecek.
- Müdahale pencereleri 60, 90 ve 120. adımlarda açılacak. Savaş genelinde toplam
  iki değişim hakkı var; her pencerede en fazla bir değişim yapılabilir ve
  kullanılmayan hak sonraki pencereye taşınır. Böylece raftaki bir modül sonraki
  pencerede korunmuş canıyla geri çağrılabilir. Canlı eşleştirmede seçimler iki
  oyuncuya aynı anda açılıp gizli kilitlenecek.
- Kariyer ve canlı savaş sunumu mevcut varsayılandan daha yavaş, sabit ve iki
  oyuncu arasında senkron bir taktik temposuna geçirilecek. Kesin hız katsayısı
  görsel kabul sırasında ayarlanacak; başlangıç adayı `0.65×`.

## Doğrulama

- `git rev-parse --show-toplevel`: `D:/Projects/project-relay`
- Python test paketi: Başarılı, 196 test geçti.
- `flutter analyze`: Başarılı, sorun bulunmadı.
- `flutter test`: Başarılı, 87 test geçti.
- Hedefli tekrar/oynatma ve seviye kutlaması testleri: Başarılı, 11 test geçti.
- İlk kullanım turu durum testleri: Başarılı, 2 test geçti.
- `git diff --check`: Başarılı; yalnız çalışma ağacının mevcut LF/CRLF dönüşüm
  uyarıları görüldü.

## Sıradaki işler

1. Motoru belirli bir adımda durdurup durum görüntüsü üretebilen, doğrulanmış
   değişim kararından sonra aynı durumdan deterministik devam edebilen oturum
   modeline dönüştür.
2. Bu oturumu önce kariyer savaşında 60/90/120 müdahale ekranına bağla; ardından
   aynı gizli kilit/senkron çözüm protokolünü WebSocket canlı eşleştirmeye uygula.
3. Paketi gerçek tarayıcı boyutlarında görsel ve işitsel olarak doğrula; özellikle
   kısa ekran yüksekliği, kariyer çift-devre alanı, merkez analiz, havai fişek,
   aşırı yük uyarısı ve web ses kilidini kontrol et.
4. Kullanıcı istediğinde mevcut değişiklikleri kontrollü biçimde commit edip
   GitHub'a gönder.

## Riskler ve engeller

- Gerçek `.env` dosyası yerelde bulunuyor; içeriği hiçbir belgeye veya commit'e
  alınmamalıdır.
- Yerel Flutter web sunucusu açıldı ancak bu Codex oturumundaki tarayıcı
  bağlantısı `C:\Users\SERVER\AppData` okuma izni nedeniyle kurulamadı. Gerçek
  tarayıcı görsel/işitsel kabulü hâlâ manuel olarak yapılmalıdır.

## Sonraki oturuma başlangıç istemi

> AGENTS.md, docs/CODEX_HANDOFF.md, git status ve son 10 commit'i incele. Mevcut
> kullanıcı değişikliklerini koruyarak sıradaki işten devam et.
