import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/relay_theme.dart';

IconData moduleIcon(ModuleKind kind) => switch (kind) {
      ModuleKind.generator => Icons.bolt,
      ModuleKind.battery => Icons.battery_charging_full,
      ModuleKind.laser => Icons.flash_on,
      ModuleKind.pulseCannon => Icons.radio_button_checked,
      ModuleKind.shield => Icons.shield_outlined,
      ModuleKind.cooler => Icons.ac_unit,
      ModuleKind.amplifier => Icons.call_split,
      ModuleKind.repair => Icons.build_circle_outlined,
    };

Color moduleColor(ModuleKind kind) => switch (kind) {
      ModuleKind.generator => RelayColors.amber,
      ModuleKind.battery => RelayColors.mint,
      ModuleKind.laser => RelayColors.coral,
      ModuleKind.pulseCannon => const Color(0xFFFF8C42),
      ModuleKind.shield => const Color(0xFF74A7FF),
      ModuleKind.cooler => RelayColors.cyan,
      ModuleKind.amplifier => const Color(0xFFB48CFF),
      ModuleKind.repair => const Color(0xFF62D89A),
    };

IconData directionIcon(RelayDirection direction) => switch (direction) {
      RelayDirection.north => Icons.arrow_upward,
      RelayDirection.east => Icons.arrow_forward,
      RelayDirection.south => Icons.arrow_downward,
      RelayDirection.west => Icons.arrow_back,
    };

bool usesConnectionDirectionArrow(ModuleKind kind) => switch (kind) {
      ModuleKind.laser ||
      ModuleKind.pulseCannon ||
      ModuleKind.shield ||
      ModuleKind.cooler ||
      ModuleKind.repair => true,
      _ => false,
    };

RelayDirection moduleDisplayDirection(
  ModuleKind kind,
  RelayDirection orientation,
) {
  return usesConnectionDirectionArrow(kind) ? orientation.opposite : orientation;
}

String moduleDirectionTooltip(
  ModuleKind kind,
  RelayDirection orientation,
) {
  final direction = moduleDisplayDirection(kind, orientation);
  return switch (kind) {
    ModuleKind.generator => 'Jeneratör çekirdeğe dönük kalır',
    ModuleKind.battery =>
      'Dört yönlü kavşak • yalnız kullanılabilir uçlar gösterilir',
    ModuleKind.amplifier => 'Etki yönü: ${direction.displayName}',
    _ => 'Enerji bağlantısı: ${direction.displayName}',
  };
}

