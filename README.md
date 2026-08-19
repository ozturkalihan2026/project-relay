# Project Relay v0.8.23 — Battle Presentation

Bu sürüm v0.8.22 üzerine savaş ekranını tek canlı sahneye taşır, fiziksel devre görünümlü modül donanımını ekler, namlu/ateşleme geri tepmesi ve çarpma partikülü efektlerini güçlendirir; ses ve yaşam döngüsü iyileştirmelerini içerir.

- Sunucu API: `0.8.23`
- Flutter istemci: `0.8.23+91`
- Savaş kuralları: `0.8`
- Alembic başı: `20260808_0012`

## v0.8.20 öne çıkanlar

- Savaş sahnesinde `ui.Gradient.linear` renk durağı hatası düzeltildi; devre kartları ve modüller yeniden görünür.
- Yok edilen modüller kırmızı X yerine patlama/enerji sönmesi geri bildirimi kullanır.
- Kalkan enerji emişi sahne üzerinde ayrı kalkan animasyonuyla gösterilir.
- Tek portlu modüller yerleştirildiğinde bağlantı yönü otomatik seçilir; yalnız Güçlendirici etki yönü manuel döndürülür.
- Sol altta açılır-kapanır sohbet: tüm sunucu, klan, arkadaş özel sohbeti ve 2–12 kişilik grup sohbetleri.
- Klan ekranından klan sohbetine, arkadaş profilinden doğrudan özel mesaja geçiş.
- Günlük görevler 10, başarımlar 28, sezon ödül yolu 20 kademeye genişletildi.
- Profilde günlük görev, başarım ve sezon ödülü listeleri sabit yükseklikte scrollbar alanlarına taşındı.
- Profil/Klan/İstatistik/Mağaza alt menüleri ortak yeni segmented-button tasarımını kullanır.
- Oyna ekranındaki devre kartı kompozisyonu bütün ekranı kaplayan düşük opaklıklı bir arka plan haline getirildi.
