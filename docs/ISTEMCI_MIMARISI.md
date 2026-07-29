# Project Relay v0.4.2 — İstemci Mimarisi

## Katmanlar

| Katman | Dizin | Sorumluluk |
|---|---|---|
| API | `client/lib/src/api` | HTTP, hata, JWT yenileme ve güvenli oturum saklama |
| Modeller | `client/lib/src/models` | Oyuncu, oturum, modül, kart, maç ve replay verileri |
| Durum | `client/lib/src/state` | Riverpod kart düzenleme kuralları |
| Arayüz | `client/lib/src/screens`, `widgets` | Kart, el kitabı, bot ve canlı olay akışı |
| Oyun | `client/lib/src/game` | Tick gruplama, olay yerelleştirme, ses ve Flame replay |

## Veri akışı

1. Riverpod misafir oturumu sağlayıcısı güvenli depodaki yenileme anahtarını
   okur; varsa döndürür, yoksa otomatik misafir oluşturur.
2. API katmanı kısa ömürlü erişim anahtarını yalnız bellekte tutar. Yetkili
   istek `401` alırsa yenileme anahtarını bir kez döndürür ve isteği yineler.
3. Riverpod katalog sağlayıcısı modül ve bot listesini FastAPI'den alır.
4. Kart denetleyicisi yalnızca oyuncunun taslak yerleşimini tutar.
5. İstemci yönlü portları, pasif çekirdeği ve dört çekirdek kapısını önizleme
   amacıyla çizer.
6. Doğrulama isteği sunucudan gerçek enerjili kimlikleri alır.
7. Asenkron eylem taslak kartı `PUT /me/board` ile kaydeder; ardından gövdesiz
   `POST /matches/async` çağrısıyla sunucu eşleştirmesini başlatır.
8. Bot antrenmanı eski kart ve bot kimliği isteğini ayrı akışta korur.
9. Sunucu sonuç, replay adresi ve savaşta kullanılan iki kartı döndürür.
10. İstemci replay'i ayrıca alır ve checksum eşitliğini kontrol eder.
11. Replay yanıtındaki durum kareleri her adımın kesin can, ısı, bekleme,
   kalkan ve enerji durumunu taşır.
12. Flame, olayları tick gruplarına ayırıp iki 4×4 kart üzerinde sırayla
   görselleştirir; aynı olaylar Türkçe akışa ve modül türüne göre yerel ses
   eşlemesine gider.

## Yerleşim ve sonuç sunumu

Geniş ekran düzeninde kart görünüm yüksekliğine göre 340–460 px arasında
uyarlanır. Asenkron PvP kartı ana eylemdir. Dokuz botun ayrı
`ScrollController` kullanan sabit yükseklikli listesi, varsayılan olarak kapalı
**Bot Antrenmanı** alanındadır. Seçili modülün döndürme eylemi hücre üzerinde
gösterilir; modül palete sürüklenerek kaldırılır.

Uygulama çubuğu sunucunun verdiği güvenli misafir adını gösterir. Yenileme
JWT'si `flutter_secure_storage` ile platformun güvenli anahtar/depolama
mekanizmasında tutulur; erişim JWT'si kalıcı depoya yazılmaz.

Sunucu sonucundaki `decision` yapısı arayüzde altı ölçütlü tabloya dönüştürülür.
İstemci yalnız sunucunun `criterion` değerini vurgular. Savaş durum kareleri
modül Can ve Isı değişimlerinin önceki kareye göre `+ / −` gösterilmesini
sağlar. Sıfır bekleme `Hazır`, pozitif bekleme `Doluyor: N` biçiminde yazılır.

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
