# Project Relay v0.6.2 — İstemci Mimarisi

## Katmanlar

| Katman | Dizin | Sorumluluk |
|---|---|---|
| API | `client/lib/src/api` | HTTP, hata, JWT yenileme ve güvenli oturum saklama |
| Modeller | `client/lib/src/models` | Oyuncu, oturum, modül, kart, maç ve replay verileri |
| Durum | `client/lib/src/state` | Riverpod kart düzenleme ve tekrar tercihi kuralları |
| Arayüz | `client/lib/src/screens`, `widgets` | Ana menü, kip seçimi, kart, el kitabı ve canlı olay akışı |
| Oyun | `client/lib/src/game` | Tick gruplama, olay yerelleştirme, ses ve Flame replay |

## Veri akışı

1. Riverpod misafir oturumu sağlayıcısı güvenli depodaki yenileme anahtarını
   okur; varsa döndürür, yoksa otomatik misafir oluşturur.
2. API katmanı kısa ömürlü erişim anahtarını yalnız bellekte tutar. Yetkili
   istek `401` alırsa yenileme anahtarını bir kez döndürür ve isteği yineler.
3. Riverpod katalog sağlayıcısı modül ve bot listesini FastAPI'den alır.
4. Ana menü Oyna, Kariyer, Koleksiyon, İstatistikler, Nasıl Oynanır ve
   Ayarlar ekranlarını ayırır.
   Oyun el kitabı modül kataloğunu bağımsız akışta yükler; Oyna ekranı
   çevrimiçi ve antrenman düzenleyici kiplerinden yalnız birini açar.
5. Koleksiyon sağlayıcısı aktif sekizli kiti, Devre Kredisini, sahip olunan
   kozmetikleri ve kuşanılanları sunucudan alır.
6. Kart denetleyicisi oyuncunun taslak yerleşimiyle birlikte aktif kit limitlerini
   tutar; palet her modül türünde kalan adedi gösterir.
6. İstemci yönlü portları, pasif çekirdeği ve dört çekirdek kapısını önizleme
   amacıyla çizer; kart dışına veya kapısız çekirdek kenarına bakan kullanılamaz
   port işaretlerini göstermez.
7. Doğrulama isteği sunucudan gerçek enerjili kimlikleri alır.
8. Asenkron eylem taslak kartı `PUT /me/board` ile kaydeder; ardından gövdesiz
   `POST /matches/async` çağrısıyla sunucu eşleştirmesini başlatır.
9. Bot antrenmanı eski kart ve bot kimliği isteğini ayrı ekranda korur.
10. Sunucu sonuç, replay adresi ve savaşta kullanılan iki kartı döndürür.
11. İstemci replay'i ayrıca alır ve checksum eşitliğini kontrol eder.
12. Replay yanıtındaki durum kareleri her adımın kesin can, ısı, bekleme,
   kalkan ve enerji durumunu taşır.
13. Flame, olayları tick gruplarına ayırıp iki 4×4 kart üzerinde sırayla
   görselleştirir; aynı olaylar Türkçe akışa ve modül türüne göre yerel ses
   eşlemesine gider.
14. Normal/antrenman/Asenkron PvP ve kariyer savaşları aynı replay motorunu
   kullanır; `CareerBattleScreen` yalnız kariyere özgü sonuç yönlendirmesini
   ayrı tutar.
15. Asenkron PvP ilerleme ödülü replay tamamlanınca `RelayNotice` ile ekran
   ortasında gösterilir; sayfa akışına ayrı ödül kartı eklenmez.

## Yerleşim ve sonuç sunumu

Geniş ekran düzeninde kart görünüm yüksekliğine göre 340–460 px arasında
uyarlanır. Çevrimiçi kipte asenkron PvP kartı ana eylemdir ve bot listesi
oluşturulmaz. Antrenman kipinde dokuz botun ayrı `ScrollController` kullanan
sabit yükseklikli listesi gösterilir ve PvP kartı oluşturulmaz. Seçili modülün
döndürme eylemi hücre üzerinde
gösterilir; dört portu yönsüz olan Bataryada döndürme eylemi gösterilmez.
Güçlendiricinin döndürme eylemi sol üstte, yön oku sağ üstte ayrı kalır.
Modül palete sürüklenerek kaldırılır. Her dolu hücre sunucunun modül
kataloğundan türetilen Can ve role özgü temel değer etiketlerini gösterir.
Çekirdek kapısı hücrelerinde ad, özellik rozetleri ve kapı etiketi ayrı dikey
alanlarda tutulur; uzun adlar hücreye sığacak biçimde ölçeklenir.
Doğrulama ve yerleşim sonucu kartın hemen altında saydam, renk kodlu ve
erişilebilir canlı bölge olarak sunulur.

Uygulama çubuğu sunucunun verdiği güvenli misafir adını gösterir. Yenileme
JWT'si `flutter_secure_storage` ile platformun güvenli anahtar/depolama
mekanizmasında tutulur; erişim JWT'si kalıcı depoya yazılmaz.

Sunucu sonucu savaş başından itibaren sabit yükseklikte görünür; replay
ilerlerken çekirdek canı, kalan modül, oynatılan hasar ve olay sayısını
günceller. Savaş tamamlanınca aynı alan sunucudaki `decision` yapısını altı
ölçütlü tabloya dönüştürür.
İstemci yalnız sunucunun `criterion` değerini vurgular. Savaş durum kareleri
modül Can ve Isı değişimlerinin önceki kareye göre `+ / −` gösterilmesini
sağlar. Sıfır bekleme `Hazır`, pozitif bekleme `Doluyor: N` biçiminde yazılır.
Olay listesi kalan yüksekliği esnek biçimde kullanır. Duraklatma, yeniden
oynatma, ses ve hız kontrolleri sonuç alanının altında
gruplanır. Normal ve antrenman akışında **Yeni Oyun** aynı grubun ikinci
satırında ortalanır. Kariyer savaşında aynı alan sonuç kesinleşene kadar
pasif kalır; ardından koşu durumuna göre **Sonraki Savaş**, **Boss
Hazırlığına Geç**, **Koşuyu Tamamla** veya **Kariyer Sonucuna Dön** olur.
Ana menüdeki Ayarlar, yeni tekrarın başlangıç sesi ve hızını Riverpod
durumunda tutar; tekrar içindeki Ses/Hız kontrolleri aynı tercihi günceller.

## Güven sınırı

Flutter istemcisi değiştirilebilir ve bu nedenle güvenilir değildir. Port çizimi,
seçim durumu ve animasyon yalnızca sunumdur. Aşağıdaki alanların otoritesi
FastAPI ve deterministik Python motorudur:

- oyuncu kimliği ve oturum geçerliliği,
- geçerli sunucu kartı,
- rakip havuzu, kendiyle eşleşmeme ve tekrar rakip sınırı,
- geçerli kart kuralı,
- merkezî çekirdek ve jeneratör kapısı kuralı,
- enerjili modüller,
- maç tohumu,
- rakip düzeni,
- hasar ve iyileştirme,
- modüller → Jeneratör → çekirdek hedef sırası,
- kazanan ve eşitlik bozma,
- replay olayları ve checksum.


## v0.6.2 koleksiyon akışı

Koleksiyon ekranı `collectionProvider` ile tek sunucu anlık görüntüsü kullanır.
Kit kaydı ve kozmetik eylemlerinden sonra koleksiyon ile ilerleme sağlayıcıları
yenilenir. Editör açılırken aktif kit yüklenir; çevrimiçi, kariyer ve antrenman
paletleri aynı kalan-adet kuralına bağlanır. Sunucuya kaydedilen kartlar istemci
kısıtından bağımsız olarak aktif kit karşısında tekrar denetlenir.
