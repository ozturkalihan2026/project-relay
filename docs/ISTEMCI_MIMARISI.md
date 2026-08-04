# Project Relay v0.8.4 — İstemci Mimarisi

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
4. Ana merkez Oyna, Klan, Koleksiyon, Mağaza ve Profil alanlarını ayırır.
   Ayarlar ile Nasıl Oynanır üst çubuk simgelerinden açılır. Oyna ekranı
   Çevrimiçi Savaş, Kariyer ve Antrenman kiplerini birlikte sunar. Profil;
   derece, sezon, geçmiş, günlük görev ve başarımların birleşik girişidir.
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


## v0.7.0 koleksiyon akışı

Koleksiyon ekranı `collectionProvider` ile tek sunucu anlık görüntüsü kullanır.
Kit kaydı ve kozmetik eylemlerinden sonra koleksiyon ile ilerleme sağlayıcıları
yenilenir. Editör açılırken aktif kit yüklenir; çevrimiçi, kariyer ve antrenman
paletleri aynı kalan-adet kuralına bağlanır. Sunucuya kaydedilen kartlar istemci
kısıtından bağımsız olarak aktif kit karşısında tekrar denetlenir.


## v0.8.0 sosyal ve klan akışı

- `socialProvider`, oyuncunun sosyal profilini, isteklerini, arkadaşlarını ve mevcut klanını yükler.
- `clanDirectoryProvider`, açık klanları ayrı ve yenilenebilir bir akışta getirir.
- `SocialScreen`, profil düzenleme, oyuncu arama, arkadaşlık ve klan işlemlerini ortak merkez bildirimleriyle yürütür.
- Bütün üyelik ve ilişki kuralları FastAPI tarafından yeniden doğrulanır.


## v0.8.1 Flutter kabul hotfix'i

Ana menü widget testi, her gezinme eyleminden önce hedef düğmenin gerçekten
var olduğunu doğrular. Görünür alanın dışında kalabilen **Oyna** düğmesi
`ensureVisible` ile kaydırılır, yerleşim tamamlandıktan sonra tıklanır. Oyna
sayfasındaki geri düğmesi de aynı biçimde doğrulanır. Bu değişiklik yalnız test
kararlılığına yöneliktir; uygulamanın gezinme davranışını değiştirmez.


## v0.8.2 sosyal arayüz düzeni

`SocialScreen`, tek uzun akış yerine Profil, Arkadaşlar ve Klan olmak üzere üç
seçilebilir çalışma alanı kullanır. `socialProvider` profil, gelen/giden istek,
arkadaş ve mevcut klanı tek snapshot olarak yükler. `clanDirectoryProvider` yalnız
oyuncu klansızken açık klan keşfini besler.

Yıkıcı sosyal işlemler API çağrısından önce onay ister. Herkese açık profil ve
klan girişleri temel istemci doğrulamasından geçer. Sosyal güvenlik kartı,
raporlama/engelleme uçları henüz bulunmadığını açıkça belirtir ve mevcut kapalı
alfa geri bildirim ekranına yönlendirir. Bu istemci katmanı tam moderasyon veya
sunucu yetkili içerik filtresi yerine geçmez.


## v0.8.3 ana merkez ve profil düzeni

`MainMenuScreen`, uzun dikey özellik listesini beş ürün alanında toplar.
`PlayerStatusBar`, ana merkezde profile dokunma eylemi ve alınabilir görev/
başarım ödülü için bildirim noktası taşır. Bildirim yalnız sunucunun
`progressionProvider` snapshot'ından türetilir.

`ProfileScreen`; genel sosyal kimlik, derece/sezon, maç geçmişi, günlük görevler
ve başarımları tek seçilebilir akışta sunar. Ödül alma ve replay açma işlemleri
mevcut sunucu yetkili API'leri kullanır.

`CollectionScreenMode`, sahip olunan Kit/Kozmetik görünümü ile satın alınmamış
ürünleri gösteren Mağazayı ayırır. Aynı `collectionProvider` ve satın alma/
kuşanma uçları kullanılır; savaş gücü üreten yeni ekonomi eklenmez.

`SocialScreen`, ana merkezdeki Klan girişini doğrudan sade klan alanına açar. Mevcut klan verisi özet, üyeler, katılım
tarihlerinden türetilen etkinlik ve ayrılma ayarları olarak düzenlenir.


## v0.8.4 profil, klan ve kariyer hazırlığı

`ProfileScreen`, Genel'in ardından ayrı Arkadaşlar sekmesi kullanır. Genel,
`SocialScreen(embeddedProfileOnly: true)` ile yalnız sosyal kimliği; Arkadaşlar
ise `embeddedFriendsOnly: true` ile istek, liste ve aramayı gömer. Bağımsız
`SocialScreen` yalnız klan işlevlerini gösterir.

`AppHeaderActions`, `PlayerStatusBar` profil eylemini ve Ayarlar/Nasıl Oynanır
adlandırılmış rotalarını ortaklaştırır. Replay gibi AppBar kullanmayan ekranlar
aynı bileşeni içerik başında gösterir.

`CareerScreen`, `boardControllerProvider`, `ModulePalette` ve `CircuitBoard`
ile kariyer devresini kendi içinde düzenler. Aktif koşunun rakip devresi aynı
çalışma alanında gösterilir. Koşu başlatma ve her savaş eylemi önce güncel
kartı doğrular ve `/api/v1/me/career-board` üzerinden kaydeder; ardından mevcut
kariyer uçlarını kullanır.
