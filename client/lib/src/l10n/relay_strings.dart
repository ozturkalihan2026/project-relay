import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class RelayStrings {
  const RelayStrings(this.locale);

  final Locale locale;

  bool get _english => locale.languageCode == 'en';

  static const delegate = _RelayStringsDelegate();

  static RelayStrings of(BuildContext context) {
    return Localizations.of<RelayStrings>(context, RelayStrings) ??
        const RelayStrings(Locale('tr'));
  }

  String get onlineBattle => _english ? 'ONLINE BATTLE' : 'ÇEVRİMİÇİ SAVAŞ';
  String get onlineBadge => _english ? 'ASYNC PvP' : 'ASENKRON PvP';
  String get onlineSubtitle => _english
      ? 'Build your circuit, face an equal-module rival and raise your rating.'
      : 'Devreni kur, eşit modüllü rakibe karşı stratejini sınayıp dereceni yükselt.';
  String get careerPath => _english ? 'CAREER PATH' : 'KARİYER YOLU';
  String get careerBadge => _english ? '5-STAGE PATH' : '5 AŞAMALI YOL';
  String get careerSubtitle => _english
      ? 'Read rival circuits, upgrade modules for the run and reach the sector boss.'
      : 'Rakip devreleri aç, modüllerini koşuya özel yükselt ve sektör boss’una ulaş.';
  String get statistics => _english ? 'STATISTICS' : 'İSTATİSTİKLER';
  String get statisticsSubtitle => _english
      ? 'Season, weekly league and competitive performance'
      : 'Sezon, haftalık lig ve rekabet performansı';
  String get profile => _english ? 'PROFILE' : 'PROFİL';
  String get profileSubtitle => _english
      ? 'Daily missions, achievements, season rewards and match history'
      : 'Günlük görevler, başarımlar, sezon ödülleri ve maç geçmişi';
  String get settingsTitle => _english ? 'SETTINGS' : 'AYARLAR';
  String get replaySound =>
      _english ? 'Music and battle sounds' : 'Müzik ve savaş sesleri';
  String get replaySoundSubtitle => _english
      ? 'Controls menu ambience, battle music and combat effects.'
      : 'Ana menü ambiyansını, savaş müziğini ve çatışma efektlerini yönetir.';
  String get replaySpeed =>
      _english ? 'Default replay speed' : 'Varsayılan tekrar hızı';
  String get appearance => _english ? 'Appearance' : 'Görünüm';
  String get appearanceSubtitle => _english
      ? 'High-contrast dark circuit theme is active.'
      : 'Yüksek kontrastlı koyu devre teması etkin.';
  String get language => _english ? 'Language' : 'Dil';
  String get languageSubtitle => _english
      ? 'Interface translation is being expanded screen by screen.'
      : 'Arayüz çevirisi ekran ekran genişletiliyor.';
  String get telemetry => _english ? 'Product telemetry' : 'Ürün telemetrisi';
  String get telemetrySubtitle => _english
      ? 'Share privacy-limited interaction events that improve balance and flow.'
      : 'Dengeyi ve akışı iyileştiren, kişisel içerik taşımayan etkileşim olaylarını paylaş.';
  String get alphaFeedback =>
      _english ? 'Alpha feedback' : 'Alfa geri bildirimi';
  String get alphaFeedbackSubtitle => _english
      ? 'Send balance, bug and interface feedback.'
      : 'Denge, hata ve arayüz geri bildirimlerini buradan gönder.';
  String get sandbox => 'SANDBOX LAB';
  String get sandboxSubtitle => _english
      ? 'Test connections against bot circuits without affecting saves or rating.'
      : 'Kayıt ve derece baskısı olmadan bot devrelerine karşı bağlantılarını test et.';
  String get backToMain => _english ? 'BACK TO MAIN MENU' : 'ANA MENÜYE DÖN';
}

class _RelayStringsDelegate extends LocalizationsDelegate<RelayStrings> {
  const _RelayStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const {'tr', 'en'}.contains(locale.languageCode);

  @override
  Future<RelayStrings> load(Locale locale) {
    return SynchronousFuture(RelayStrings(locale));
  }

  @override
  bool shouldReload(_RelayStringsDelegate old) => false;
}
