import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../widgets/module_visuals.dart';

@immutable
class BoardVisualTheme {
  const BoardVisualTheme({
    required this.id,
    required this.background,
    required this.cell,
    required this.emptyCell,
    required this.border,
    required this.grid,
    required this.trace,
    required this.traceMuted,
    required this.core,
    required this.coreSurface,
    required this.gate,
  });

  const BoardVisualTheme.midnight()
      : this(
          id: 'board_midnight_grid',
          background: const Color(0xFF0B1C24),
          cell: const Color(0xFF112730),
          emptyCell: const Color(0x99112730),
          border: const Color(0xFF2B5969),
          grid: const Color(0x222F879D),
          trace: const Color(0xFF38E8FF),
          traceMuted: const Color(0xFF3C6976),
          core: const Color(0xFF38E8FF),
          coreSurface: const Color(0xF20A2028),
          gate: const Color(0xFFFFB84A),
        );

  final String id;
  final Color background;
  final Color cell;
  final Color emptyCell;
  final Color border;
  final Color grid;
  final Color trace;
  final Color traceMuted;
  final Color core;
  final Color coreSurface;
  final Color gate;

  static BoardVisualTheme fromId(String id) => switch (id) {
        'board_ion_storm' => const BoardVisualTheme(
            id: 'board_ion_storm',
            background: Color(0xFF100E2B),
            cell: Color(0xFF1A1942),
            emptyCell: Color(0x991B1A48),
            border: Color(0xFF8B7CFF),
            grid: Color(0x335C53C7),
            trace: Color(0xFF76B8FF),
            traceMuted: Color(0xFF55517E),
            core: Color(0xFFB8ABFF),
            coreSurface: Color(0xF2161235),
            gate: Color(0xFFFFD166),
          ),
        'board_mint_matrix' => const BoardVisualTheme(
            id: 'board_mint_matrix',
            background: Color(0xFF061E19),
            cell: Color(0xFF0D3027),
            emptyCell: Color(0x99113930),
            border: Color(0xFF39DDA5),
            grid: Color(0x3326A77E),
            trace: Color(0xFF63F5C7),
            traceMuted: Color(0xFF316B5D),
            core: Color(0xFF9BFFDB),
            coreSurface: Color(0xF2082921),
            gate: Color(0xFFFFD166),
          ),
        _ => const BoardVisualTheme.midnight(),
      };
}

@immutable
class ModuleVisualTheme {
  const ModuleVisualTheme({
    required this.id,
    required this.accent,
    required this.attack,
  });

  const ModuleVisualTheme.neonCyan()
      : this(
          id: 'module_neon_cyan',
          accent: const Color(0xFF38E8FF),
          attack: const Color(0xFFFF6B6B),
        );

  final String id;
  final Color accent;
  final Color attack;

  Color moduleColorFor(ModuleKind kind) {
    return Color.lerp(moduleColor(kind), accent, 0.28)!;
  }

  static ModuleVisualTheme fromId(String id) => switch (id) {
        'module_coral_pulse' => const ModuleVisualTheme(
            id: 'module_coral_pulse',
            accent: Color(0xFFFF6B6B),
            attack: Color(0xFFFF8B73),
          ),
        'module_mint_flux' => const ModuleVisualTheme(
            id: 'module_mint_flux',
            accent: Color(0xFF63F5C7),
            attack: Color(0xFF63F5C7),
          ),
        _ => const ModuleVisualTheme.neonCyan(),
      };
}


@immutable
class ProfileFrameVisualTheme {
  const ProfileFrameVisualTheme({
    required this.id,
    required this.accent,
    required this.glow,
    required this.icon,
  });

  const ProfileFrameVisualTheme.circuitBasic()
      : this(
          id: 'frame_circuit_basic',
          accent: const Color(0xFF38E8FF),
          glow: const Color(0x2238E8FF),
          icon: Icons.person_outline,
        );

  final String id;
  final Color accent;
  final Color glow;
  final IconData icon;

  static ProfileFrameVisualTheme fromId(String id) => switch (id) {
        'frame_ranked_gold' => const ProfileFrameVisualTheme(
            id: 'frame_ranked_gold',
            accent: Color(0xFFFFD166),
            glow: Color(0x44FFD166),
            icon: Icons.workspace_premium_outlined,
          ),
        'frame_boss_core' => const ProfileFrameVisualTheme(
            id: 'frame_boss_core',
            accent: Color(0xFFFF6B6B),
            glow: Color(0x44FF6B6B),
            icon: Icons.hub_outlined,
          ),
        _ => const ProfileFrameVisualTheme.circuitBasic(),
      };
}

@immutable
class EquippedVisuals {
  const EquippedVisuals({
    required this.board,
    required this.modules,
    this.profile = const ProfileFrameVisualTheme.circuitBasic(),
  });

  const EquippedVisuals.defaults()
      : board = const BoardVisualTheme.midnight(),
        modules = const ModuleVisualTheme.neonCyan(),
        profile = const ProfileFrameVisualTheme.circuitBasic();

  factory EquippedVisuals.fromCollection(CollectionSnapshot? snapshot) {
    if (snapshot == null) return const EquippedVisuals.defaults();
    return EquippedVisuals(
      board: BoardVisualTheme.fromId(snapshot.equippedBoardThemeId),
      modules: ModuleVisualTheme.fromId(snapshot.equippedModuleSkinId),
      profile: ProfileFrameVisualTheme.fromId(
        snapshot.equippedProfileFrameId,
      ),
    );
  }

  final BoardVisualTheme board;
  final ModuleVisualTheme modules;
  final ProfileFrameVisualTheme profile;
}

class CosmeticVisualScope extends InheritedWidget {
  const CosmeticVisualScope({
    required this.visuals,
    required super.child,
    super.key,
  });

  final EquippedVisuals visuals;

  static EquippedVisuals of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<CosmeticVisualScope>()
            ?.visuals ??
        const EquippedVisuals.defaults();
  }

  @override
  bool updateShouldNotify(CosmeticVisualScope oldWidget) =>
      visuals.board.id != oldWidget.visuals.board.id ||
      visuals.modules.id != oldWidget.visuals.modules.id ||
      visuals.profile.id != oldWidget.visuals.profile.id;
}
