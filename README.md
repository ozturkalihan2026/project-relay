# Project Relay v0.8.21 rev4 — Battle Presentation 2.0

Bu sürüm v0.8.19 rev1 üzerine savaş ekranındaki gradient kaynaklı görünmezlik hatasını giderir; savaş geri bildirimini kalkan/yok oluş/enerji sönmesiyle güçlendirir; modül bağlantı yönlerini büyük ölçüde otomatikleştirir; oyun geneline açılır-kapanır sohbet sistemi ekler ve görev/başarım/sezon ödülü içeriklerini genişletir.

- Sunucu API: `0.8.21`
- Flutter istemci: `0.8.21+87`
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
