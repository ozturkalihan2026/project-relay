import 'package:flutter/material.dart';

import '../game/replay_game.dart';
import '../models/relay_models.dart';
import '../theme/cosmetic_visuals.dart';
import 'circuit_board.dart';

/// Shared battle board pair used by both career and online live battle screens.
///
/// Renders the player (left) and opponent (right) [CircuitBoard]s positioned
/// via [ReplayStageGeometry] inside a [Stack]. The right board is always
/// non-interactive. Additional [extraChildren] (e.g. attack overlay) can be
/// stacked on top.
class BattleCircuitBoards extends StatelessWidget {
  const BattleCircuitBoards({
    required this.size,
    required this.playerBoard,
    required this.opponentBoard,
    required this.frame,
    required this.specs,
    required this.visuals,
    this.onModuleDropped,
    this.interventionUsable = false,
    this.extraChildren = const [],
    super.key,
  });

  final Size size;
  final BoardDraft playerBoard;
  final BoardDraft opponentBoard;
  final ReplayStateFrame frame;
  final Map<ModuleKind, ModuleSpec> specs;
  final EquippedVisuals visuals;
  final ModuleDropCallback? onModuleDropped;
  final bool interventionUsable;
  final List<Widget> extraChildren;

  @override
  Widget build(BuildContext context) {
    final leftRect = ReplayStageGeometry.leftBoard(size);
    final rightRect = ReplayStageGeometry.rightBoard(size);

    final playerPlacements = {
      for (final module in playerBoard.modules) module.cellIndex: module,
    };
    final opponentPlacements = {
      for (final module in opponentBoard.modules) module.cellIndex: module,
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fromRect(
          rect: leftRect,
          child: CircuitBoard(
            placements: playerPlacements,
            specs: specs,
            poweredIds: {
              for (final m in frame.left.modules)
                if (m.powered && m.hp > 0) m.id,
            },
            moduleHp: {
              for (final m in frame.left.modules) m.id: m.hp,
            },
            moduleMaxHp: {
              for (final m in frame.left.modules) m.id: m.maxHp,
            },
            validationVisible: false,
            selectedCell: null,
            onCellTap: (_) {},
            onModuleDropped: onModuleDropped ?? (_, _) {},
            onRotateModule: (_) {},
            visuals: visuals,
            presentation3d: true,
            moduleDraggingEnabled: interventionUsable,
            keyPrefix: 'left',
          ),
        ),
        Positioned.fromRect(
          rect: rightRect,
          child: IgnorePointer(
            child: CircuitBoard(
              placements: opponentPlacements,
              specs: specs,
              poweredIds: {
                for (final m in frame.right.modules)
                  if (m.powered && m.hp > 0) m.id,
              },
              moduleHp: {
                for (final m in frame.right.modules) m.id: m.hp,
              },
              moduleMaxHp: {
                for (final m in frame.right.modules) m.id: m.maxHp,
              },
              validationVisible: false,
              selectedCell: null,
              onCellTap: (_) {},
              onModuleDropped: (_, _) {},
              onRotateModule: (_) {},
              visuals: visuals,
              presentation3d: true,
              moduleDraggingEnabled: false,
              keyPrefix: 'right',
            ),
          ),
        ),
        ...extraChildren,
      ],
    );
  }
}
