# Project Relay — Bağlayıcı Ürün Hedefi

Bu belge projenin hedef sonucunu korur. Sürüm planları bu kararlara göre
hazırlanır; kısa vadeli kolaylık için oyun fikri değiştirilmez.

## Oyun fikri

Project Relay şimdilik proje kod adıdır; ticari ad değildir.

Oyuncu sınırlı sürede küçük bir 4×4 devre kartına modüller yerleştirerek savaş
makinesi kurar. Sistem oyuncuyu gerçek bir rakibin kaydedilmiş düzeniyle
eşleştirir. İki makine sunucuda otomatik savaşır; istemci sonucu animasyonlu
tekrar olarak oynatır.

Hedef tur süresi 2–3 dakikadır.

## Temel döngü

1. Oyuncuya koşuya bağlı rastgele modüller sunulur.
2. Modüller 4×4 devre kartına yerleştirilir.
3. Enerji, ısı, yön, bağlantı ve komşuluk etkileşimleri hesaplanır.
4. Sunucu benzer düzeyde gerçek bir oyuncunun kayıtlı düzenini seçer.
5. Savaş deterministik biçimde sunucuda hesaplanır.
6. İstemci sunucunun olay akışını animasyonlu tekrar olarak oynatır.
7. Oyuncu puan ve kozmetik para kazanır.
8. Yeni düzen kurarak lige devam eder.

Oyuncunun telefonu hasar, puan veya kazanan bildiremez.

## Oyunu farklılaştıran çekirdek

- Devre üzerinden gerçek yönlü enerji akışı
- Isınma ve soğutma dengesi
- Modüllerin yönü ve bağlantı noktaları
- Savaş sırasında zincirleme aktivasyon
- Elektronik/robotik görsel kimlik
- Az dil bağımlılığı ve küresel oynanış
- Sürekli gerçek zamanlı oda gerektirmeyen asenkron rekabet

## Sekiz başlangıç modülü

| Modül | Görev |
|---|---|
| Jeneratör | Devreye enerji sağlar |
| Batarya | Enerjiyi dört yöne dağıtır ve fazlasını depolar |
| Lazer | Düzenli hasar verir |
| Darbe Topu | Yavaş ve yüksek hasar verir |
| Kalkan | Gelen hasarı emer |
| Soğutucu | Isınmayı azaltır |
| Güçlendirici | Enerjiyi dört yöne taşır; ok yönündeki komşuyu güçlendirir |
| Onarım | Hasarlı modülü iyileştirir |

Oyunun ilk adalet kuralı şudur: en pahalı veya en yüksek seviyeli parçaya sahip
olmak değil, doğru yerleşim ve karşı strateji kazanmalıdır.

## İlerleme ve adalet

- Her oyuncu aynı sekiz temel modülle başlar.
- Hesap seviyesi modüllerin kalıcı ham gücünü artırmaz.
- Sonradan açılan modüller doğrudan daha güçlü değil, farklı strateji sunan yan
  seçeneklerdir.
- Oyuncu açtığı modüllerden kontrollü bir sekizli kit hazırlar.
- Yükseltmeler yalnızca mevcut koşuda geçerlidir ve yeni koşuda sıfırlanır.
- Örnek koşu hedefi 5 galibiyet veya 3 yenilgidir.
- Aynı modüllerin aynı düzenle savaşması gerçek beraberlikle bitebilir.
- Dereceli maçta bütün oyuncular aynı güç kurallarına tabidir.

Kalıcı hesap ilerlemesi içerik ve prestij açar:

- yeni yan seçenek modül planları,
- alternatif kart şekilleri ve çekirdek yazılımları,
- renkler, efektler, kasalar ve rozetler,
- yeni oyun modları ve sezon katılımı.

## Maç hesabı

Sonuç toplam güç puanı karşılaştırılarak bulunmaz. Sunucu her tick içinde enerji
üretimi, enerji aktarımı, batarya rezervi, saldırı, kalkan, ısı, aşırı ısınma,
soğutma, onarım, modül hasarı ve çekirdek hasarını çalıştırır.

Süre sonunda iki çekirdek de ayaktaysa sıralama:

1. kalan çekirdek sağlık yüzdesi,
2. hayatta kalan modül sayısı,
3. verilen toplam hasar,
4. enerji verimliliği,
5. ortalama ısı.

Bütün değerler eşitse gerçek beraberlik verilir.

## İlk çevrimiçi ürün

- misafir hesap,
- otomatik oluşturulan güvenli oyuncu adı,
- dereceli asenkron karşılaşma,
- ELO benzeri puan,
- haftalık lig,
- maç geçmişi ve savaş tekrarları,
- rakip yoksa sunucu botu.

İlk sürümde sohbet ve serbest oyuncu adı yoktur.

## Gelir ilkeleri

İlk alfa sürümünde para kazanma etkin değildir. Başarı hâlinde ödüllü reklam,
tek seferlik reklam kaldırma, kart/kasa temaları, efektler, profil rozetleri ve
kozmetik sezon bileti değerlendirilebilir.

İstatistik sağlayan modüller parayla satılmaz. Gerçek para ödülü, bahis,
kripto, NFT ve ücretli rastgele ganimet kutusu bulunmaz.

## Teknoloji yönü

İstemci: Flutter, Flame ve Riverpod; Android ve web öncelikli, Windows ve iOS
sonraki hedeflerdir.

Sunucu: Python, FastAPI, PostgreSQL, SQLAlchemy, Alembic, JWT ve Docker.
Redis yalnızca ölçülmüş ihtiyaç oluşursa eklenir.
