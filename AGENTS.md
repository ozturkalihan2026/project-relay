# Project Relay Agent Guide

Bu dosyanın kapsamı deponun tamamıdır. Bu depoda çalışan her Codex oturumu,
değişiklik yapmadan önce bu dosyayı ve `docs/CODEX_HANDOFF.md` dosyasını
okumalıdır.

## Oturum başlangıcı

1. Doğru depoda olduğunu `git rev-parse --show-toplevel` ile doğrula.
2. `git status --short --branch` ile dalı ve kullanıcı değişikliklerini incele.
3. `docs/CODEX_HANDOFF.md` ve son 10 commit'i oku.
4. Çalışma ağacı temizse, kullanıcı senkronizasyon istediyse
   `git pull --ff-only` kullan. Yerel değişiklik varken otomatik pull yapma.
5. Kullanıcıya ait ilgisiz, izlenmeyen veya yarım kalmış değişiklikleri silme,
   taşıma, ezme ya da commit'e katma.

## Proje haritası

- `relay_engine/`: deterministik savaş motoru ve oyun kuralları.
- `relay_api/`: FastAPI uygulaması, servisler, kalıcılık ve kimlik doğrulama.
- `relay_content/`: paketlenen oyun içeriği ve JSON verileri.
- `client/`: Flutter istemcisi.
- `tests/`: Python testleri.
- `client/test/`: Flutter testleri.
- `alembic/`: veritabanı göçleri.
- `docs/`: ürün, sürüm ve çalışma devri belgeleri.

## Aktif sürüm yönü: v0.8.23

Aktif iş paketi **v0.8.23 - Tek Savaş Sahnesi ve Fiziksel Devre Görünümü**'dür.
Ayrıntılı ilerleme ve güncel depo durumu `docs/CODEX_HANDOFF.md` içinde tutulur.
Bu paket üzerinde çalışan her oturum aşağıdaki ürün kararlarını korumalıdır:

1. Kariyer savaşı başlangıçtan sonuca kadar tek canlı sahnede yürür. Savaş
   bittikten sonra otomatik ikinci replay açılmaz; replay yalnız maç geçmişinden
   isteğe bağlı erişilen ayrı bir özellik olabilir.
2. Modül rafı savaş boyunca görünür kalır. 60/90/120. adım pencerelerinde
   etkinleşir; savaş durmadan bir geçerli sürükle-bırak kabul eder, hemen
   kilitlenir ve değişiklik sonraki güvenli sunucu tick'inde uygulanır. Koşu
   başına toplam iki, pencere başına en fazla bir değişim hakkı korunur.
3. Hazırlık, kariyer ve savaş aynı devre kartı geometrisini, çekirdeği, fiziksel
   modül donanımını, portları, kabloları ve enerji akış dilini kullanır.
4. Kablo ve enerji parçacıkları gerçek porttan gerçek porta bağlanır. Batarya
   bağlantıları çift yönlüdür; görsel olaylar sunucunun replay/snapshot olaylarıyla
   eşleşir ve istemci bağımsız savaş sonucu üretmez.
5. Modüller ikon kutusu olarak değil, işlevi gövdesinden okunan fiziksel donanım
   olarak çizilir. Lazer ve mermiler görünür namlu/emitör noktasından çıkar;
   kalkan, hasar, onarım ve enerji kayıtlarının eş zamanlı görsel karşılığı olur.
6. Teknoloji amaç değil araçtır. Varsayılan taban Flutter/CustomPainter'dır;
   Flame, Rive ve özellikle `flutter_unity_widget` üzerinden Unity, yalnız ölçülen
   bir prototip fiziksel görünüm veya performans ihtiyacını doğrularsa eklenir.
   Unity değerlendirmesinde web/Android uyumu, açılış süresi, bellek, paket boyutu,
   giriş katmanları, asset hattı ve bakım maliyeti birlikte ölçülür.
7. Ürün/API/istemci sürümü, paket kabul ölçütleri tamamlanmadan topluca
   yükseltilmez. Sürüm değişikliği yapılırken `pyproject.toml`, API sabiti,
   Flutter `pubspec.yaml`, README, Docker başlangıç/göç akışı ve test raporları
   birlikte kontrol edilir.

## Değişiklik kuralları

- Önce mevcut davranışı ve ilgili testleri oku; sonra dar kapsamlı değişiklik yap.
- Sunucu oyun sonucunun otoritesidir. İstemcide savaş sonucunu bağımsız olarak
  yeniden hesaplayan mantık ekleme.
- API sözleşmesi değişiyorsa şemaları, istemciyi, testleri ve ilgili belgeyi
  birlikte güncelle.
- Veritabanı şeması değişiklikleri için Alembic göçü ekle; yalnızca ORM modelini
  değiştirmekle yetinme.
- Gizli anahtar, token, parola veya gerçek `.env` içeriğini koda, belgelere,
  çıktılara ya da commit'lere koyma.
- Büyük mimari yeniden düzenlemeleri davranış değişikliklerinden ayrı tut.
- Kullanıcı açıkça istemedikçe commit veya push yapma.

## Doğrulama

Değişikliğe uygun en küçük testle başla, ardından mümkünse tam kontrolleri çalıştır:

```powershell
.\.venv\Scripts\python.exe -m pytest
cd client
flutter analyze
flutter test
```

Ortamda bir araç yoksa bunu başarısız test gibi sunma; hangi kontrolün neden
çalıştırılamadığını devir belgesine ve kullanıcıya açıkça yaz.

## Çalışma devri protokolü

Bilgisayar değiştirmeden veya anlamlı bir çalışma dilimini bitirmeden önce
`docs/CODEX_HANDOFF.md` dosyasını güncelle:

- güncelleme zamanı, aktif dal ve doğrulanmış son commit;
- tamamlanan işler ve alınan kararlar;
- commit edilmemiş/kullanıcıya ait dosyalar;
- çalıştırılan testler ve sonuçları;
- sıradaki somut işler, riskler ve engeller.

Tam sohbet dökümünü ekleme. Yalnızca sonraki oturumun güvenle devam etmesi için
gereken teknik bağlamı yaz. Devir belgesini kod değişikliğiyle birlikte commit
edip GitHub'a göndermek, diğer bilgisayarda `git pull --ff-only` sonrasında aynı
bağlamın okunmasını sağlar.

## Hazır komutlar

Yeni bilgisayarda oturum açılış istemi:

> AGENTS.md, docs/CODEX_HANDOFF.md, git status ve son 10 commit'i incele. Mevcut
> kullanıcı değişikliklerini koruyarak sıradaki işten devam et.

Bilgisayar değiştirmeden önce kapanış istemi:

> Yapılan işi doğrula, docs/CODEX_HANDOFF.md dosyasını güncelle ve commit/push
> için hangi dosyaların hazır olduğunu bildir. Ben istemeden commit veya push yapma.
