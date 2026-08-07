import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../navigation/navigation_actions.dart';
import '../theme/relay_theme.dart';
import 'app_header_actions.dart';
import 'manual_circuit_demo.dart';
import 'module_visuals.dart';

class GameManualScreen extends StatelessWidget {
  const GameManualScreen({
    required this.modules,
    super.key,
  });

  final List<ModuleSpec> modules;

  @override
  Widget build(BuildContext context) {
    final specs = {
      for (final module in modules) module.kind: module,
    };
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 224,
        leading: const AppHeaderProfile(),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NASIL OYNANIR',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'PROJECT RELAY • v0.8.19',
              style: TextStyle(
                color: RelayColors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: const [
          AppHeaderActions(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _GoalCard(),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.electrical_services,
                    title: 'ENERJİ NASIL AKAR?',
                    subtitle: 'Bağlantının dört kesin kuralı',
                    children: [
                      _RuleLine(
                        index: '1',
                        text: 'Jeneratör dört çekirdek kapısından birine '
                            'yerleşir, çekirdeğe dönük kalır ve her savaş '
                            'adımında 8 enerji üretir.',
                      ),
                      _RuleLine(
                        index: '2',
                        text: 'Jeneratörün üç portundan biri pasif çekirdeğe, '
                            'ikisi çevre halkasının iki yönüne bakar.',
                      ),
                      _RuleLine(
                        index: '3',
                        text: 'Çekirdek enerji üretmez veya depolamaz; aldığı '
                            'enerjiyi portu açık diğer üç kapıya taşır.',
                      ),
                      _RuleLine(
                        index: '4',
                        text: 'Halkadaki komşu modüller yine karşılıklı '
                            'portlarla bağlanır. Batarya ve Güçlendirici dört '
                            'yönlü kavşak, diğerleri uç modüldür.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _OrientationGuide(),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.play_circle_outline,
                    title: 'ÖRNEK OYNANIŞ',
                    subtitle: 'Enerjinin devrede adım adım ilerleyişi',
                    children: [
                      ManualCircuitDemo(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.query_stats,
                    title: 'MODÜL DEĞERLERİ NE ANLAMA GELİR?',
                    subtitle: 'Bir modülü seçerken okuyacağınız on özellik',
                    children: [
                      _StatGuide(
                        name: 'Can',
                        icon: Icons.favorite_outline,
                        text: 'Modülün dayanıklılığıdır. Sıfıra inen modül '
                            'imha olur; enerji taşıyamaz ve eylem yapamaz.',
                        tactic: 'Yüksek tehditli saldırı modüllerini Kalkan '
                            've Onarım ile daha uzun süre koruyun.',
                      ),
                      _StatGuide(
                        name: 'Enerji',
                        icon: Icons.bolt,
                        text: 'Jeneratörün her savaş adımında devreye verdiği '
                            'güçtür. Başlangıç Jeneratörü 8 üretir.',
                        tactic: 'Aynı anda çalışan modüllerin toplam '
                            'maliyetini hesaplarken bu değeri temel alın.',
                      ),
                      _StatGuide(
                        name: 'Depo',
                        icon: Icons.battery_charging_full,
                        text: 'Bataryanın kullanılmayan enerjiyi sonraki '
                            'adımlara taşıma kapasitesidir.',
                        tactic: '8 enerji isteyen Darbe Topu için önce rezerv '
                            'biriktirin.',
                      ),
                      _StatGuide(
                        name: 'Maliyet',
                        icon: Icons.toll,
                        text: 'Modülün tek eylemde harcadığı enerjidir. Enerji '
                            'yetmezse modül o adımı bekleyerek geçirir.',
                        tactic: 'Ucuz Lazer ve Soğutucu, dar enerji '
                            'bütçelerinde daha sık çalışır.',
                      ),
                      _StatGuide(
                        name: 'Hasar',
                        icon: Icons.flash_on,
                        text: 'Saldırının rakip Kalkan, modül veya çekirdek '
                            'canından düşürdüğü değerdir.',
                        tactic: 'Lazer süreklilik, Darbe Topu yüksek tek '
                            'vuruş baskısı sağlar.',
                      ),
                      _StatGuide(
                        name: 'Kalkan',
                        icon: Icons.shield_outlined,
                        text: 'Gelen hasarı modül canına ulaşmadan önce '
                            'karşılayan ortak kart havuzudur.',
                        tactic: 'Düzenli yenilenen Kalkan, kırılgan saldırı '
                            'modüllerine zaman kazandırır.',
                      ),
                      _StatGuide(
                        name: 'Soğutma',
                        icon: Icons.ac_unit,
                        text: 'Enerjili devredeki canlı modüllerin ısısını '
                            'azaltır ve aşırı ısınmayı geciktirir.',
                        tactic: 'Darbe Topu ve Güçlendirici ile birlikte '
                            'kullanıldığında en çok değer üretir.',
                      ),
                      _StatGuide(
                        name: 'Onarım',
                        icon: Icons.build_outlined,
                        text: 'En çok hasar görmüş enerjili ve canlı modülün '
                            'canını geri kazandırır.',
                        tactic: 'İmha edilmiş modülü diriltemez; erken '
                            'bağlanması uzun savaşta avantaj sağlar.',
                      ),
                      _StatGuide(
                        name: 'Isı',
                        icon: Icons.device_thermostat,
                        text: 'Her eylemle artar. 100 değerinde modül durur, '
                            '55 değerine düşünce yeniden çalışır.',
                        tactic: 'Yüksek hasarı daha fazla ısıyla aldığınızı '
                            'unutmayın.',
                      ),
                      _StatGuide(
                        name: 'Bekleme',
                        icon: Icons.timer_outlined,
                        text: 'Modülün bir eylemden sonra yeniden '
                            'çalışabilmek için beklediği savaş adımıdır.',
                        tactic: 'Kısa bekleme süreli modüller daha istikrarlı, '
                            'uzun beklemeliler daha patlayıcıdır.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ManualSection(
                    icon: Icons.memory,
                    title: 'SEKİZ BAŞLANGIÇ MODÜLÜ',
                    subtitle: 'Görevleri, bağlantıları ve savaş etkileri',
                    children: [
                      for (final guide in _moduleGuides)
                        _ModuleGuideCard(
                          guide: guide,
                          spec: specs[guide.kind],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.device_thermostat,
                    title: 'ENERJİ, ISI VE EYLEM SIRASI',
                    subtitle: 'Modül bağlı olsa bile neden bekleyebilir?',
                    children: [
                      _ManualParagraph(
                        text: 'Bağlı olmak, modülün enerji ağına katıldığı '
                            'anlamına gelir. Savaş adımındaki toplam enerji '
                            'yetmezse kartta yukarıdan aşağıya ve soldan sağa '
                            'önce gelen eylem öncelik kazanır.',
                      ),
                      _ManualParagraph(
                        text: 'Kullanılmayan enerji yalnızca bağlı Bataryanın '
                            'kapasitesi kadar saklanır. Bu rezerv, maliyeti '
                            'Jeneratörün tek adımlık üretiminden yüksek olan '
                            'Darbe Topu için özellikle önemlidir.',
                      ),
                      _ManualParagraph(
                        text: 'Eylemler ısı üretir. Isı 100 olduğunda modül '
                            'durur; 55 değerine soğuduğunda yeniden çalışır. '
                            'Soğutucu bağlı devrenin tamamını soğutur.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.shield_outlined,
                    title: 'KALKAN NASIL ÇALIŞIR?',
                    subtitle: 'Bağlantı ve koruma davranışı',
                    children: [
                      _ManualParagraph(
                        text: 'Kalkanın arka portu bir çekirdek kapısına, '
                            'Jeneratörün halka portuna ya da Batarya ve '
                            'Güçlendirici üzerinden kurulan hatta bağlanabilir.',
                      ),
                      _ManualParagraph(
                        text: 'Enerjili Kalkan her eyleminde kartın ortak '
                            'kalkan havuzuna 14 koruma ekler. Gelen saldırı '
                            'önce bu havuzdan karşılanır; havuz en fazla 60 '
                            'olabilir. Kalkan modülleri ayrıca silahlardan '
                            'önce hedef çekerek onları korur.',
                      ),
                      _ManualParagraph(
                        text: 'Kalkan tek portlu bir uç modüldür. Kalkanın '
                            'öteki tarafına yerleştirilen modül, Kalkan '
                            'üzerinden enerji alamaz.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.rule,
                    title: 'DOĞRULAMA İŞARETLERİ',
                    subtitle: 'Kart üzerindeki renkleri okuyun',
                    children: [
                      _LegendLine(
                        color: RelayColors.cyan,
                        icon: Icons.bolt,
                        title: 'Enerjili',
                        text: 'Jeneratöre kesintisiz ve karşılıklı portlarla '
                            'bağlıdır.',
                      ),
                      _LegendLine(
                        color: RelayColors.coral,
                        icon: Icons.link_off,
                        title: 'Enerjisiz',
                        text: 'Bir port eksik, yön yanlış veya arada boşluk '
                            'vardır.',
                      ),
                      _LegendLine(
                        color: RelayColors.amber,
                        icon: Icons.swap_horiz,
                        title: 'Değiştirme hedefi',
                        text: 'Kart modülü bırakılırsa hücreler yer değiştirir; '
                            'palet modülü bırakılırsa eski modül çıkarılır.',
                      ),
                      _ManualParagraph(
                        text: 'Kart 4×4 alandır; ortadaki 2×2 alan pasif '
                            'çekirdektir ve çevrede 12 yerleşim hücresi kalır. '
                            'En fazla 6 modül kullanın; doğrulama sonucu 6/6 '
                            'enerjili göstermelidir.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.inventory_2_outlined,
                    title: 'SEKİZLİ KİT VE KOLEKSİYON',
                    subtitle: 'Hazırlık seçimi güç satışından ayrı tutulur',
                    children: [
                      _ManualParagraph(
                        text: 'Sekizli kit, savaş editöründe erişebileceğiniz '
                            'modül havuzudur. Kartta en fazla altı modül '
                            'kullanılır; kitte kalan iki yuva farklı rakiplere '
                            'karşı yedek seçenektir.',
                      ),
                      _ManualParagraph(
                        text: 'Kit tam olarak sekiz yuva ve yalnız bir '
                            'Jeneratör içerir. Jeneratör dışındaki bir modül '
                            'türü en fazla üç kez seçilebilir. Editör paletindeki '
                            'sayı rozeti o türden kaç kit yuvasının kaldığını '
                            'gösterir.',
                      ),
                      _ManualParagraph(
                        text: 'Kozmetik mağaza modül gücü, hasar, enerji veya '
                            'savaş hakkı satmaz. Devre Kredisi yalnız modül '
                            'kaplaması, devre kartı teması ve profil çerçevesi '
                            'gibi görsel koleksiyon ürünlerinde kullanılır.',
                      ),
                      _ManualParagraph(
                        text: 'Satın alınan içerikler kalıcı koleksiyona eklenir. '
                            'Kuşanılan devre kartı teması kurulum ekranında ve '
                            'savaş tekrarındaki sizin kartınızda görünür. Modül '
                            'kaplaması modül vurgularını ve saldırı darbelerinin '
                            'rengini, profil çerçevesi üst oyuncu bilgi alanını '
                            'değiştirir. Hiçbiri savaş dengesini değiştirmez.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.route_outlined,
                    title: 'KARİYER KOŞUSU VE KARŞI DEVRE',
                    subtitle: 'Beş savaş, tam ön izleme ve boss hazırlığı',
                    children: [
                      _ManualParagraph(
                        text: 'Kariyer koşusu birbirine bağlı beş savaştan '
                            'oluşur. Her aşamada savaş başlamadan önce rakibin '
                            'gerçekte kullanacağı devreyi bütünüyle görürsünüz. '
                            'Modül türlerini, konumlarını ve bağlantı yönlerini '
                            'inceleyip Devremi Düzenle ile karşı devrenizi '
                            'hazırlayın.',
                      ),
                      _ManualParagraph(
                        text: 'Kariyer devresi ile Asenkron PvP devresi ayrı '
                            'kaydedilir. Kariyerde yaptığınız düzenleme PvP '
                            'kartınızı, PvP için yaptığınız düzenleme de '
                            'kariyer kartınızı değiştirmez.',
                      ),
                      _ManualParagraph(
                        text: 'Kariyer savaşları kendine ait savaş ekranında '
                            'oynanır. Savaş sonucu kesinleşince Yeni Oyun yerine '
                            'Sonraki Savaş düğmesi görünür. Bu düğme yeni savaşı '
                            'otomatik başlatmaz; bir sonraki rakibin tam devre '
                            'ön izlemesine döner. Devrenizi yeniden düzenledikten '
                            'sonra savaşı siz başlatırsınız.',
                      ),
                      _ManualParagraph(
                        text: 'Dördüncü zaferin ardından düğme Boss Hazırlığına '
                            'Geç olur. Yalnız boss savaşında geçerli olacak tek '
                            'bir geçici güçlendiriciyi Devre Kredisi ile satın '
                            'alabilir veya satın almadan ilerleyebilirsiniz.',
                      ),
                      _ManualParagraph(
                        text: 'Boss Güçlendirici Kademeleri kalıcı modül gücü '
                            'değildir. K1 başlangıçtır; K2, K3, K4 ve K5 sırasıyla '
                            '10, 20, 30 ve 40. seviyelerde açılır ve yalnız boss '
                            'öncesinde satın alınan geçici etkinin miktarını belirler.',
                      ),
                      _ManualParagraph(
                        text: 'Koşu tamamlandığında, kaybedildiğinde veya '
                            'bırakıldığında geçici güçlendirici sıfırlanır. '
                            'Kariyer güçlendirmeleri normal ya da dereceli PvP '
                            'savaşlarına taşınmaz.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.insights_outlined,
                    title: 'SEVİYE VE EKONOMİ',
                    subtitle: 'Erken öğrenme hızlı, uzun vadeli ilerleme kontrollü',
                    children: [
                      _ManualParagraph(
                        text: 'İlk beş seviye öğretici tempoyu korur. Sonraki '
                            'seviyelerde gereken XP kademeli olarak yükselir; '
                            'seviye 40 son boss güçlendirici kademesini açar ama '
                            'kariyer modu burada bitmez ve koşular tekrar oynanır.',
                      ),
                      _ManualParagraph(
                        text: 'Devre Kredisi asenkron savaşlar, günlük görevler, '
                            'başarımlar ve kariyer koşularından kazanılır. Boss '
                            'güçlendiricileri kredi harcar; kozmetik fiyatları da '
                            'koleksiyonun birkaç oturumda tükenmemesi için '
                            'uzun vadeli hedef olarak ayarlanmıştır.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.auto_awesome,
                    title: 'SEZON VE KAPALI ALFA',
                    subtitle: 'Aylık hedefler, adil puan ve güvenli geri bildirim',
                    children: [
                      _ManualParagraph(
                        text: 'Sezon puanı yalnız gerçek oyuncuya karşı yapılan '
                            'asenkron dereceli savaşlardan gelir. Galibiyet 5, '
                            'beraberlik 3 ve mağlubiyet 1 sezon puanı verir. '
                            'Bot ve antrenman savaşları sezon sıralamasını etkilemez.',
                      ),
                      _ManualParagraph(
                        text: 'Sezon kademeleri sınırlı XP ve Devre Kredisi '
                            'ödülleri verir. Ödüller sunucu tarafından tek '
                            'seferlik kaydedilir; aynı kademe tekrar alınamaz.',
                      ),
                      _ManualParagraph(
                        text: 'Kapalı alfa ekranı savaş isteği sınırını, tek '
                            'seferlik ödül korumasını ve sunucu doğrulamasını '
                            'gösterir. Çok hızlı istekler kısa süreli sınırlandırılır.',
                      ),
                      _ManualParagraph(
                        text: 'Denge, hata veya arayüz geri bildirimi Sezon ve '
                            'Alfa ekranından doğrudan kaydedilebilir. Kişisel '
                            'bilgi yazmayın; ne olduğunu ve beklenen davranışı açıklayın.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.groups_2_outlined,
                    title: 'SOSYAL MERKEZ',
                    subtitle: 'Profil, arkadaşlık istekleri ve açık klanlar',
                    children: [
                      _ManualParagraph(
                        text: 'Sosyal profilinde kısa bir durum mesajı ve '
                            'favori modülünü gösterebilirsin. Bu bilgiler savaş '
                            'gücünü değiştirmez; yalnızca oyuncu kimliğini '
                            'diğer devre ustalarına tanıtır.',
                      ),
                      _ManualParagraph(
                        text: 'Oyuncu adıyla arama yapabilir, arkadaşlık isteği '
                            'gönderebilir ve gelen istekleri kabul ya da '
                            'reddedebilirsin. Arkadaş listesi sosyal bağlantıdır; '
                            'eşleşme veya ödül avantajı sağlamaz.',
                      ),
                      _ManualParagraph(
                        text: 'Açık klanlara katılabilir veya 20 üyeye kadar '
                            'kendi klanını kurabilirsin. İlk sürümde klanlar '
                            'isim, etiket, açıklama ve üye listesi sunar; klan '
                            'savaşları daha sonraki sürümlerde değerlendirilecektir.',
                      ),
                      _ManualParagraph(
                        text: 'Bir oyuncu aynı anda yalnızca bir klana üye olur. '
                            'Lider, klanında başka üyeler varken ayrılamaz; '
                            'üyelik kuralları sunucu tarafından doğrulanır.',
                      ),
                      _ManualParagraph(
                        text: 'Durum mesajı ve klan metinleri herkese açıktır. '
                            'Kişisel bilgi veya iletişim adresi paylaşma. '
                            'Raporlama ve engelleme tamamlanana kadar uygunsuz '
                            'içerikleri Alfa Geri Bildirimi ile ilet.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.notifications_active_outlined,
                    title: 'BİLDİRİMLER',
                    subtitle: 'Her ekranda aynı okunabilir uyarı kuralı',
                    children: [
                      _ManualParagraph(
                        text: 'Başarı, bilgi, uyarı ve hata mesajları ekranın '
                            'ortasında yarı saydam bir kutuda gösterilir. '
                            'Sayfa kaydırılmış olsa bile bildirim görünür '
                            'kalır ve kısa süre sonra otomatik kapanır. '
                            'Asenkron PvP savaşının XP ve Devre Kredisi ödülü '
                            'de savaş ekranının altına eklenmez; aynı ortak '
                            'bildirim kutusunda gösterilir. Seviye atlandığında '
                            'yeni seviye, kazanılan XP/Kredi ve açılan kademe ayrı '
                            'bir kutlama rozetiyle görünür.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.emoji_events_outlined,
                    title: 'SAVAŞI KAZANMAK',
                    subtitle: 'Amaç ve beraberlik kuralları',
                    children: [
                      _ManualParagraph(
                        text: 'Amaç, kendi çekirdeğinizi korurken rakibin '
                            'çekirdeğini sıfıra indirmektir. Saldırı, savunma, '
                            'enerji rezervi ve ısı kontrolü arasında denge '
                            'kurun.',
                      ),
                      _ManualParagraph(
                        text: 'Saldırılar önce Jeneratör dışındaki bütün canlı '
                            'modülleri hedefler. Bu modüller bitince Jeneratör, '
                            'Jeneratör imha edilince en son çekirdek hedefe '
                            'açılır.',
                      ),
                      _ManualParagraph(
                        text: 'Süre biterse önce hayatta kalan modül sayısı '
                            'karşılaştırılır. Modül kaybı eşitse verilen toplam '
                            'hasar, ardından kalan modül canı, çekirdek canı, '
                            'enerji verimi ve düşük ısı dikkate alınır. Tam '
                            'eşitlik beraberliktir.',
                      ),
                      _ManualParagraph(
                        text: 'Asenkron PvP kartınız ayrı olarak sunucuda '
                            'kaydedilir ve aynı modül sayısındaki başka bir '
                            'oyuncu düzeniyle eşleştirilir. Rakip, hedef '
                            'seçimi, hasar, sonuç ve tekrar kaydı sunucu '
                            'tarafından belirlenir.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _ManualSection(
                    icon: Icons.psychology_alt_outlined,
                    title: 'NEDEN TEKRAR OYNAMALI?',
                    subtitle: 'Kazancın yalnızca sonuç ekranı olmadığı yer',
                    children: [
                      _ManualParagraph(
                        text: 'Her savaş bir devre bulmacasının cevabıdır. '
                            'Kazandığınızda ödül; kurduğunuz enerji düzeninin '
                            'gerçekten çalıştığını görmek, rakibin zayıf '
                            'noktasını çözmek ve tekrarda kararınızın etkisini '
                            'izlemektir.',
                      ),
                      _ManualParagraph(
                        text: 'Yeni hedefiniz farklı gerçek oyuncu devrelerine '
                            'karşı daha az enerji kaybı, daha çok canlı modül '
                            've doğru karşı bileşim bulmaktır. Bot Antrenmanı '
                            'ise aynı rakibe karşı değişikliğinizi ölçmenizi '
                            'sağlar.',
                      ),
                      _ManualParagraph(
                        text: 'Project Relay kalıcı güç satmayacak; ilerleme '
                            'daha güçlü sayı satın almak yerine yeni taktikleri '
                            'öğrenme, derece kazanma ve kozmetik başarılarla '
                            'görünür olacaktır.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    key: const Key('manual-bottom-back-button'),
                    onPressed: () => returnToMainMenu(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Text('ANA MENÜYE DÖN'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF112B35),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OYUNUN AMACI NEDİR?',
              style: TextStyle(
                color: RelayColors.amber,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Merkezinde 2×2 pasif çekirdek bulunan 4×4 kartın çevresine '
              'en fazla 6 modül ve tam olarak bir Jeneratör yerleştirerek '
              'çalışan bir '
              'savaş devresi kurun. Enerjiyi saldırı, savunma ve destek '
              'modüllerine ulaştırın; ardından gerçek bir oyuncunun kayıtlı '
              'düzenine karşı asenkron sunucu savaşını başlatın. Asıl başarı '
              'yalnızca '
              '“Zafer” yazısı değil; kendi tasarladığınız düzenin neden '
              'kazandığını savaş kartlarında okuyabilmektir.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GoalChip(icon: Icons.grid_4x4, label: '12 HÜCRE'),
                _GoalChip(icon: Icons.bolt, label: '1 JENERATÖR'),
                _GoalChip(icon: Icons.hub_outlined, label: '4 ÇEKİRDEK KAPISI'),
                _GoalChip(icon: Icons.sports_mma, label: 'OTOMATİK SAVAŞ'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: RelayColors.cyan, size: 17),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ManualSection extends StatelessWidget {
  const _ManualSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: RelayColors.cyan),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: RelayColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ..._withSpacing(children),
          ],
        ),
      ),
    );
  }

  static List<Widget> _withSpacing(List<Widget> children) {
    return [
      for (var index = 0; index < children.length; index++) ...[
        children[index],
        if (index < children.length - 1) const SizedBox(height: 10),
      ],
    ];
  }
}

class _OrientationGuide extends StatelessWidget {
  const _OrientationGuide();

  @override
  Widget build(BuildContext context) {
    return const _ManualSection(
      icon: Icons.rotate_right,
      title: 'OK VE PORT YÖNLERİ',
      subtitle: 'Okun anlamı modülün işlevine göre açıkça gösterilir',
      children: [
        _ManualParagraph(
          text: 'Lazer, Darbe Topu, Kalkan, Soğutucu ve Onarım Ünitesindeki '
              'ok, enerji alan tek portun yönünü gösterir. Bu ok bağlı '
              'devreye veya çekirdek kapısına bakmalıdır. Noktaları karşı '
              'karşıya getirdiğinizde modül enerji ağına katılır.',
        ),
        _ManualParagraph(
          text: 'Batarya dört yönlü ve yönsüz bir kavşaktır. Güçlendiricinin '
              'dört kenarında port bulunur; onun oku enerji girişini değil, '
              'hangi komşu modülün güçleneceğini gösterir. Kart dışına veya '
              'kapısız çekirdek kenarına bakan kullanılamayan uçlar '
              'kalabalık oluşturmaması için çizilmez.',
        ),
        _ManualParagraph(
          text: 'Jeneratör yalnızca dört çekirdek kapısına yerleşir ve ön '
              'yönü otomatik olarak çekirdeğe kilitlenir. Kalan iki port '
              'halkada saat yönü ve ters yön için iki ayrı başlangıç verir.',
        ),
        _DirectionExample(
          icon: Icons.arrow_forward,
          text: 'Üst kapıdaki Jeneratör Güneye, sağ kapıdaki Batıya bakar.',
        ),
        _DirectionExample(
          icon: Icons.arrow_back,
          text: 'Alt kapıdaki Jeneratör Kuzeye, sol kapıdaki Doğuya bakar.',
        ),
        _DirectionExample(
          icon: Icons.hub_outlined,
          text: 'Diğer kapıdaki bir modülün çekirdeğe bakan portu açıksa '
              'enerjiyi doğrudan pasif omurgadan alır.',
        ),
      ],
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.index, required this.text});

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: RelayColors.amber,
          child: Text(
            index,
            style: const TextStyle(
              color: Color(0xFF10242D),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _DirectionExample extends StatelessWidget {
  const _DirectionExample({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0x2238E8FF),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, color: RelayColors.cyan, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
      ],
    );
  }
}

class _ManualParagraph extends StatelessWidget {
  const _ManualParagraph({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFBDD0D6),
        height: 1.45,
      ),
    );
  }
}

class _StatGuide extends StatelessWidget {
  const _StatGuide({
    required this.name,
    required this.icon,
    required this.text,
    required this.tactic,
  });

  final String name;
  final IconData icon;
  final String text;
  final String tactic;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x99101E25),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFF28515E)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0x2238E8FF),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: RelayColors.cyan, size: 19),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: RelayColors.amber,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(text, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 4),
                  Text(
                    'Faydalı kullanım: $tactic',
                    style: const TextStyle(
                      color: RelayColors.muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({
    required this.color,
    required this.icon,
    required this.title,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title — ',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
            style: const TextStyle(height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _ModuleGuideData {
  const _ModuleGuideData({
    required this.kind,
    required this.role,
    required this.connection,
    required this.effect,
    required this.advantage,
    required this.disadvantage,
    required this.tip,
  });

  final ModuleKind kind;
  final String role;
  final String connection;
  final String effect;
  final String advantage;
  final String disadvantage;
  final String tip;
}

const _moduleGuides = [
  _ModuleGuideData(
    kind: ModuleKind.generator,
    role: 'Enerji kaynağı',
    connection: 'Üç portludur; yalnız çekirdek kapısında ve içe dönük çalışır.',
    effect: 'Her savaş adımında bağlı devre için 8 enerji üretir.',
    advantage: 'Çekirdek ve iki halka yönünü aynı anda besleyebilir.',
    disadvantage: 'İmha edilirse tüm devre enerjisiz kalır ve yedeklenemez.',
    tip: 'Kapı seçimi, ilk saldırı kolunuzla yedek enerji yolunuzu belirler.',
  ),
  _ModuleGuideData(
    kind: ModuleKind.battery,
    role: 'Enerji dağıtma ve depolama',
    connection: 'Dört yönde portu vardır; hattı döndürür, böler ve sürdürür.',
    effect: 'Kullanılmayan enerjiyi 20 birime kadar saklar.',
    advantage: 'Altı modüllük kartta farklı enerji kolları kuran ana kavşaktır.',
    disadvantage: 'Doğrudan hasar veya savunma üretmez; kartta yer kaplar.',
    tip: '8 enerji isteyen Darbe Topunu düzenli ateşlemek için kullanın.',
  ),
  _ModuleGuideData(
    kind: ModuleKind.laser,
    role: 'Hızlı saldırı',
    connection: 'Tek arka porttan enerji alır; hattı devam ettirmez.',
    effect: '4 enerjiyle 8 hasar verir; 2 adım bekler ve 14 ısı üretir.',
    advantage: 'Düşük maliyet ve kısa bekleme ile düzenli baskı kurar.',
    disadvantage: 'Tek vuruşu zayıftır; yenilenen Kalkanı geçmekte zorlanır.',
    tip: 'Düşük maliyeti sayesinde Bataryasız devrelerde güvenilir saldırıdır.',
  ),
  _ModuleGuideData(
    kind: ModuleKind.pulseCannon,
    role: 'Ağır saldırı',
    connection: 'Tek arka porttan enerji alır; hattı devam ettirmez.',
    effect: '8 enerjiyle 16 hasar verir; 4 adım bekler ve 30 ısı üretir.',
    advantage: 'Yüksek tek vuruş hasarı Kalkanı ve kırılgan modülleri deler.',
    disadvantage: 'Çoklu kullanımda Batarya ister; yavaş çalışır ve hızla ısınır.',
    tip: 'Tek Darbe Topunu Jeneratör çalıştırır; yaylım için Batarya rezervi kurun.',
  ),
  _ModuleGuideData(
    kind: ModuleKind.shield,
    role: 'Kart savunması',
    connection: 'Tek arka porttan enerji alır; Jeneratör, Batarya veya '
        'Güçlendirici hattına bağlanabilir.',
    effect: '5 enerjiyle ortak kalkan havuzuna 14 ekler; 3 adım bekler.',
    advantage: 'Gelen hasarı emer ve saldırı modüllerinden önce hedef çeker.',
    disadvantage: 'Saldırı üretmez; yüksek tempolu Darbe Topuna karşı '
        'yenilenme aralığında kırılabilir.',
    tip: 'Kalkan hattın sonu olmalıdır; arkasına başka modül bağlamayın.',
  ),
  _ModuleGuideData(
    kind: ModuleKind.cooler,
    role: 'Isı kontrolü',
    connection: 'Tek arka porttan enerji alır; hattı devam ettirmez.',
    effect: '3 enerjiyle bağlı devredeki tüm canlı modüllerden 12 ısı düşürür.',
    advantage: 'Sıcak saldırı düzenlerinin çalışır kalma süresini uzatır.',
    disadvantage: 'Düşük ısılı kısa savaşta harcadığı enerji boşa gidebilir.',
    tip: 'Darbe Topu veya Güçlendirici kullanılan sıcak devrelerde değerlidir.',
  ),
  _ModuleGuideData(
    kind: ModuleKind.amplifier,
    role: 'Etki güçlendirme ve enerji aktarma',
    connection: 'Dört portludur; çekirdek kapısında iki halka kolunu besler.',
    effect: 'Hemen önündeki bağlı modülün etkisini 1,35×, ısısını 1,25× yapar.',
    advantage: 'Enerjiyi dallandırırken seçilen tek bir kritik modülü büyütür.',
    disadvantage: 'Ek ısı üretir ve yalnızca önündeki doğru bağlı hedefe '
        'etki eder.',
    tip: 'Kapıda oku halka üzerindeki güçlendirilecek komşuya çevirin.',
  ),
  _ModuleGuideData(
    kind: ModuleKind.repair,
    role: 'Hasar onarımı',
    connection: 'Tek arka porttan enerji alır; hattı devam ettirmez.',
    effect: '5 enerjiyle en çok hasar görmüş bağlı canlı modülü 11 onarır.',
    advantage: 'Uzayan savaşlarda değerli modülleri ayakta tutar.',
    disadvantage: 'İmha edilmiş hedefi diriltemez ve çekirdeği onaramaz.',
    tip: 'Yok edilmiş modülü diriltemez; uzun savaşlarda dayanıklılık sağlar.',
  ),
];

class _ModuleGuideCard extends StatelessWidget {
  const _ModuleGuideCard({
    required this.guide,
    required this.spec,
  });

  final _ModuleGuideData guide;
  final ModuleSpec? spec;

  @override
  Widget build(BuildContext context) {
    final color = moduleColor(guide.kind);
    final name = spec?.displayName ?? guide.kind.displayName;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x99101E25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(moduleIcon(guide.kind), color: color),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        guide.role,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (spec != null)
                  Text(
                    '${spec!.maxHp.toStringAsFixed(0)} CAN',
                    style: const TextStyle(
                      color: RelayColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            _GuideDetail(label: 'Bağlantı', text: guide.connection),
            const SizedBox(height: 5),
            _GuideDetail(label: 'Etkisi', text: guide.effect),
            const SizedBox(height: 5),
            _GuideDetail(label: 'Avantaj', text: guide.advantage),
            const SizedBox(height: 5),
            _GuideDetail(label: 'Dezavantaj', text: guide.disadvantage),
            const SizedBox(height: 5),
            _GuideDetail(label: 'Taktik', text: guide.tip),
          ],
        ),
      ),
    );
  }
}

class _GuideDetail extends StatelessWidget {
  const _GuideDetail({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: RelayColors.amber,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: text),
        ],
      ),
      style: const TextStyle(
        color: Color(0xFFBDD0D6),
        fontSize: 11,
        height: 1.4,
      ),
    );
  }
}
