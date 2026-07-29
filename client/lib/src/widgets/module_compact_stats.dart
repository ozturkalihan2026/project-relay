import '../models/relay_models.dart';

class ModuleCompactStat {
  const ModuleCompactStat({
    required this.shortLabel,
    required this.fullLabel,
  });

  final String shortLabel;
  final String fullLabel;
}

List<ModuleCompactStat> moduleCompactStats(ModuleSpec spec) {
  return [
    ModuleCompactStat(
      shortLabel: 'C ${_number(spec.maxHp)}',
      fullLabel: 'Can ${_number(spec.maxHp)}',
    ),
    _roleStat(spec),
  ];
}

ModuleCompactStat _roleStat(ModuleSpec spec) {
  return switch (spec.kind) {
    ModuleKind.generator => ModuleCompactStat(
        shortLabel: 'E +${_number(spec.energyOutput)}',
        fullLabel: 'Enerji +${_number(spec.energyOutput)}',
      ),
    ModuleKind.battery => ModuleCompactStat(
        shortLabel: 'D ${_number(spec.batteryCapacity)}',
        fullLabel: 'Depo ${_number(spec.batteryCapacity)}',
      ),
    ModuleKind.laser || ModuleKind.pulseCannon => ModuleCompactStat(
        shortLabel: 'H ${_number(spec.damage)}',
        fullLabel: 'Hasar ${_number(spec.damage)}',
      ),
    ModuleKind.shield => ModuleCompactStat(
        shortLabel: 'K ${_number(spec.shield)}',
        fullLabel: 'Kalkan ${_number(spec.shield)}',
      ),
    ModuleKind.cooler => ModuleCompactStat(
        shortLabel: 'S ${_number(spec.cooling)}',
        fullLabel: 'Soğutma ${_number(spec.cooling)}',
      ),
    ModuleKind.amplifier => const ModuleCompactStat(
        shortLabel: '×1,35',
        fullLabel: 'Ok yönündeki komşunun hasarı ×1,35',
      ),
    ModuleKind.repair => ModuleCompactStat(
        shortLabel: '+${_number(spec.repair)}',
        fullLabel: 'Onarım +${_number(spec.repair)}',
      ),
  };
}

String _number(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
