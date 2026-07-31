import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import 'replay_screen.dart';

/// Kariyer koşusunun savaş sonu yönlendirmesini normal tekrar akışından ayırır.
///
/// Savaş motoru ve replay görselleri ortak kalır; ancak kariyer ekranı yeni oyun
/// başlatmaz. Sonuç kesinleşince oyuncuyu sonraki rakip ön izlemesine, boss
/// hazırlığına veya koşu sonucuna geri götürür.
class CareerBattleScreen extends StatelessWidget {
  const CareerBattleScreen({
    required this.outcome,
    required this.replay,
    required this.modules,
    required this.stageNumber,
    super.key,
  });

  final CareerBattleResponse outcome;
  final ReplayResponse replay;
  final List<ModuleSpec> modules;
  final int stageNumber;

  String get _primaryActionLabel => switch (outcome.run.status) {
        'active' => 'SONRAKİ SAVAŞ',
        'awaiting_booster' => 'BOSS HAZIRLIĞINA GEÇ',
        'completed' => 'KOŞUYU TAMAMLA',
        'failed' => 'KARİYER SONUCUNA DÖN',
        _ => 'KARİYERE DÖN',
      };

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('career-battle-screen'),
      child: ReplayScreen(
        match: outcome.match,
        replay: replay,
        modules: modules,
        battleModeLabel:
            'KARİYER SAVAŞI • $stageNumber/${outcome.run.totalStages}',
        primaryActionLabel: _primaryActionLabel,
        primaryActionKey: 'career-battle-primary-action',
        primaryActionRequiresCompletion: true,
        onPrimaryAction: () => Navigator.of(context).pop(),
      ),
    );
  }
}
