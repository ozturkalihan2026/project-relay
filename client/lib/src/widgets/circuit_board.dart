import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/cosmetic_visuals.dart';
import '../theme/relay_theme.dart';
import 'module_compact_stats.dart';
import 'module_visuals.dart';
import 'relay_emblem.dart';

typedef ModuleDropCallback = void Function(int cellIndex, ModuleDragData data);

class CircuitBoard extends StatelessWidget {
  const CircuitBoard({
    required this.placements,
    required this.specs,
    required this.poweredIds,
    required this.validationVisible,
    required this.selectedCell,
    required this.onCellTap,
    required this.onModuleDropped,
    required this.onRotateModule,
    this.visuals = const EquippedVisuals.defaults(),
    this.presentation3d = false,
    this.upgradeBranches = const {},
    super.key,
  });

  final Map<int, ModulePlacement> placements;
  final Map<ModuleKind, ModuleSpec> specs;
  final Set<String> poweredIds;
  final bool validationVisible;
  final int? selectedCell;
  final ValueChanged<int> onCellTap;
  final ModuleDropCallback onModuleDropped;
  final ValueChanged<int> onRotateModule;
  final EquippedVisuals visuals;
  final bool presentation3d;
  final Map<String, String> upgradeBranches;

  @override
  Widget build(BuildContext context) {
    final boardTheme = visuals.board;
    final board = CosmeticVisualScope(
      visuals: visuals,
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          key: ValueKey('circuit-board-theme-${boardTheme.id}'),
          decoration: BoxDecoration(
            color: boardTheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: boardTheme.border, width: 2),
            boxShadow: [
              BoxShadow(
                color: boardTheme.core.withValues(alpha: 0.22),
                blurRadius: 26,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: CustomPaint(
                  painter: _CircuitTracePainter(
                    placements: placements,
                    specs: specs,
                    poweredIds: poweredIds,
                    visuals: visuals,
                  ),
                ),
              ),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                clipBehavior: Clip.none,
                padding: const EdgeInsets.all(4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  if (isCoreCell(index)) {
                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: _CoreCellBackdrop(
                        cellIndex: index,
                        onTap: () => onCellTap(index),
                      ),
                    );
                  }
                  final placement = placements[index];
                  return Padding(
                    padding: const EdgeInsets.all(4),
                    child: _CircuitCell(
                      cellIndex: index,
                      coreGate: isCoreGate(index),
                      placement: placement,
                      spec: placement == null ? null : specs[placement.kind],
                      selected: selectedCell == index,
                      validationVisible: validationVisible,
                      powered:
                          placement != null &&
                          poweredIds.contains(placement.id),
                      onTap: () => onCellTap(index),
                      onModuleDropped: (data) => onModuleDropped(index, data),
                      onRotate: placement?.kind == ModuleKind.amplifier
                          ? () => onRotateModule(index)
                          : null,
                      raised: presentation3d,
                      upgradeBranch: placement == null
                          ? null
                          : upgradeBranches[placement.id],
                    ),
                  );
                },
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _CircuitFlowPainter(
                    placements: placements,
                    specs: specs,
                    poweredIds: poweredIds,
                    visuals: visuals,
                  ),
                ),
              ),
              IgnorePointer(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.48,
                    heightFactor: 0.48,
                    child: _CoreHub(raised: presentation3d),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!presentation3d) return board;
    return _PreparationStageShell(boardTheme: boardTheme, child: board);
  }
}

class _PreparationStageShell extends StatelessWidget {
  const _PreparationStageShell({required this.boardTheme, required this.child});

  final BoardVisualTheme boardTheme;
  final Widget child;

  static const double perspectiveDepth = 0.00155;
  static const double deckTilt = -0.32;
  static const double deckYaw = 0.012;

  Matrix4 _deckTransform() {
    return Matrix4.identity()
      ..setEntry(3, 2, perspectiveDepth)
      ..rotateX(deckTilt)
      ..rotateZ(deckYaw);
  }

  Widget _deckLayer({
    required Color color,
    required double depth,
    required double opacity,
  }) {
    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, depth),
        child: Transform(
          alignment: Alignment.center,
          transform: _deckTransform(),
          transformHitTests: false,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(
                    boardTheme.core.withValues(alpha: opacity),
                    color,
                  ),
                  color,
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: boardTheme.core.withValues(alpha: 0.24 + opacity),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 48),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 34,
              right: 20,
              bottom: -22,
              height: 64,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: RadialGradient(
                      colors: [
                        boardTheme.core.withValues(alpha: 0.24),
                        const Color(0x99000000),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.52, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: _deckLayer(
                color: const Color(0xFF06131A),
                depth: 17,
                opacity: 0.09,
              ),
            ),
            Positioned.fill(
              child: Transform.translate(
                offset: const Offset(0, 4),
                child: Transform(
                  alignment: Alignment.center,
                  transform: _deckTransform(),
                  transformHitTests: true,
                  child: child,
                ),
              ),
            ),
            Positioned(
              left: 30,
              right: 30,
              bottom: -7,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DeckFastener(color: boardTheme.core),
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              boardTheme.core.withValues(alpha: 0.62),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    _DeckFastener(color: boardTheme.core),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckFastener extends StatelessWidget {
  const _DeckFastener({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF09171D),
        border: Border.all(color: color.withValues(alpha: 0.64)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.34), blurRadius: 8),
        ],
      ),
      child: const SizedBox.square(dimension: 8),
    );
  }
}

class _RaisedModuleShell extends StatelessWidget {
  const _RaisedModuleShell({
    required this.accent,
    required this.lifted,
    required this.placementId,
    required this.child,
  });

  final Color accent;
  final bool lifted;
  final String placementId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ModuleChassis(
      accent: accent,
      lifted: lifted,
      animateSeat: true,
      animationKey: ValueKey('module-seat-$placementId'),
      child: child,
    );
  }
}

class _CircuitCell extends StatelessWidget {
  const _CircuitCell({
    required this.cellIndex,
    required this.coreGate,
    required this.placement,
    required this.spec,
    required this.selected,
    required this.validationVisible,
    required this.powered,
    required this.onTap,
    required this.onModuleDropped,
    required this.onRotate,
    required this.raised,
    required this.upgradeBranch,
  });

  final int cellIndex;
  final bool coreGate;
  final ModulePlacement? placement;
  final ModuleSpec? spec;
  final bool selected;
  final bool validationVisible;
  final bool powered;
  final VoidCallback onTap;
  final ValueChanged<ModuleDragData> onModuleDropped;
  final VoidCallback? onRotate;
  final bool raised;
  final String? upgradeBranch;

  @override
  Widget build(BuildContext context) {
    final visuals = CosmeticVisualScope.of(context);
    final module = placement;
    final color = module == null
        ? RelayColors.muted
        : visuals.modules.moduleColorFor(module.kind);
    final compactStats = spec == null
        ? const <ModuleCompactStat>[]
        : moduleCompactStats(spec!);
    final statSemantics = compactStats.map((stat) => stat.fullLabel).join(', ');
    return DragTarget<ModuleDragData>(
      hitTestBehavior: HitTestBehavior.opaque,
      onWillAcceptWithDetails: (details) =>
          details.data.sourceCell != cellIndex,
      onAcceptWithDetails: (details) => onModuleDropped(details.data),
      builder: (context, candidateData, rejectedData) {
        final candidate = candidateData.isEmpty ? null : candidateData.first;
        final dropActive = candidate != null;
        final dropLabel = switch ((candidate?.source, module)) {
          (ModuleDragSource.palette, null) => 'YERLEŞTİR',
          (ModuleDragSource.palette, _) => 'DEĞİŞTİR',
          (ModuleDragSource.board, null) => 'TAŞI',
          (ModuleDragSource.board, _) => 'YER DEĞİŞTİR',
          _ => '',
        };
        final borderColor = dropActive
            ? module == null
                  ? RelayColors.cyan
                  : RelayColors.amber
            : selected
            ? RelayColors.amber
            : module == null || !validationVisible
            ? coreGate
                  ? visuals.board.gate
                  : visuals.board.border.withValues(alpha: 0.72)
            : powered
            ? visuals.modules.accent
            : RelayColors.coral;
        final upgradeColor = upgradeBranch == 'overclock'
            ? RelayColors.amber
            : upgradeBranch == 'efficient'
            ? RelayColors.mint
            : null;

        final cell = Semantics(
          key: ValueKey('circuit-cell-$cellIndex'),
          button: true,
          label: module == null
              ? coreGate
                    ? 'Boş çekirdek kapısı, modül bırakılabilir'
                    : 'Boş devre hücresi, modül bırakılabilir'
              : module.kind == ModuleKind.battery
              ? '${spec?.displayName ?? module.kind.displayName}, '
                    'dört yönlü bağlantı, $statSemantics'
              : '${spec?.displayName ?? module.kind.displayName}, '
                    '${moduleDisplayDirection(module.kind, module.orientation).shortLabel} '
                    '${usesConnectionDirectionArrow(module.kind) ? 'bağlantı' : 'etki'} yönü, '
                    '$statSemantics',
          child: AnimatedScale(
            scale: dropActive ? 1.035 : 1,
            duration: const Duration(milliseconds: 120),
            child: Material(
              color: dropActive
                  ? RelayColors.cyan.withValues(alpha: 0.16)
                  : module == null
                  ? visuals.board.emptyCell
                  : color.withValues(alpha: 0.17),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: dropActive || selected ? 3 : 1.5,
                    ),
                    boxShadow: dropActive
                        ? const [
                            BoxShadow(
                              color: Color(0x9938E8FF),
                              blurRadius: 22,
                              spreadRadius: 1,
                              offset: Offset(0, 6),
                            ),
                          ]
                        : module != null && upgradeColor != null
                        ? [
                            BoxShadow(
                              color: upgradeColor.withValues(alpha: 0.52),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ]
                        : module != null && raised
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: module == null
                      ? Center(
                          child: candidate == null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      coreGate ? Icons.hub_outlined : Icons.add,
                                      color: coreGate
                                          ? RelayColors.amber.withValues(
                                              alpha: 0.72,
                                            )
                                          : const Color(0x774C7785),
                                      size: coreGate ? 20 : 22,
                                    ),
                                    if (coreGate)
                                      const Text(
                                        'KAPI',
                                        style: TextStyle(
                                          color: RelayColors.amber,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ModuleGlyph(
                                      kind: candidate.kind,
                                      color: visuals.modules.moduleColorFor(
                                        candidate.kind,
                                      ),
                                      size: 28,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      dropLabel,
                                      style: const TextStyle(
                                        color: RelayColors.amber,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.9,
                                      ),
                                    ),
                                  ],
                                ),
                        )
                      : Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: EdgeInsets.all(coreGate ? 20 : 16),
                                child: Center(
                                  child: ModuleGlyph(
                                    kind: module.kind,
                                    key: ValueKey('module-glyph-${module.id}'),
                                    color: color,
                                    size: coreGate ? 34 : 44,
                                  ),
                                ),
                              ),
                            ),
                            if (module.kind == ModuleKind.amplifier)
                              Positioned(
                                right: 5,
                                top: 5,
                                child: Tooltip(
                                  message: 'Güçlendirici etki yönü',
                                  child: Icon(
                                    directionIcon(module.orientation),
                                    key: ValueKey(
                                      'module-direction-$cellIndex',
                                    ),
                                    color: RelayColors.violet,
                                    size: 15,
                                  ),
                                ),
                              ),
                            if (upgradeColor != null)
                              Positioned(
                                left: 5,
                                bottom: 5,
                                child: Container(
                                  key: ValueKey('module-upgrade-${module.id}'),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: RelayColors.background.withValues(
                                      alpha: 0.88,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: upgradeColor),
                                  ),
                                  child: Icon(
                                    upgradeBranch == 'overclock'
                                        ? Icons.bolt
                                        : Icons.eco_outlined,
                                    color: upgradeColor,
                                    size: 13,
                                  ),
                                ),
                              ),
                            if (onRotate != null &&
                                module.kind == ModuleKind.amplifier)
                              Positioned(
                                left: 4,
                                top: 4,
                                child: SizedBox.square(
                                  dimension: 28,
                                  child: IconButton.filled(
                                    key: ValueKey('rotate-module-$cellIndex'),
                                    tooltip: '90° döndür',
                                    padding: EdgeInsets.zero,
                                    onPressed: onRotate,
                                    icon: const Icon(
                                      Icons.rotate_right,
                                      size: 17,
                                    ),
                                  ),
                                ),
                              ),
                            if (spec != null)
                              for (final port in usableBoardPorts(
                                module,
                                spec!.worldPorts(module.orientation),
                              ))
                                _PortMarker(
                                  direction: port,
                                  energized: powered,
                                ),
                            if (validationVisible)
                              Positioned(
                                right: 5,
                                top: 24,
                                child: Icon(
                                  powered ? Icons.bolt : Icons.link_off,
                                  color: powered
                                      ? RelayColors.cyan
                                      : RelayColors.coral,
                                  size: 15,
                                ),
                              ),
                            if (coreGate)
                              const Positioned(
                                left: 5,
                                right: 5,
                                bottom: 4,
                                child: Text(
                                  'ÇEKİRDEK KAPISI',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: RelayColors.amber,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            if (dropActive)
                              Positioned(
                                left: 4,
                                right: 4,
                                bottom: 4,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xE6122730),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      dropLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: RelayColors.amber,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
        final presentedCell = raised && module != null
            ? _RaisedModuleShell(
                accent: color,
                lifted: dropActive,
                placementId: module.id,
                child: cell,
              )
            : cell;
        if (module == null) {
          return cell;
        }
        return Draggable<ModuleDragData>(
          data: ModuleDragData.board(kind: module.kind, cellIndex: cellIndex),
          maxSimultaneousDrags: 1,
          onDragStarted: onTap,
          feedback: _BoardDragFeedback(
            placement: module,
            displayName: spec?.displayName ?? module.kind.displayName,
          ),
          childWhenDragging: Opacity(opacity: 0.24, child: presentedCell),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: presentedCell,
          ),
        );
      },
    );
  }
}

class _CoreCellBackdrop extends StatelessWidget {
  const _CoreCellBackdrop({required this.cellIndex, required this.onTap});

  final int cellIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visuals = CosmeticVisualScope.of(context);
    return Semantics(
      key: ValueKey('circuit-cell-$cellIndex'),
      button: true,
      label: 'Pasif çekirdek hücresi',
      child: Material(
        color: visuals.board.cell,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: visuals.board.core.withValues(alpha: 0.34),
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _CoreHub extends StatelessWidget {
  const _CoreHub({required this.raised});

  final bool raised;

  @override
  Widget build(BuildContext context) {
    final visuals = CosmeticVisualScope.of(context);
    final hub = DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            visuals.board.core.withValues(alpha: 0.48),
            visuals.board.coreSurface,
            visuals.board.cell,
          ],
          stops: const [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: visuals.board.core.withValues(alpha: 0.90),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: visuals.board.core.withValues(alpha: 0.34),
            blurRadius: 30,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: RelayColors.violet.withValues(alpha: 0.14),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: visuals.board.core.withValues(alpha: 0.22),
              ),
            ),
          ),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: visuals.board.core.withValues(alpha: 0.08),
              border: Border.all(
                color: visuals.board.core.withValues(alpha: 0.52),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: visuals.board.core.withValues(alpha: 0.20),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          RelayEmblem(
            key: const ValueKey('board-core-emblem'),
            size: 92,
            accent: visuals.board.core,
            secondary: RelayColors.violet,
          ),
          for (final alignment in const [
            Alignment(-0.5, -1),
            Alignment(1, -0.5),
            Alignment(0.5, 1),
            Alignment(-1, 0.5),
          ])
            Align(
              alignment: alignment,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: visuals.board.gate,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: RelayColors.white.withValues(alpha: 0.55),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: visuals.board.gate.withValues(alpha: 0.72),
                      blurRadius: 11,
                    ),
                  ],
                ),
                child: const SizedBox(width: 11, height: 11),
              ),
            ),
        ],
      ),
    );
    if (!raised) return hub;
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          top: 9,
          bottom: -5,
          left: 3,
          right: 3,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF061116),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: visuals.board.core.withValues(alpha: 0.36),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 18,
                    offset: Offset(0, 11),
                  ),
                ],
              ),
            ),
          ),
        ),
        Transform.translate(offset: const Offset(0, -11), child: hub),
      ],
    );
  }
}

class _PortMarker extends StatelessWidget {
  const _PortMarker({required this.direction, required this.energized});

  final RelayDirection direction;
  final bool energized;

  @override
  Widget build(BuildContext context) {
    final position = switch (direction) {
      RelayDirection.north => const {'top': -1.0, 'left': 0.0, 'right': 0.0},
      RelayDirection.east => const {'right': -1.0, 'top': 0.0, 'bottom': 0.0},
      RelayDirection.south => const {'bottom': -1.0, 'left': 0.0, 'right': 0.0},
      RelayDirection.west => const {'left': -1.0, 'top': 0.0, 'bottom': 0.0},
    };
    return Positioned(
      top: position['top'],
      right: position['right'],
      bottom: position['bottom'],
      left: position['left'],
      child: Align(
        alignment: Alignment.center,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: energized
                ? CosmeticVisualScope.of(context).modules.accent
                : const Color(0xFF7896A0),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF07161C), width: 1.5),
            boxShadow: energized
                ? [
                    BoxShadow(
                      color: CosmeticVisualScope.of(
                        context,
                      ).modules.accent.withValues(alpha: 0.6),
                      blurRadius: 7,
                    ),
                  ]
                : null,
          ),
          child: const SizedBox(width: 9, height: 9),
        ),
      ),
    );
  }
}

class _BoardDragFeedback extends StatelessWidget {
  const _BoardDragFeedback({
    required this.placement,
    required this.displayName,
  });

  final ModulePlacement placement;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final color = moduleColor(placement.kind);
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 9,
            bottom: -5,
            left: 4,
            right: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF050E13),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.45)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xCC000000),
                    blurRadius: 22,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xF2112730),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.48),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ModuleGlyph(kind: placement.kind, color: color, size: 25),
                    const SizedBox(width: 9),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          'TAŞI / YER DEĞİŞTİR',
                          style: TextStyle(
                            color: RelayColors.cyan,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class CircuitTraceGeometry {
  static const double gridPadding = 4;
  static const double cellPadding = 4;
  static const double modulePortDiameter = 9;
  static const double modulePortEdgeOffset = -1;
  static const double coreScale = 0.48;
  static const double corePortDiameter = 10;

  static Offset modulePortAnchor(
    Size size,
    ModulePlacement module,
    RelayDirection direction,
  ) {
    final cellWidth = (size.width - gridPadding * 2) / relayBoardSize;
    final cellHeight = (size.height - gridPadding * 2) / relayBoardSize;
    final center = Offset(
      gridPadding + (module.column + 0.5) * cellWidth,
      gridPadding + (module.row + 0.5) * cellHeight,
    );
    final horizontalInset =
        cellPadding + modulePortDiameter / 2 + modulePortEdgeOffset;
    final verticalInset =
        cellPadding + modulePortDiameter / 2 + modulePortEdgeOffset;
    final left = gridPadding + module.column * cellWidth + horizontalInset;
    final right =
        gridPadding + (module.column + 1) * cellWidth - horizontalInset;
    final top = gridPadding + module.row * cellHeight + verticalInset;
    final bottom = gridPadding + (module.row + 1) * cellHeight - verticalInset;
    return switch (direction) {
      RelayDirection.north => Offset(center.dx, top),
      RelayDirection.east => Offset(right, center.dy),
      RelayDirection.south => Offset(center.dx, bottom),
      RelayDirection.west => Offset(left, center.dy),
    };
  }

  static Offset corePortAnchor(Size size, RelayDirection gateDirection) {
    final coreWidth = size.width * coreScale;
    final coreHeight = size.height * coreScale;
    final coreLeft = (size.width - coreWidth) / 2;
    final coreTop = (size.height - coreHeight) / 2;
    final usableWidth = coreWidth - corePortDiameter;
    final usableHeight = coreHeight - corePortDiameter;
    final alignment = switch (gateDirection) {
      RelayDirection.south => const Alignment(-0.5, -1),
      RelayDirection.west => const Alignment(1, -0.5),
      RelayDirection.north => const Alignment(0.5, 1),
      RelayDirection.east => const Alignment(-1, 0.5),
    };
    return Offset(
      coreLeft + usableWidth * (alignment.x + 1) / 2 + corePortDiameter / 2,
      coreTop + usableHeight * (alignment.y + 1) / 2 + corePortDiameter / 2,
    );
  }
}

class _CircuitTracePainter extends CustomPainter {
  _CircuitTracePainter({
    required this.placements,
    required this.specs,
    required this.poweredIds,
    required this.visuals,
  });

  final Map<int, ModulePlacement> placements;
  final Map<ModuleKind, ModuleSpec> specs;
  final Set<String> poweredIds;
  final EquippedVisuals visuals;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / 4;
    final cellHeight = size.height / 4;
    final faintPaint = Paint()
      ..color = visuals.board.grid
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index += 1) {
      canvas
        ..drawLine(
          Offset(index * cellWidth, 0),
          Offset(index * cellWidth, size.height),
          faintPaint,
        )
        ..drawLine(
          Offset(0, index * cellHeight),
          Offset(size.width, index * cellHeight),
          faintPaint,
        );
    }

    for (final entry in placements.entries) {
      final module = entry.value;
      for (final direction in const [
        RelayDirection.east,
        RelayDirection.south,
      ]) {
        final neighborIndex = switch (direction) {
          RelayDirection.east when module.column < 3 => entry.key + 1,
          RelayDirection.south when module.row < 3 => entry.key + 4,
          _ => -1,
        };
        final neighbor = placements[neighborIndex];
        if (neighbor == null || !_connects(module, neighbor, direction)) {
          continue;
        }
        final start = CircuitTraceGeometry.modulePortAnchor(
          size,
          module,
          direction,
        );
        final end = CircuitTraceGeometry.modulePortAnchor(
          size,
          neighbor,
          direction.opposite,
        );
        final energized =
            poweredIds.contains(module.id) && poweredIds.contains(neighbor.id);
        final glow = Paint()
          ..color = energized
              ? visuals.modules.accent.withValues(alpha: 0.28)
              : visuals.board.traceMuted.withValues(alpha: 0.34)
          ..strokeWidth = energized ? 12 : 8
          ..strokeCap = StrokeCap.round;
        final trace = Paint()
          ..color = energized
              ? visuals.modules.accent
              : visuals.board.traceMuted
          ..strokeWidth = energized ? 4 : 3
          ..strokeCap = StrokeCap.round;
        canvas
          ..drawLine(start, end, glow)
          ..drawLine(start, end, trace);
      }
    }

    for (final entry in coreGateDirections.entries) {
      final module = placements[entry.key];
      final spec = module == null ? null : specs[module.kind];
      if (module == null ||
          spec == null ||
          !spec.worldPorts(module.orientation).contains(entry.value)) {
        continue;
      }
      final modulePort = CircuitTraceGeometry.modulePortAnchor(
        size,
        module,
        entry.value,
      );
      final corePort = CircuitTraceGeometry.corePortAnchor(size, entry.value);
      final energized = poweredIds.contains(module.id);
      final trace = Paint()
        ..color = energized ? visuals.board.gate : visuals.board.traceMuted
        ..strokeWidth = energized ? 4 : 3
        ..strokeCap = StrokeCap.round;
      final glow = Paint()
        ..color = energized
            ? visuals.board.gate.withValues(alpha: 0.28)
            : visuals.board.traceMuted.withValues(alpha: 0.20)
        ..strokeWidth = energized ? 12 : 8
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawLine(modulePort, corePort, glow)
        ..drawLine(modulePort, corePort, trace);
    }
  }

  bool _connects(
    ModulePlacement first,
    ModulePlacement second,
    RelayDirection direction,
  ) {
    final firstSpec = specs[first.kind];
    final secondSpec = specs[second.kind];
    if (firstSpec == null || secondSpec == null) {
      return false;
    }
    return firstSpec.worldPorts(first.orientation).contains(direction) &&
        secondSpec.worldPorts(second.orientation).contains(direction.opposite);
  }

  @override
  bool shouldRepaint(covariant _CircuitTracePainter oldDelegate) => true;
}

class _CircuitFlowPainter extends CustomPainter {
  const _CircuitFlowPainter({
    required this.placements,
    required this.specs,
    required this.poweredIds,
    required this.visuals,
  });

  final Map<int, ModulePlacement> placements;
  final Map<ModuleKind, ModuleSpec> specs;
  final Set<String> poweredIds;
  final EquippedVisuals visuals;

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in placements.entries) {
      final module = entry.value;
      for (final direction in const [
        RelayDirection.east,
        RelayDirection.south,
      ]) {
        final neighborIndex = switch (direction) {
          RelayDirection.east when module.column < 3 => entry.key + 1,
          RelayDirection.south when module.row < 3 => entry.key + 4,
          _ => -1,
        };
        final neighbor = placements[neighborIndex];
        if (neighbor == null ||
            !poweredIds.contains(module.id) ||
            !poweredIds.contains(neighbor.id) ||
            !_connects(module, neighbor, direction)) {
          continue;
        }
        _drawFlow(
          canvas,
          CircuitTraceGeometry.modulePortAnchor(size, module, direction),
          CircuitTraceGeometry.modulePortAnchor(
            size,
            neighbor,
            direction.opposite,
          ),
          visuals.modules.accent,
        );
      }
    }

    for (final entry in coreGateDirections.entries) {
      final module = placements[entry.key];
      final spec = module == null ? null : specs[module.kind];
      if (module == null ||
          spec == null ||
          !poweredIds.contains(module.id) ||
          !spec.worldPorts(module.orientation).contains(entry.value)) {
        continue;
      }
      final modulePort = CircuitTraceGeometry.modulePortAnchor(
        size,
        module,
        entry.value,
      );
      final corePort = CircuitTraceGeometry.corePortAnchor(size, entry.value);
      _drawFlow(
        canvas,
        module.kind == ModuleKind.generator ? modulePort : corePort,
        module.kind == ModuleKind.generator ? corePort : modulePort,
        visuals.board.gate,
      );
    }
  }

  void _drawFlow(Canvas canvas, Offset from, Offset to, Color color) {
    final delta = to - from;
    final distance = delta.distance;
    if (distance < 1) return;
    final direction = delta / distance;
    final normal = Offset(-direction.dy, direction.dx);
    for (final fraction in const [0.28, 0.56, 0.84]) {
      final center = Offset.lerp(from, to, fraction)!;
      final tip = center + direction * 3.8;
      final tail = center - direction * 3.8;
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tail.dx + normal.dx * 2.8, tail.dy + normal.dy * 2.8)
        ..lineTo(tail.dx - normal.dx * 2.8, tail.dy - normal.dy * 2.8)
        ..close();
      canvas.drawCircle(
        center,
        6,
        Paint()
          ..color = color.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(
        path,
        Paint()..color = RelayColors.white.withValues(alpha: 0.92),
      );
    }
  }

  bool _connects(
    ModulePlacement first,
    ModulePlacement second,
    RelayDirection direction,
  ) {
    final firstSpec = specs[first.kind];
    final secondSpec = specs[second.kind];
    return firstSpec != null &&
        secondSpec != null &&
        firstSpec.worldPorts(first.orientation).contains(direction) &&
        secondSpec.worldPorts(second.orientation).contains(direction.opposite);
  }

  @override
  bool shouldRepaint(covariant _CircuitFlowPainter oldDelegate) =>
      oldDelegate.placements != placements ||
      oldDelegate.poweredIds != poweredIds ||
      oldDelegate.visuals != visuals;
}
