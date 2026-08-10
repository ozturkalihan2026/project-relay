import '../models/relay_models.dart';

enum BattleWeapon { laser, pulseCannon, generic }

enum BattleImpact { light, heavy, critical }

class BattleVisualCue {
  const BattleVisualCue({
    required this.weapon,
    required this.impact,
    required this.chargeFraction,
    required this.travelFraction,
    required this.impactFraction,
  });

  final BattleWeapon weapon;
  final BattleImpact impact;
  final double chargeFraction;
  final double travelFraction;
  final double impactFraction;
}

abstract final class BattleVisualDirector {
  static BattleVisualCue cueFor(BattleEvent event, MatchResponse match) {
    final kind = _kindForActor(event.actorId, match);
    final weapon = switch (kind) {
      ModuleKind.laser => BattleWeapon.laser,
      ModuleKind.pulseCannon => BattleWeapon.pulseCannon,
      _ => BattleWeapon.generic,
    };
    final impact = event.type == 'core_damage'
        ? BattleImpact.critical
        : weapon == BattleWeapon.pulseCannon || event.type == 'destroyed'
            ? BattleImpact.heavy
            : BattleImpact.light;
    return BattleVisualCue(
      weapon: weapon,
      impact: impact,
      chargeFraction: weapon == BattleWeapon.pulseCannon ? 0.24 : 0.18,
      travelFraction: weapon == BattleWeapon.pulseCannon ? 0.52 : 0.34,
      impactFraction: weapon == BattleWeapon.pulseCannon ? 0.24 : 0.48,
    );
  }

  static ModuleKind? _kindForActor(String id, MatchResponse match) {
    for (final module in match.playerBoard.modules) {
      if (module.id == id) return module.kind;
    }
    for (final module in match.opponentBoard.modules) {
      if (module.id == id) return module.kind;
    }
    return null;
  }
}
