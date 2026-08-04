# Project Relay — Özellik Havuzu

Bu belge, bağlayıcı sürüm yol haritasının önüne geçirilmeyecek fakat ileride
ürün tasarımı sırasında yeniden değerlendirilecek fikirleri saklar. Buradaki
maddeler uygulanmış özellik veya yakın sürüm taahhüdü değildir.

## Komutan Sistemi

**Durum:** Özellik havuzunda — uygulanmadı.

Oyuncu devreyi kurduktan ve doğruladıktan sonra, savaşı başlatmadan önce bir
komutan seçer. Komutan seçimi mevcut kartı değiştirmez; ayrı modül eklemez ve
kalıcı hesap gücü üretmez.

Bağlayıcı tasarım sınırları:

- Komutan; modül Can, Hasar, Enerji, Isı, Kalkan veya Onarım değerlerine kalıcı
  ham artış vermez.
- Dereceli PvP'de satın alınabilir güç veya seviye avantajı oluşturmaz.
- Etki, mümkünse sayısal çarpan yerine davranış ve karar sırasını değiştirir.
- Enerji dağıtım önceliği, hedef seçimi, savunma zamanlaması veya ısı risk
  toleransı gibi davranış alanları değerlendirilebilir.
- Seçim sunucu yetkili maç isteğine eklenir ve replay kaydında görünür.
- Komutan seçimi, devre kurma ve doğrulama tamamlanmadan açılamaz.
- Rakip seçilen komutanı savaş öncesi görebilir; gizli güç uygulanmaz.

İlk rol fikirleri:

- Mühendis
- Saldırı Uzmanı
- Savunmacı
- Enerji Uzmanı
- Risk Uzmanı
- Denge Uzmanı

Bu roller nihai katalog değildir. Denge ve kapalı alfa verisi görülmeden savaş
motoruna alınmayacaktır.

## Oyuncu Tarzı Profili

**Durum:** Özellik havuzunda — uygulanmadı.

Sunucu, oyuncunun belirli bir maç dönemindeki modül tercihlerini ve devre
alışkanlıklarını analiz ederek kozmetik bir oyun tarzı unvanı üretebilir.
Örnekler:

- Enerji Mühendisi
- Savunma Uzmanı
- Risk Ustası
- Onarım Mimarı
- Hücum Tasarımcısı

Tasarım sınırları:

- Unvan hiçbir savaş avantajı sağlamaz.
- Profilde, arkadaş görünümünde ve klan üye listesinde gösterilebilir.
- Oyuncuya hangi verilerden türetildiği açıklanır.
- Oyuncu unvanı gizleyebilir veya son sezon unvanı ile genel unvan arasında
  seçim yapabilir.
- Tek maçtan değil, yeterli örnek büyüklüğünden sonra hesaplanır.
- Komutan seçimi gelirse seçilen komutan ile gerçek oynama tarzı ayrı tutulur.

## Değerlendirme kapısı

Komutan Sistemi ve Oyuncu Tarzı Profili; v0.8.3 ana merkez ve menü düzenlemesi,
v0.9.0 kapalı alfa ölçümü ve mevcut sekiz modüllü meta çeşitliliği doğrulandıktan
sonra yeniden ele alınacaktır.


## v0.8.3 koruma notu

Ana merkez ve profil düzenlenirken Komutan seçimi için görünür seçim ekranı,
savaş isteği alanı veya sahte oyuncu tarzı unvanı eklenmedi. Komutan seçimi,
ileride devre kurulup sunucuda doğrulandıktan sonra savaş öncesi ayrı adım
olarak değerlendirilecektir.
