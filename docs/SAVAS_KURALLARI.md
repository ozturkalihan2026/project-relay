# Project Relay — Savaş Kuralları v0.7

## 1. Kart ve bağlantı

Her oyuncunun 4×4 kartının ortasındaki 2×2 alan pasif çekirdektir. Çevredeki
12 hücreye en fazla 6 modül ve tam olarak bir jeneratör yerleştirilir. Bir
modülün enerji alabilmesi için jeneratöre kesintisiz biçimde bağlanması
gerekir.

- Çekirdeğe yalnız kuzey, doğu, güney ve batıdaki dört simetrik kapı hücresi
  bağlanır.
- Jeneratör yalnız bu kapılardan birine, ön yönü çekirdeğe bakacak biçimde
  yerleşir; döndürülemez.
- Jeneratörün üç portu vardır: ön port çekirdeği, iki yan port halkanın iki
  yönünü besler.
- Çekirdek enerji üretmez ve depolamaz. Jeneratörden enerji alırsa onu diğer
  üç kapıya ileten dört portlu pasif omurga gibi davranır.
- Batarya dört yönlü kavşaktır; enerjiyi döndürebilir ve birden fazla kola
  dağıtabilir.
- Güçlendirici arka ve ön bağlantılarıyla enerjiyi düz hatta iletir.
- Diğer başlangıç modülleri yalnızca arka bağlantılarından enerji alır.
- Modülün oku ön tarafını gösterir. Örneğin jeneratörün sağındaki doğuya bakan
  Lazerin arka bağlantısı batıya, yani jeneratöre bakar.
- Bağlantısı kesilen modül kartta kalır ama enerji kullanamaz.
- Yedinci modül hem istemci hem sunucu tarafından reddedilir. Bu sınır,
  ücretsiz modül çoğaltmanın tek başına üstünlük kurmasını engeller.

Jeneratör iki yan uç ile çekirdeğin açtığı diğer üç kapıyı aynı anda
besleyebildiği için geçerli bir altı modüllük düzen bataryasız beş paralel uç
kurabilir. Merkezî çekirdek bu nedenle kartı tek seri halkaya zorlamaz.

## 2. Eşit başlangıç ve ilerleme

Her yeni hesap aynı sekiz temel modülle başlar. Hesap ilerlemesi dereceli
maçlarda kalıcı ham güç vermez.

- Uzun vadeli ilerleme: yeni yan seçenekler, yeni stratejiler ve kozmetikler.
- Koşu içi ilerleme: modülü geçici olarak Seviye 1’den 2 veya 3’e yükseltme.
- Koşu bittiğinde geçici seviyeler sıfırlanır.
- Ücretli içerik dereceli maçta saldırı, can veya enerji üstünlüğü sağlamaz.

Bu yapı hem yeni oyuncunun rekabet edebilmesini hem de deneyimli oyuncunun
daha fazla stratejik seçeneğe sahip olmasını amaçlar.

## 3. Savaş adımı

Motor her adımda şu sırayı izler:

1. Canlı modüllerin bekleme ve ısı değerlerini günceller.
2. Jeneratörden başlayarak bağlı devreyi yeniden hesaplar.
3. Enerjiyi en uzun süredir enerji alamayan hazır modülden başlayarak
   deterministik sırayla dağıtır.
4. Her iki oyuncunun eylemlerini mevcut durumdan planlar.
5. Yararlı hedefi bulunan Kalkan, soğutma ve onarım eylemlerini uygular.
6. İki tarafın önceden planlanmış saldırılarını uygular.

Bir modül aynı adımda yok edilse bile önceden planladığı eylemi tamamlar.
Böylece işlemlerin teknik sırası oyunculardan birine gizli avantaj sağlamaz.

## 4. Enerji ve batarya

- Jeneratör her adım 8 yeni enerji üretir.
- Modüller yalnızca eylem yaptığında enerji harcar.
- Aynı adımda enerji yetmezse çalışamayan hazır modül bekleme puanı kazanır
  ve sonraki adımda diğer hazır modüllerden önce değerlendirilir.
- Eşit bekleme puanında hücre ve modül kimliği kararlı sırayı belirler.
- Kullanılmayan enerji, bağlı ve canlı Bataryaların kapasitesine kadar saklanır.
- Batarya yok edilirse kullanılabilir rezerv yeni kapasiteye indirilir.
- Dolu Kalkan, düşürülecek ısı bulamayan Soğutucu ve onarılacak canlı hedef
  bulamayan Onarım enerji harcamaz veya beklemeye girmez.
- Aynı modülün kesintisiz enerji yetersizliği tek olay günlüğü uyarısıdır.
  Modül yeniden eylem yaptıktan sonra başlayan yeni kesinti tekrar bildirilir.

İleride kart düzenleyicisinde enerji önceliği ayrıca gösterilecektir.

## 5. Isı

- Her eylem ısı üretir.
- Modüller her adım pasif olarak bir miktar soğur.
- Isı 100’e ulaştığında modül aşırı ısınır ve eylem yapamaz.
- Isı 55’e düştüğünde yeniden çalışır.
- Soğutucu, bağlı devredeki bütün canlı modüllerin ısısını düşürür.
- Güçlendirici etkiyi artırırken üretilen ısıyı da yükseltir.

## 6. Güçlendirici

Güçlendirici yalnızca önündeki, kendisine doğru bağlanmış modülü etkiler.
Temel sürümde etkiyi 1,35 katına, eylem ısısını 1,25 katına çıkarır.
Birden fazla etki için üst sınır vardır; sonsuz çarpan kurulamaz.

## 7. Hedef seçimi

Saldırı hedefleri üç kesin aşamada seçilir:

1. Jeneratör dışındaki en yüksek tehdit sınıfındaki canlı modüller
2. Diğer bütün modüller imha edildikten sonra Jeneratör
3. Jeneratör de imha edildikten sonra çekirdek

Bu nedenle yaşayan başka bir modül varken Jeneratör, yaşayan Jeneratör varken
çekirdek hedef alınamaz. Aynı tehditte birden fazla hedef varsa maç tohumu ve
kart konumu deterministik seçimi belirler. Aynı adımda daha önce seçilmiş hedef
imha edilirse yedek hedef de aynı üç aşamalı sırayla belirlenir.

Kalkanın tehdit değeri saldırı modüllerinden yüksektir. Yaşayan Kalkanlar bu
nedenle silahlardan önce hedef çekerek savunma dizilimlerine hazırlık süresi
kazandırır.

Aynı kartlar, aynı tohumla birbirine karşı oynadığında iki taraf da aynı hedef
kararlarını verir.

## 8. Galibiyet ve beraberlik

Çekirdeği sıfıra düşen taraf kaybeder. İki çekirdek aynı adımda yok olursa
maç berabere biter.

Azami savaş süresine ulaşıldığında şu sıra kullanılır:

1. Çekirdek can oranı
2. Hayatta kalan modül sayısı
3. Toplam modül can oranı
4. Verilen toplam hasar
5. Harcanan enerji başına hasar
6. Daha düşük toplam ısı

Tüm değerler eşitse sonuç gerçek beraberliktir ve dereceli puan değişmez.

Normal bot savaşında iki taraf eşit sayıda modülle başlar. Sunucu, seçilen
rakibin oyuncu kartındaki modül sayısına karşılık gelen 1–6 modüllük
varyantını seçer ve eşitliği simülasyondan önce doğrular. Böylece hayatta kalan
modül ölçütü başlangıçtaki farklı kart büyüklüklerinden etkilenmez.

## 9. Sunucu yetkisi

İstemci kart dizilimini sunucuya gönderir; savaşın sonucunu istemci belirlemez.
Sunucu:

1. kartları ve eşit modül sayısını doğrular,
2. sabit oyun kuralı sürümü ve tohumla savaşı çalıştırır,
3. sonucu ve olay kaydının özetini saklar,
4. istemciye canlandırılacak olay listesini gönderir.

Bu model çevrimdışı hesaplanmış sahte galibiyetleri ve değiştirilmiş istemci
değerlerini önemli ölçüde sınırlar.

## 10. Denge karşılıkları

Darbe Topu 8 enerji harcar, 16 hasar verir ve 30 ısı üretir. Jeneratör 8 enerji
ürettiği için tek Darbe Topu Bataryasız çalışabilir; çoklu yaylımın aynı
zamanda ateşlenmesi hâlâ Batarya rezervi gerektirir. Kalkan 5 enerjiyle 14
koruma üretir ve saldırı modüllerinden önce hedef çeker.
Sunucu rakip havuzunda saldırı ve savunma arasında tek yönlü bir üstünlük
yerine karşılık zinciri korunur:

- Darbe Topu yaylımı, çoklu Lazer baskısını yüksek ön hasarla karşılar.
- Kalkan duvarı, Darbe Topu yaylımını enerji verimli savunmayla karşılar.
- Çoklu Lazer baskısı, Kalkan duvarının yavaş hücumunu sürekli ateşle karşılar.
- Üç Kalkanlı Siper, dört Darbe Topulu yığın stratejisini karşılar.

Bu ilişkiler 21 farklı tohumda, kartlar iki tarafta da oynatılarak otomatik
denge testine alınır. Dokuz tam rakibin 36 ikili eşleşmesindeki 1.512 savaşta
her düzen için onu çoğunlukla yenen en az bir karşı düzen bulunmalıdır.
