import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/relay_theme.dart';

class BattleAnalysisPanel extends StatelessWidget {
  const BattleAnalysisPanel({
    required this.match,
    required this.replay,
    required this.modules,
    this.onRematch,
    super.key,
  });

  final MatchResponse match;
  final ReplayResponse replay;
  final List<ModuleSpec> modules;
  final VoidCallback? onRematch;

  @override
  Widget build(BuildContext context) {
    final analysis = BattleAnalysis.fromMatch(match, replay, modules);
    final result = match.result;
    final resultLabel = switch (result.winner) {
      'left' => 'ZAFER',
      'right' => 'YENİLGİ',
      _ => 'BERABERE',
    };
    final resultColor = switch (result.winner) {
      'left' => RelayColors.mint,
      'right' => RelayColors.coral,
      _ => RelayColors.amber,
    };
    final reward = match.progressionReward;
    final season = match.seasonChange;
    final recommendation = RematchRecommendation.fromAnalysis(
      match: match,
      replay: replay,
      analysis: analysis,
    );

    return Container(
      key: const ValueKey('battle-analysis-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: RelayDecorations.panel(accent: resultColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SAVAŞ ANALİZİ',
                      style: TextStyle(
                        color: RelayColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resultLabel,
                      style: TextStyle(
                        color: resultColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              if (reward != null)
                _RewardBadge(
                  xp: reward.xp,
                  credits: reward.credits,
                  seasonPoints: season?.pointsGained,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            analysis.decisionExplanation,
            key: const ValueKey('battle-analysis-decision'),
            style: TextStyle(
              color: resultColor,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _RematchLabCard(recommendation: recommendation, onRematch: onRematch),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = <Widget>[
                _MetricCard(
                  icon: Icons.flash_on,
                  label: 'VERİLEN HASAR',
                  value: analysis.playerDamage.toStringAsFixed(0),
                  detail: 'Rakip: ${analysis.enemyDamage.toStringAsFixed(0)}',
                  color: RelayColors.coral,
                ),
                _MetricCard(
                  icon: Icons.bolt,
                  label: 'ENERJİ',
                  value: analysis.playerEnergy.toStringAsFixed(0),
                  detail: '${analysis.playerStarved} kez enerji açlığı',
                  color: RelayColors.amber,
                ),
                _MetricCard(
                  icon: Icons.shield_outlined,
                  label: 'KALKAN EMİŞİ',
                  value: analysis.playerShieldAbsorbed.toStringAsFixed(0),
                  detail:
                      'Rakip: ${analysis.enemyShieldAbsorbed.toStringAsFixed(0)}',
                  color: RelayColors.electricBlue,
                ),
                _MetricCard(
                  icon: Icons.build_outlined,
                  label: 'ONARIM',
                  value: analysis.playerRepair.toStringAsFixed(0),
                  detail:
                      'Soğutma ${analysis.playerCooling.toStringAsFixed(0)}',
                  color: RelayColors.mint,
                ),
                _MetricCard(
                  icon: Icons.local_fire_department_outlined,
                  label: 'AŞIRI ISI',
                  value: '${analysis.playerOverheats}',
                  detail: 'Rakip: ${analysis.enemyOverheats}',
                  color: RelayColors.amber,
                ),
                _MetricCard(
                  icon: Icons.memory_outlined,
                  label: 'AYAKTA KALAN',
                  value:
                      '${result.left.survivingModules}/${match.playerBoard.modules.length}',
                  detail:
                      'Çekirdek ${result.left.coreHp.toStringAsFixed(0)}/${result.left.coreMaxHp.toStringAsFixed(0)}',
                  color: RelayColors.cyan,
                ),
              ];
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: columns == 1 ? 4.1 : 2.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: cards,
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('battle-star-card'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: RelayColors.background.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: RelayColors.violet.withValues(alpha: 0.42),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: RelayColors.violet),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SAVAŞIN YILDIZI',
                        style: TextStyle(
                          color: RelayColors.violet,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        analysis.starTitle,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        analysis.starDetail,
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
          ),
          const SizedBox(height: 12),
          Text(
            '${replay.events.length} savaş olayı • ${result.ticks} adım • doğrulama ${replay.checksum.substring(0, math.min(8, replay.checksum.length))}…',
            style: const TextStyle(color: RelayColors.muted, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

class RematchRecommendation {
  const RematchRecommendation({
    required this.title,
    required this.diagnosis,
    required this.experiment,
    required this.icon,
    required this.accent,
  });

  factory RematchRecommendation.fromAnalysis({
    required MatchResponse match,
    required ReplayResponse replay,
    required BattleAnalysis analysis,
  }) {
    final firstStarved = _firstTick(replay, 'energy_starved', side: 'left');
    final firstOverheat = _firstTick(replay, 'overheat', side: 'left');
    final lost = match.result.winner == 'right';
    if (analysis.playerStarved >= 2) {
      return RematchRecommendation(
        title: 'ENERJİ HATTI KOPTU',
        diagnosis:
            '${analysis.playerStarved} enerji açlığı${firstStarved == null ? '' : ' • ilk kesinti $firstStarved. adımda'} saldırı ritmini bozdu.',
        experiment:
            'Bataryayı jeneratör ile silahların arasına taşı; yüksek maliyetli iki silahı aynı hatta çalıştırma.',
        icon: Icons.battery_alert_outlined,
        accent: RelayColors.amber,
      );
    }
    if (analysis.playerOverheats >= 2) {
      return RematchRecommendation(
        title: 'ISI BİRİKTİ',
        diagnosis:
            '${analysis.playerOverheats} aşırı ısınma${firstOverheat == null ? '' : ' • ilki $firstOverheat. adımda'} devreyi susturdu.',
        experiment:
            'Soğutucuyu en sık ateş eden modüle komşu yerleştir veya ikinci ağır silahı daha serin bir hatla değiştir.',
        icon: Icons.device_thermostat,
        accent: RelayColors.coral,
      );
    }
    if (lost && analysis.playerShieldAbsorbed < analysis.enemyDamage * 0.18) {
      return const RematchRecommendation(
        title: 'ÇEKİRDEK AÇIKTA KALDI',
        diagnosis:
            'Savunma, rakibin baskısını karşılayacak kadar hasar ememedi.',
        experiment:
            'Kalkanı kesintisiz enerji alan kısa bir hatta bağla; Onarım modülünü en çok hedeflenen savunmanın yanına al.',
        icon: Icons.shield_outlined,
        accent: RelayColors.electricBlue,
      );
    }
    if (lost && analysis.playerDamage < analysis.enemyDamage * 0.82) {
      return const RematchRecommendation(
        title: 'BASKI YETERSİZ KALDI',
        diagnosis: 'Rakip, devrenden belirgin biçimde daha fazla hasar üretti.',
        experiment:
            'Güçlendiricinin okunu ana silaha çevir; saldırı modülünün enerji yolunu kısalt ve destek dışı boş bağlantıları kaldır.',
        icon: Icons.trending_up,
        accent: RelayColors.coral,
      );
    }
    if (match.result.winner == 'left') {
      return const RematchRecommendation(
        title: 'KAZANAN DÜZENİ SINIRLA',
        diagnosis:
            'Devren bu eşleşmeyi kazandı; şimdi dayanıklılığını ölçebilirsin.',
        experiment:
            'Aynı çekirdeği koruyup savaşın yıldızı dışındaki tek bir modülün yerini değiştir. Sonucun düzene mi parçaya mı bağlı olduğunu gör.',
        icon: Icons.science_outlined,
        accent: RelayColors.mint,
      );
    }
    return const RematchRecommendation(
      title: 'BERABERLİĞİ BOZ',
      diagnosis: 'İki devre karar ölçütlerinde birbirini dengeledi.',
      experiment:
          'Bir savunma modülünü saldırıya çevir veya Güçlendirici yönünü değiştirerek tek bir karar ölçütünde üstünlük kur.',
      icon: Icons.balance_outlined,
      accent: RelayColors.violet,
    );
  }

  final String title;
  final String diagnosis;
  final String experiment;
  final IconData icon;
  final Color accent;

  static int? _firstTick(
    ReplayResponse replay,
    String type, {
    required String side,
  }) {
    for (final event in replay.events) {
      if (event.type == type && event.side == side) return event.tick;
    }
    return null;
  }
}

class _RematchLabCard extends StatelessWidget {
  const _RematchLabCard({
    required this.recommendation,
    required this.onRematch,
  });

  final RematchRecommendation recommendation;
  final VoidCallback? onRematch;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('rematch-lab-card'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            recommendation.accent.withValues(alpha: 0.16),
            RelayColors.background.withValues(alpha: 0.58),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: recommendation.accent.withValues(alpha: 0.52),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: recommendation.accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    recommendation.icon,
                    color: recommendation.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RÖVANŞ LABORATUVARI',
                      style: TextStyle(
                        color: RelayColors.violet,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recommendation.title,
                      style: TextStyle(
                        color: recommendation.accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recommendation.diagnosis,
                      style: const TextStyle(
                        color: RelayColors.muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'DENEY: ${recommendation.experiment}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final action = FilledButton.icon(
            key: const ValueKey('rematch-lab-action'),
            onPressed: onRematch,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('DEVREYİ DÜZENLE'),
          );
          if (constraints.maxWidth < 660) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content,
                if (onRematch != null) ...[const SizedBox(height: 12), action],
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: content),
              if (onRematch != null) ...[const SizedBox(width: 16), action],
            ],
          );
        },
      ),
    );
  }
}

class BattleAnalysis {
  const BattleAnalysis({
    required this.playerDamage,
    required this.enemyDamage,
    required this.playerEnergy,
    required this.playerShieldAbsorbed,
    required this.enemyShieldAbsorbed,
    required this.playerRepair,
    required this.playerCooling,
    required this.playerOverheats,
    required this.enemyOverheats,
    required this.playerStarved,
    required this.decisionExplanation,
    required this.starTitle,
    required this.starDetail,
  });

  factory BattleAnalysis.fromMatch(
    MatchResponse match,
    ReplayResponse replay,
    List<ModuleSpec> specs,
  ) {
    var playerShield = 0.0;
    var enemyShield = 0.0;
    var playerRepair = 0.0;
    var playerCooling = 0.0;
    var playerOverheats = 0;
    var enemyOverheats = 0;
    var playerStarved = 0;
    final contribution = <String, double>{};
    final details = <String, String>{};
    final kindById = <String, ModuleKind>{
      for (final module in match.playerBoard.modules) module.id: module.kind,
    };
    final specByKind = {for (final spec in specs) spec.kind: spec};

    for (final event in replay.events) {
      final player = event.side == 'left';
      switch (event.type) {
        case 'attack':
        case 'core_damage':
          if (player) {
            contribution[event.actorId] =
                (contribution[event.actorId] ?? 0) + event.amount;
            details[event.actorId] =
                '${event.amount.toStringAsFixed(0)} son vuruş katkısı';
          }
          break;
        case 'shield_absorb':
          if (player) {
            enemyShield += event.amount;
          } else {
            playerShield += event.amount;
          }
          break;
        case 'repair':
          if (player) {
            playerRepair += event.amount;
            contribution[event.actorId] =
                (contribution[event.actorId] ?? 0) + event.amount * 0.85;
            details[event.actorId] =
                '${event.amount.toStringAsFixed(0)} onarım';
          }
          break;
        case 'cool':
          if (player) {
            playerCooling += event.amount;
            contribution[event.actorId] =
                (contribution[event.actorId] ?? 0) + event.amount * 0.45;
            details[event.actorId] =
                '${event.amount.toStringAsFixed(0)} ısı düşüşü';
          }
          break;
        case 'shield':
          if (player) {
            contribution[event.actorId] =
                (contribution[event.actorId] ?? 0) + event.amount * 0.55;
            details[event.actorId] =
                '${event.amount.toStringAsFixed(0)} kalkan üretimi';
          }
          break;
        case 'overheat':
          if (player) {
            playerOverheats += 1;
          } else {
            enemyOverheats += 1;
          }
          break;
        case 'energy_starved':
          if (player) {
            playerStarved += 1;
          }
          break;
      }
    }

    String starId = '';
    var starScore = -1.0;
    contribution.forEach((id, score) {
      if (score > starScore) {
        starScore = score;
        starId = id;
      }
    });
    final starKind = kindById[starId];
    final starName = starKind == null
        ? 'Devre Çekirdeği'
        : (specByKind[starKind]?.displayName ?? starKind.displayName);
    final starDetail = starId.isEmpty
        ? 'Dengeli takım katkısı'
        : (details[starId] ?? '${starScore.toStringAsFixed(0)} katkı puanı');

    return BattleAnalysis(
      playerDamage: match.result.left.totalDamage,
      enemyDamage: match.result.right.totalDamage,
      playerEnergy: match.result.left.energySpent,
      playerShieldAbsorbed: playerShield,
      enemyShieldAbsorbed: enemyShield,
      playerRepair: playerRepair,
      playerCooling: playerCooling,
      playerOverheats: playerOverheats,
      enemyOverheats: enemyOverheats,
      playerStarved: playerStarved,
      decisionExplanation: _decisionExplanation(match.result),
      starTitle: starName,
      starDetail: starDetail,
    );
  }

  final double playerDamage;
  final double enemyDamage;
  final double playerEnergy;
  final double playerShieldAbsorbed;
  final double enemyShieldAbsorbed;
  final double playerRepair;
  final double playerCooling;
  final int playerOverheats;
  final int enemyOverheats;
  final int playerStarved;
  final String decisionExplanation;
  final String starTitle;
  final String starDetail;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RelayColors.background.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RelayColors.muted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({
    required this.xp,
    required this.credits,
    this.seasonPoints,
  });
  final int xp;
  final int credits;
  final int? seasonPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RelayColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RelayColors.amber.withValues(alpha: 0.35)),
      ),
      child: Text(
        '+$xp XP • +$credits DK${seasonPoints == null ? '' : ' • +$seasonPoints SP'}',
        style: const TextStyle(
          color: RelayColors.amber,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

String _decisionExplanation(MatchResult result) {
  if (result.reason == 'core_destroyed') {
    return result.winner == 'left'
        ? 'Rakip çekirdeği yok edildi. Devren son darbeyi başarıyla tamamladı.'
        : 'Senin çekirdeğin yok edildi. Savunma hattı çekirdeği koruyamadı.';
  }
  if (result.reason == 'mutual_core_destruction') {
    return 'İki çekirdek aynı savaş adımında yok edildi.';
  }
  if (result.decision.criterion == 'exact_draw') {
    return 'Süre sonundaki bütün karar ölçütleri eşit kaldı.';
  }
  DecisionMetric? metric;
  for (final item in result.decision.metrics) {
    if (item.key == result.decision.criterion) {
      metric = item;
      break;
    }
  }
  if (metric == null) return 'Sunucu süre sonu karşılaştırmasını uyguladı.';
  final label = switch (metric.key) {
    'surviving_modules' => 'hayatta kalan modül sayısı',
    'total_damage' => 'toplam hasar',
    'module_hp_ratio' => 'modül can oranı',
    'core_hp_ratio' => 'çekirdek can oranı',
    'damage_efficiency' => 'hasar/enerji verimliliği',
    'total_heat' => 'toplam ısı',
    _ => metric.key,
  };
  return 'Süre sonu kararı: $label belirleyici oldu.';
}
