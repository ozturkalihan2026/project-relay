import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/models/relay_models.dart';
import 'package:project_relay_client/src/widgets/module_compact_stats.dart';

void main() {
  test('sekiz modül için can ve role özgü kompakt değeri üretir', () {
    final expectations = <ModuleKind, String>{
      ModuleKind.generator: 'E +8',
      ModuleKind.battery: 'D 20',
      ModuleKind.laser: 'H 8',
      ModuleKind.pulseCannon: 'H 16',
      ModuleKind.shield: 'K 14',
      ModuleKind.cooler: 'S 12',
      ModuleKind.amplifier: '×1,35',
      ModuleKind.repair: '+11',
    };

    for (final entry in expectations.entries) {
      final stats = moduleCompactStats(_spec(entry.key));
      expect(stats, hasLength(2));
      expect(stats.first.shortLabel, startsWith('C '));
      expect(stats.last.shortLabel, entry.value);
    }
  });
}

ModuleSpec _spec(ModuleKind kind) {
  return ModuleSpec(
    kind: kind,
    displayName: kind.displayName,
    description: 'Test modülü',
    maxHp: kind == ModuleKind.generator ? 52 : 30,
    ports: const {RelayDirection.west},
    energyOutput: kind == ModuleKind.generator ? 8 : 0,
    batteryCapacity: kind == ModuleKind.battery ? 20 : 0,
    energyCost: 0,
    cooldownTicks: 0,
    heatPerAction: 0,
    damage: switch (kind) {
      ModuleKind.laser => 8,
      ModuleKind.pulseCannon => 16,
      _ => 0,
    },
    shield: kind == ModuleKind.shield ? 14 : 0,
    cooling: kind == ModuleKind.cooler ? 12 : 0,
    repair: kind == ModuleKind.repair ? 11 : 0,
    threat: 0,
  );
}
