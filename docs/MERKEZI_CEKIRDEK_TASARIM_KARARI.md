# Merkezî Çekirdek Tasarım Kararı — v0.3.10

## Karar

Merkezî çekirdek modeli v0.3.10'da uygulanmıştır ve mevcut serbest 4×4 modele
göre daha doğru tasarım olarak seçilmiştir.

- Ortadaki 2×2 alan enerji üretmeyen ve depolamayan pasif çekirdektir.
- Çevrede 12 yerleşim hücresi vardır; 6 modül sınırı korunur.
- Çekirdeğe yalnız dört simetrik kapı bağlanır.
- Jeneratör bir kapıya, çekirdeğe dönük yerleşir ve döndürülemez.
- Jeneratörün bir iç portu çekirdeği, iki yan portu halkanın iki yönünü
  besler.
- Enerjilenen çekirdek, enerjiyi diğer üç kapıya iletir.

## Geometri

|  |  |  |  |
| --- | --- | --- | --- |
| H1 | Kuzey kapısı | H2 | H3 |
| H4 | Çekirdek | Çekirdek | Doğu kapısı |
| Batı kapısı | Çekirdek | Çekirdek | H5 |
| H6 | H7 | Güney kapısı | H8 |

Kapı koordinatları ve çekirdeğe bakan zorunlu jeneratör yönleri:

| Kapı | Koordinat | Yön |
| --- | --- | --- |
| Kuzey | `(0,1)` | Güney |
| Doğu | `(1,3)` | Batı |
| Güney | `(3,2)` | Kuzey |
| Batı | `(2,0)` | Doğu |

## Neden seri bağlantıya dönüşmüyor?

Jeneratörün iki yan portu aynı anda halkanın saat yönü ve saat yönü tersindeki
ilk hücrelerine bağlanır. İç port çekirdeği enerjileyince diğer üç kapı da
bağımsız çıkış noktası olur. Böylece bir jeneratör:

- iki doğrudan halka ucunu,
- çekirdek üzerinden üç uzak kapı ucunu

aynı anda besleyebilir. Motor testi, jeneratör dâhil altı modüllük ve
bataryasız bir kartın kalan beş modülünü paralel olarak enerjileyebildiğini
doğrular.

## v0.3.9 ile ölçümlü karşılaştırma

Her iki sürümün tam rakip düzenleri, 21 tohumda kartlar iki tarafta da
oynatılarak aynı yöntemle ölçülmüştür.

| Ölçüt | v0.3.9 serbest 4×4 | v0.3.10 merkezî çekirdek |
| --- | ---: | ---: |
| Yerleşim hücresi | 16 | 12 |
| Modül sınırı | 6 | 6 |
| Dolu alan oranı | %37,5 | %50 |
| Jeneratör çıkış modeli | 4 doğrudan port | 2 halka + çekirdekten 3 uzak kapı |
| Sunucu rakibi | 8 | 9 |
| 1–6 modüllük varyant | 48 | 54 |
| Tam denge savaşı | 1.176 | 1.512 |
| Yenilmez düzen | 0 | 0 |
| En güçlü düzenin kazandığı ikili eşleşme | 6/7 (%85,7) | 7/8 (%87,5) |
| En güçlü düzene karşı çoğunlukla kazanan karşı düzen | Var | Var |

Not: Ön tasarım hesabında merkez modelin en güçlü eşleşme oranı `%85,7`
olarak ifade edilmişti. Doğru payda dokuz rakiple `7/8`, yani `%87,5`'tir.
Bu küçük artış yenilmez strateji üretmemiştir; Darbe Topu yaylımını Kalkan
Duvarı çoğunlukla yenmektedir.

İlk doğrudan uyarlamada `pulse_volley` topolojideki eylem sırasından
yararlanarak karşılıksız kalmıştır. Bu nedenle:

- Kalkan Duvarı iki Kalkan ve iki Darbe Topuyla yeniden düzenlenmiş,
- dört Darbe Topulu yığına özel üç Kalkanlı **Siper** rakibi eklenmiş,
- bütün dokuz rakibin karşı düzeni olduğu kalıcı teste bağlanmıştır.

Riskli dört Darbe Topulu yığın, Siper'e karşı 21 tohum ve iki taraflı toplam
42 savaşın `0–42` tamamını kaybetmiştir.

## Sonuç

Merkezî çekirdek daha mantıklıdır çünkü çekirdeği savaşın görsel ve mekanik
odağı yapar, jeneratöre benzersiz ve zorunlu bir rol verir, yerleşim alanını
daha okunaklı hâle getirir ve buna rağmen paralel devre kurma seçeneğini
korur. Eski serbest 4×4 modeline dönülmeyecektir.

İkinci aşamada çekirdek kapasitesi, kapı başına enerji sınırı veya hasarla
kapı kapanması eklenmemelidir. Bunlar mevcut karşı-strateji dengesini gereksiz
biçimde karmaşıklaştırır ve önde olan oyuncuyu daha da güçlendirebilir.
