import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/circuit_cable.dart';
import '../theme/circuit_presentation.dart';
import '../theme/cosmetic_visuals.dart';
import '../theme/relay_theme.dart';
import 'module_compact_stats.dart';
import 'module_visuals.dart';
import 'relay_emblem.dart';

typedef ModuleDropCallback = void Function(int cellIndex, ModuleDragData data);
typedef ModuleDropPredicate = bool Function(int cellIndex, ModuleDragData data);

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
    this.canAcceptModuleDrop,
    this.moduleDraggingEnabled = true,
    this.keyPrefix,
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
  final ModuleDropPredicate? canAcceptModuleDrop;
  final bool moduleDraggingEnabled;
  final String? keyPrefix;

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
            borderRadius: BorderRadius.circular(
              CircuitPresentationSpec.boardCornerRadius,
            ),
            border: Border.all(
              color: boardTheme.border,
              width: CircuitPresentationSpec.boardBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: boardTheme.core.withValues(alpha: 0.22),
                blurRadius: 26,
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            key: const ValueKey('circuit-board-face-clip'),
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(
              CircuitPresentationSpec.boardCornerRadius -
                  CircuitPresentationSpec.boardBorderWidth,
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: CustomPaint(
                    painter: _CircuitTracePainter(
                      placements: placements,
                      specs: specs,
                      poweredIds: poweredIds,
                      visuals: visuals,
                      moduleLift: presentation3d
                          ? CircuitPresentationSpec.moduleRestingLift
                          : 0,
                      coreLift: presentation3d ? 11.0 : 0,
                    ),
                  ),
                ),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  clipBehavior: Clip.hardEdge,
                  padding: const EdgeInsets.all(
                    CircuitPresentationSpec.boardContentInset,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: CircuitPresentationSpec.gridSize,
                  ),
                  itemCount:
                      CircuitPresentationSpec.gridSize *
                      CircuitPresentationSpec.gridSize,
                  itemBuilder: (context, index) {
                    if (isCoreCell(index)) {
                      return Padding(
                        padding: const EdgeInsets.all(
                          CircuitPresentationSpec.cellInset,
                        ),
                        child: _CoreCellBackdrop(
                          cellIndex: index,
                          keyPrefix: keyPrefix,
                          onTap: () => onCellTap(index),
                        ),
                      );
                    }
                    final placement = placements[index];
                    return Padding(
                      padding: const EdgeInsets.all(
                        CircuitPresentationSpec.cellInset,
                      ),
                      child: _CircuitCell(
                        cellIndex: index,
                        keyPrefix: keyPrefix,
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
                        canAcceptDrop: (data) =>
                            canAcceptModuleDrop?.call(index, data) ??
                            data.sourceCell != index,
                        onRotate: placement?.kind == ModuleKind.amplifier
                            ? () => onRotateModule(index)
                            : null,
                        raised: presentation3d,
                        upgradeBranch: placement == null
                            ? null
                            : upgradeBranches[placement.id],
                        moduleDraggingEnabled: moduleDraggingEnabled,
                      ),
                    );
                  },
                ),
                IgnorePointer(
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: CircuitPresentationSpec.coreExtentFactor,
                      heightFactor: CircuitPresentationSpec.coreExtentFactor,
                      child: _CoreHub(raised: presentation3d),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: _AnimatedCircuitFlow(
                      placements: placements,
                      specs: specs,
                      poweredIds: poweredIds,
                      visuals: visuals,
                      moduleLift: presentation3d
                          ? CircuitPresentationSpec.moduleRestingLift
                          : 0,
                      coreLift: presentation3d ? 11.0 : 0,
                    ),
                  ),
                ),
              ],
            ),
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

  static const double perspectiveDepth =
      CircuitPresentationSpec.preparationPerspectiveDepth;
  static const double deckTilt = CircuitPresentationSpec.preparationDeckTilt;
  static const double deckYaw = CircuitPresentationSpec.preparationDeckYaw;

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
    required double blurRadius,
    required double spreadRadius,
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
              borderRadius: BorderRadius.circular(
                CircuitPresentationSpec.boardCornerRadius + 2,
              ),
              border: Border.all(
                color: boardTheme.core.withValues(alpha: 0.34 + opacity),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: boardTheme.core.withValues(alpha: 0.30),
                  blurRadius: blurRadius,
                  spreadRadius: spreadRadius,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.min(
          constraints.maxWidth,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : constraints.maxWidth,
        );
        final scale = (available / 500.0).clamp(0.5, 1.2);
        final hPad = 16.0 * scale;
        final topPad = 20.0 * scale;
        final bottomPad = 34.0 * scale;
        final deckDepth = 22.0 * scale;
        final boardOffset = 4.0 * scale;
        final glowBottom = -12.0 * scale;
        final glowHeight = 54.0 * scale;
        final glowLeft = 34.0 * scale;
        final glowRight = 20.0 * scale;
        final blurRadius = 16.0 * scale;
        final spreadRadius = -4.0 * scale;
        return ClipRect(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, bottomPad),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: glowLeft,
                    right: glowRight,
                    bottom: glowBottom,
                    height: glowHeight,
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
                      depth: deckDepth,
                      opacity: 0.09,
                      blurRadius: blurRadius,
                      spreadRadius: spreadRadius,
                    ),
                  ),
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(0, boardOffset),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: _deckTransform(),
                        transformHitTests: true,
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    required this.canAcceptDrop,
    required this.onRotate,
    required this.raised,
    required this.upgradeBranch,
    required this.moduleDraggingEnabled,
    this.keyPrefix,
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
  final bool Function(ModuleDragData data) canAcceptDrop;
  final VoidCallback? onRotate;
  final bool raised;
  final String? upgradeBranch;
  final bool moduleDraggingEnabled;
  final String? keyPrefix;

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
      onWillAcceptWithDetails: (details) => canAcceptDrop(details.data),
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
          key: ValueKey('circuit-cell-${keyPrefix != null ? '$keyPrefix-' : ''}$cellIndex'),
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
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ModuleHardware(
                                      kind: candidate.kind,
                                      color: visuals.modules.moduleColorFor(
                                        candidate.kind,
                                      ),
                                      size: 40,
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
                                padding: EdgeInsets.all(
                                  raised ? 0 : (coreGate ? 20 : 16),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final fit = math.min(
                                      constraints.maxWidth,
                                      constraints.maxHeight,
                                    );
                                    return Center(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 260,
                                        ),
                                        switchInCurve: Curves.easeOutBack,
                                        switchOutCurve: Curves.easeIn,
                                        transitionBuilder:
                                            (child, animation) =>
                                                FadeTransition(
                                                  opacity: animation,
                                                  child: ScaleTransition(
                                                    scale: Tween<double>(
                                                      begin: 0.76,
                                                      end: 1,
                                                    ).animate(animation),
                                                    child: child,
                                                  ),
                                                ),
                                        child: ModuleHardware(
                                          kind: module.kind,
                                          key: ValueKey(
                                            'module-glyph-${module.id}',
                                          ),
                                          color: color,
                                          size: fit,
                                        ),
                                      ),
                                    );
                                  },
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
        if (!moduleDraggingEnabled) {
          return presentedCell;
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
  const _CoreCellBackdrop({
    required this.cellIndex,
    required this.onTap,
    this.keyPrefix,
  });

  final int cellIndex;
  final VoidCallback onTap;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final visuals = CosmeticVisualScope.of(context);
    return Semantics(
      key: ValueKey('circuit-cell-${keyPrefix != null ? '$keyPrefix-' : ''}$cellIndex'),
      button: true,
      label: 'Pasif çekirdek hücresi',
      child: Material(
        color: visuals.board.cell,
        borderRadius: BorderRadius.circular(
          CircuitPresentationSpec.cellCornerRadius,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            CircuitPresentationSpec.cellCornerRadius,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                CircuitPresentationSpec.cellCornerRadius,
              ),
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
        borderRadius: BorderRadius.circular(
          CircuitPresentationSpec.coreCornerRadius,
        ),
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
                borderRadius: BorderRadius.circular(
                  CircuitPresentationSpec.coreCornerRadius,
                ),
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
                    ModuleHardware(
                      kind: placement.kind,
                      color: color,
                      size: 40,
                    ),
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
  static const double gridPadding = CircuitPresentationSpec.boardContentInset;
  static const double cellPadding = CircuitPresentationSpec.cellInset;
  static const double modulePortDiameter = 9;
  static const double modulePortEdgeOffset = -1;
  static const double coreScale = CircuitPresentationSpec.coreExtentFactor;

  static Offset modulePortAnchor(
    Size size,
    ModulePlacement module,
    RelayDirection direction, {
    double moduleLift = 0,
  }) {
    final cellWidth =
        (size.width - gridPadding * 2) / CircuitPresentationSpec.gridSize;
    final cellHeight =
        (size.height - gridPadding * 2) / CircuitPresentationSpec.gridSize;
    final center = Offset(
      gridPadding + (module.column + 0.5) * cellWidth,
      gridPadding + (module.row + 0.5) * cellHeight - moduleLift,
    );
    final horizontalInset =
        cellPadding + modulePortDiameter / 2 + modulePortEdgeOffset;
    final verticalInset =
        cellPadding + modulePortDiameter / 2 + modulePortEdgeOffset;
    final left = gridPadding + module.column * cellWidth + horizontalInset;
    final right =
        gridPadding + (module.column + 1) * cellWidth - horizontalInset;
    final top = gridPadding + module.row * cellHeight + verticalInset - moduleLift;
    final bottom = gridPadding + (module.row + 1) * cellHeight - verticalInset - moduleLift;
    return switch (direction) {
      RelayDirection.north => Offset(center.dx, top),
      RelayDirection.east => Offset(right, center.dy),
      RelayDirection.south => Offset(center.dx, bottom),
      RelayDirection.west => Offset(left, center.dy),
    };
  }

  static Offset corePortAnchor(
    Size size,
    RelayDirection gateDirection, {
    double coreLift = 0,
  }) {
    final coreWidth = size.width * coreScale;
    final coreHeight = size.height * coreScale;
    final coreLeft = (size.width - coreWidth) / 2;
    final coreTop = (size.height - coreHeight) / 2;
    final alignment = switch (gateDirection) {
      RelayDirection.south => const Alignment(-0.5, -1),
      RelayDirection.west => const Alignment(1, -0.5),
      RelayDirection.north => const Alignment(0.5, 1),
      RelayDirection.east => const Alignment(-1, 0.5),
    };
    return Offset(
      coreLeft + coreWidth * (alignment.x + 1) / 2,
      coreTop + coreHeight * (alignment.y + 1) / 2 - coreLift,
    );
  }
}

class _CircuitTracePainter extends CustomPainter {
  _CircuitTracePainter({
    required this.placements,
    required this.specs,
    required this.poweredIds,
    required this.visuals,
    this.moduleLift = 0,
    this.coreLift = 0,
  });

  final Map<int, ModulePlacement> placements;
  final Map<ModuleKind, ModuleSpec> specs;
  final Set<String> poweredIds;
  final EquippedVisuals visuals;
  final double moduleLift;
  final double coreLift;

  @override
  void paint(Canvas canvas, Size size) {
    final padding = CircuitTraceGeometry.gridPadding;
    final cellWidth =
        (size.width - padding * 2) / CircuitPresentationSpec.gridSize;
    final cellHeight =
        (size.height - padding * 2) / CircuitPresentationSpec.gridSize;
    final faintPaint = Paint()
      ..color = visuals.board.grid
      ..strokeWidth = 1;
    for (var index = 1; index < CircuitPresentationSpec.gridSize; index += 1) {
      canvas
        ..drawLine(
          Offset(padding + index * cellWidth, padding),
          Offset(padding + index * cellWidth, size.height - padding),
          faintPaint,
        )
        ..drawLine(
          Offset(padding, padding + index * cellHeight),
          Offset(size.width - padding, padding + index * cellHeight),
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
          RelayDirection.east
              when module.column < CircuitPresentationSpec.gridSize - 1 =>
            entry.key + 1,
          RelayDirection.south
              when module.row < CircuitPresentationSpec.gridSize - 1 =>
            entry.key + CircuitPresentationSpec.gridSize,
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
          moduleLift: moduleLift,
        );
        final end = CircuitTraceGeometry.modulePortAnchor(
          size,
          neighbor,
          direction.opposite,
          moduleLift: moduleLift,
        );
        final energized =
            poweredIds.contains(module.id) && poweredIds.contains(neighbor.id);
        final cable = CircuitCableVisual.path(start, end);
        CircuitCableVisual.drawCable(
          canvas,
          cable,
          color: energized ? visuals.modules.accent : visuals.board.traceMuted,
          energized: energized,
        );
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
        moduleLift: moduleLift,
      );
      final corePort = CircuitTraceGeometry.corePortAnchor(
        size,
        entry.value,
        coreLift: coreLift,
      );
      final energized = poweredIds.contains(module.id);
      final cable = CircuitCableVisual.path(modulePort, corePort);
      CircuitCableVisual.drawCable(
        canvas,
        cable,
        color: energized ? visuals.board.gate : visuals.board.traceMuted,
        energized: energized,
        emphasized: true,
      );
    }

    final portRadius = CircuitTraceGeometry.modulePortDiameter / 2;
    final portFill = Paint()..style = PaintingStyle.fill;
    final portStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF07161C);

    for (final entry in placements.entries) {
      final module = entry.value;
      final spec = specs[module.kind];
      if (spec == null) continue;
      final energized = poweredIds.contains(module.id);
      for (final port in usableBoardPorts(
        module,
        spec.worldPorts(module.orientation),
      )) {
        final pos = CircuitTraceGeometry.modulePortAnchor(
          size,
          module,
          port,
          moduleLift: moduleLift,
        );
        portFill.color = energized
            ? visuals.modules.accent
            : const Color(0xFF7896A0);
        canvas
          ..drawCircle(pos, portRadius, portFill)
          ..drawCircle(pos, portRadius, portStroke);
        if (energized) {
          final glowPaint = Paint()
            ..color = visuals.modules.accent.withValues(alpha: 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
          canvas.drawCircle(pos, portRadius, glowPaint);
        }
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
      final pos = CircuitTraceGeometry.corePortAnchor(
        size,
        entry.value,
        coreLift: coreLift,
      );
      final energized = poweredIds.contains(module.id);
      portFill.color = energized
          ? visuals.board.gate
          : const Color(0xFF7896A0);
      canvas
        ..drawCircle(pos, portRadius, portFill)
        ..drawCircle(pos, portRadius, portStroke);
      if (energized) {
        final glowPaint = Paint()
          ..color = visuals.board.gate.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
        canvas.drawCircle(pos, portRadius, glowPaint);
      }
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

class _AnimatedCircuitFlow extends StatefulWidget {
  const _AnimatedCircuitFlow({
    required this.placements,
    required this.specs,
    required this.poweredIds,
    required this.visuals,
    this.moduleLift = 0,
    this.coreLift = 0,
  });

  final Map<int, ModulePlacement> placements;
  final Map<ModuleKind, ModuleSpec> specs;
  final Set<String> poweredIds;
  final EquippedVisuals visuals;
  final double moduleLift;
  final double coreLift;

  @override
  State<_AnimatedCircuitFlow> createState() => _AnimatedCircuitFlowState();
}

class _AnimatedCircuitFlowState extends State<_AnimatedCircuitFlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _motionDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      value: 0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_motionDisabled == disabled &&
        (_controller.isAnimating || disabled || _controller.value > 0)) {
      return;
    }
    _motionDisabled = disabled;
    if (disabled) {
      _controller
        ..stop()
        ..value = 0.35;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _CircuitFlowPainter(
          placements: widget.placements,
          specs: widget.specs,
          poweredIds: widget.poweredIds,
          visuals: widget.visuals,
          progress: _controller.value,
          moduleLift: widget.moduleLift,
          coreLift: widget.coreLift,
        ),
      ),
    );
  }
}

enum _FlowKind { energy, repair, cooling, shield, amplified }

class _CircuitFlowPainter extends CustomPainter {
  const _CircuitFlowPainter({
    required this.placements,
    required this.specs,
    required this.poweredIds,
    required this.visuals,
    required this.progress,
    this.moduleLift = 0,
    this.coreLift = 0,
  });

  final Map<int, ModulePlacement> placements;
  final Map<ModuleKind, ModuleSpec> specs;
  final Set<String> poweredIds;
  final EquippedVisuals visuals;
  final double progress;
  final double moduleLift;
  final double coreLift;

  @override
  void paint(Canvas canvas, Size size) {
    final distances = _energyDistances();
    for (final entry in placements.entries) {
      final module = entry.value;
      for (final direction in const [
        RelayDirection.east,
        RelayDirection.south,
      ]) {
        final neighborIndex = switch (direction) {
          RelayDirection.east
              when module.column < CircuitPresentationSpec.gridSize - 1 =>
            entry.key + 1,
          RelayDirection.south
              when module.row < CircuitPresentationSpec.gridSize - 1 =>
            entry.key + CircuitPresentationSpec.gridSize,
          _ => -1,
        };
        final neighbor = placements[neighborIndex];
        if (neighbor == null ||
            !poweredIds.contains(module.id) ||
            !poweredIds.contains(neighbor.id) ||
            !_connects(module, neighbor, direction)) {
          continue;
        }
        final moduleDistance = distances[module.id] ?? 1 << 20;
        final neighborDistance = distances[neighbor.id] ?? 1 << 20;
        final moduleFirst = moduleDistance != neighborDistance
            ? moduleDistance < neighborDistance
            : _preferAsSource(module, neighbor);
        final from = CircuitTraceGeometry.modulePortAnchor(
          size,
          moduleFirst ? module : neighbor,
          moduleFirst ? direction : direction.opposite,
          moduleLift: moduleLift,
        );
        final to = CircuitTraceGeometry.modulePortAnchor(
          size,
          moduleFirst ? neighbor : module,
          moduleFirst ? direction.opposite : direction,
          moduleLift: moduleLift,
        );
        final source = moduleFirst ? module : neighbor;
        final target = moduleFirst ? neighbor : module;
        _drawFlow(
          canvas,
          from,
          to,
          _flowKind(source: source, target: target),
          bidirectional:
              module.kind == ModuleKind.battery ||
              neighbor.kind == ModuleKind.battery,
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
        moduleLift: moduleLift,
      );
      final corePort = CircuitTraceGeometry.corePortAnchor(
        size,
        entry.value,
        coreLift: coreLift,
      );
      final from = module.kind == ModuleKind.generator ? modulePort : corePort;
      final to = module.kind == ModuleKind.generator ? corePort : modulePort;
      _drawFlow(canvas, from, to, _FlowKind.energy);
    }
  }

  Map<String, int> _energyDistances() {
    final distances = <String, int>{};
    for (final module in placements.values) {
      if (module.kind == ModuleKind.generator &&
          poweredIds.contains(module.id)) {
        distances[module.id] = 0;
      }
    }
    for (var round = 0; round < placements.length; round += 1) {
      var changed = false;
      for (final entry in placements.entries) {
        final module = entry.value;
        for (final direction in const [
          RelayDirection.east,
          RelayDirection.south,
        ]) {
          final neighborIndex = switch (direction) {
            RelayDirection.east
                when module.column < CircuitPresentationSpec.gridSize - 1 =>
              entry.key + 1,
            RelayDirection.south
                when module.row < CircuitPresentationSpec.gridSize - 1 =>
              entry.key + CircuitPresentationSpec.gridSize,
            _ => -1,
          };
          final neighbor = placements[neighborIndex];
          if (neighbor == null || !_connects(module, neighbor, direction)) {
            continue;
          }
          final moduleDistance = distances[module.id];
          final neighborDistance = distances[neighbor.id];
          if (moduleDistance != null && neighborDistance == null) {
            distances[neighbor.id] = moduleDistance + 1;
            changed = true;
          } else if (neighborDistance != null && moduleDistance == null) {
            distances[module.id] = neighborDistance + 1;
            changed = true;
          }
        }
      }
      if (!changed) break;
    }
    return distances;
  }

  bool _preferAsSource(ModulePlacement first, ModulePlacement second) {
    if (first.kind == ModuleKind.generator) return true;
    if (second.kind == ModuleKind.generator) return false;
    if (first.kind == ModuleKind.battery) return true;
    if (second.kind == ModuleKind.battery) return false;
    return first.cellIndex < second.cellIndex;
  }

  _FlowKind _flowKind({
    required ModulePlacement source,
    required ModulePlacement target,
  }) {
    return switch (source.kind) {
      ModuleKind.repair => _FlowKind.repair,
      ModuleKind.cooler => _FlowKind.cooling,
      ModuleKind.amplifier => _FlowKind.amplified,
      _ when target.kind == ModuleKind.shield => _FlowKind.shield,
      _ => _FlowKind.energy,
    };
  }

  Color _flowColor(_FlowKind kind) => switch (kind) {
    _FlowKind.energy => RelayColors.amber,
    _FlowKind.repair => RelayColors.mint,
    _FlowKind.cooling => RelayColors.cyan,
    _FlowKind.shield => RelayColors.electricBlue,
    _FlowKind.amplified => RelayColors.violet,
  };

  void _drawFlow(
    Canvas canvas,
    Offset from,
    Offset to,
    _FlowKind kind, {
    bool bidirectional = false,
  }) {
    final cable = CircuitCableVisual.path(from, to);
    final color = _flowColor(kind);
    for (final seed in const [0.0, 0.50]) {
      CircuitCableVisual.drawPacket(
        canvas,
        cable,
        phase: (seed + progress) % 1,
        color: color,
        opacity: 1,
      );
      if (bidirectional && seed == 0) {
        CircuitCableVisual.drawPacket(
          canvas,
          cable,
          phase: 1 - ((seed + progress * 0.72) % 1),
          color: color,
          opacity: 0.52,
        );
      }
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
      oldDelegate.visuals != visuals ||
      oldDelegate.progress != progress;
}
