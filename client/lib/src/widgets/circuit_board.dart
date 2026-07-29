import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import 'module_visuals.dart';

typedef ModuleDropCallback = void Function(
  int cellIndex,
  ModuleDragData data,
);

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

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1C24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2B5969), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3338E8FF),
              blurRadius: 26,
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: CustomPaint(
                  painter: _CircuitTracePainter(
                    placements: placements,
                    specs: specs,
                    poweredIds: poweredIds,
                  ),
                ),
              ),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(4),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  if (isCoreCell(index)) {
                    return const Padding(
                      padding: EdgeInsets.all(4),
                      child: _CoreCellBackdrop(),
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
                          placement != null && poweredIds.contains(placement.id),
                      onTap: () => onCellTap(index),
                      onModuleDropped: (data) =>
                          onModuleDropped(index, data),
                      onRotate: placement == null ||
                              placement.kind == ModuleKind.generator
                          ? null
                          : () => onRotateModule(index),
                    ),
                  );
                },
              ),
              const IgnorePointer(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.48,
                    heightFactor: 0.48,
                    child: _CoreHub(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final module = placement;
    final color = module == null ? RelayColors.muted : moduleColor(module.kind);
    return DragTarget<ModuleDragData>(
      hitTestBehavior: HitTestBehavior.opaque,
      onWillAcceptWithDetails: (details) =>
          details.data.sourceCell != cellIndex,
      onAcceptWithDetails: (details) => onModuleDropped(details.data),
      builder: (context, candidateData, rejectedData) {
        final candidate =
            candidateData.isEmpty ? null : candidateData.first;
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
                        ? const Color(0xFF9A7330)
                        : const Color(0xFF2B5361)
                    : powered
                        ? RelayColors.cyan
                        : RelayColors.coral;

        final cell = Semantics(
          button: true,
          label: module == null
              ? coreGate
                  ? 'Boş çekirdek kapısı, modül bırakılabilir'
                  : 'Boş devre hücresi, modül bırakılabilir'
              : '${spec?.displayName ?? module.kind.displayName}, '
                  '${module.orientation.shortLabel} yönü',
          child: AnimatedScale(
            scale: dropActive ? 1.035 : 1,
            duration: const Duration(milliseconds: 120),
            child: Material(
              color: dropActive
                  ? RelayColors.cyan.withValues(alpha: 0.16)
                  : module == null
                      ? const Color(0x99112730)
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
                              color: Color(0x6638E8FF),
                              blurRadius: 14,
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
                                      coreGate
                                          ? Icons.hub_outlined
                                          : Icons.add,
                                      color: coreGate
                                          ? RelayColors.amber
                                              .withValues(alpha: 0.72)
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
                                    Icon(
                                      moduleIcon(candidate.kind),
                                      color: moduleColor(candidate.kind),
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
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    moduleIcon(module.kind),
                                    color: color,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      spec?.displayName ??
                                          module.kind.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected && onRotate != null)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: SizedBox.square(
                                  dimension: 28,
                                  child: IconButton.filled(
                                    key: ValueKey(
                                      'rotate-module-$cellIndex',
                                    ),
                                    tooltip: '90° döndür',
                                    padding: EdgeInsets.zero,
                                    onPressed: onRotate,
                                    icon: const Icon(
                                      Icons.rotate_right,
                                      size: 17,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Positioned(
                                right: 5,
                                top: 5,
                                child: Tooltip(
                                  message: module.kind == ModuleKind.generator
                                      ? 'Jeneratör çekirdeğe dönük kalır'
                                      : 'Ön yön: '
                                          '${module.orientation.displayName}',
                                  child: Icon(
                                    directionIcon(module.orientation),
                                    color: Colors.white70,
                                    size: 15,
                                  ),
                                ),
                              ),
                            if (spec != null)
                              for (final port
                                  in spec!.worldPorts(module.orientation))
                                _PortMarker(
                                  direction: port,
                                  energized: powered,
                                ),
                            if (validationVisible)
                              Positioned(
                                left: 6,
                                top: 6,
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
        if (module == null) {
          return cell;
        }
        return Draggable<ModuleDragData>(
          data: ModuleDragData.board(
            kind: module.kind,
            cellIndex: cellIndex,
          ),
          maxSimultaneousDrags: 1,
          onDragStarted: onTap,
          feedback: _BoardDragFeedback(
            placement: module,
            displayName: spec?.displayName ?? module.kind.displayName,
          ),
          childWhenDragging: Opacity(opacity: 0.32, child: cell),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: cell,
          ),
        );
      },
    );
  }
}

class _CoreCellBackdrop extends StatelessWidget {
  const _CoreCellBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0E222B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x5538E8FF)),
      ),
    );
  }
}

class _CoreHub extends StatelessWidget {
  const _CoreHub();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [
            Color(0xFF1E5968),
            Color(0xFF102D37),
            Color(0xFF091A21),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RelayColors.cyan, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6638E8FF),
            blurRadius: 22,
          ),
        ],
      ),
      child: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.memory, color: RelayColors.cyan, size: 32),
                SizedBox(height: 4),
                Text(
                  'ÇEKİRDEK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'PASİF • 4 KAPI',
                  style: TextStyle(
                    color: RelayColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          for (final alignment in const [
            Alignment(-0.5, -1),
            Alignment(1, -0.5),
            Alignment(0.5, 1),
            Alignment(-1, 0.5),
          ])
            Align(
              alignment: alignment,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: RelayColors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x99FFB84A), blurRadius: 8),
                  ],
                ),
                child: SizedBox(width: 10, height: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _PortMarker extends StatelessWidget {
  const _PortMarker({
    required this.direction,
    required this.energized,
  });

  final RelayDirection direction;
  final bool energized;

  @override
  Widget build(BuildContext context) {
    final position = switch (direction) {
      RelayDirection.north => const {
          'top': -1.0,
          'left': 0.0,
          'right': 0.0,
        },
      RelayDirection.east => const {
          'right': -1.0,
          'top': 0.0,
          'bottom': 0.0,
        },
      RelayDirection.south => const {
          'bottom': -1.0,
          'left': 0.0,
          'right': 0.0,
        },
      RelayDirection.west => const {
          'left': -1.0,
          'top': 0.0,
          'bottom': 0.0,
        },
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
            color: energized ? RelayColors.cyan : const Color(0xFF7896A0),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF07161C), width: 1.5),
            boxShadow: energized
                ? const [
                    BoxShadow(
                      color: Color(0x9938E8FF),
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF2112730),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.32),
              blurRadius: 18,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(moduleIcon(placement.kind), color: color, size: 25),
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
    final cellWidth =
        (size.width - gridPadding * 2) / relayBoardSize;
    final cellHeight =
        (size.height - gridPadding * 2) / relayBoardSize;
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
    final bottom =
        gridPadding + (module.row + 1) * cellHeight - verticalInset;
    return switch (direction) {
      RelayDirection.north => Offset(center.dx, top),
      RelayDirection.east => Offset(right, center.dy),
      RelayDirection.south => Offset(center.dx, bottom),
      RelayDirection.west => Offset(left, center.dy),
    };
  }

  static Offset corePortAnchor(
    Size size,
    RelayDirection gateDirection,
  ) {
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
      coreLeft +
          usableWidth * (alignment.x + 1) / 2 +
          corePortDiameter / 2,
      coreTop +
          usableHeight * (alignment.y + 1) / 2 +
          corePortDiameter / 2,
    );
  }
}

class _CircuitTracePainter extends CustomPainter {
  _CircuitTracePainter({
    required this.placements,
    required this.specs,
    required this.poweredIds,
  });

  final Map<int, ModulePlacement> placements;
  final Map<ModuleKind, ModuleSpec> specs;
  final Set<String> poweredIds;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / 4;
    final cellHeight = size.height / 4;
    final faintPaint = Paint()
      ..color = const Color(0x222F879D)
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
        final energized = poweredIds.contains(module.id) &&
            poweredIds.contains(neighbor.id);
        final glow = Paint()
          ..color = energized
              ? RelayColors.cyan.withValues(alpha: 0.28)
              : const Color(0x553C6976)
          ..strokeWidth = energized ? 12 : 8
          ..strokeCap = StrokeCap.round;
        final trace = Paint()
          ..color =
              energized ? RelayColors.cyan : const Color(0xFF3C6976)
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
      final corePort = CircuitTraceGeometry.corePortAnchor(
        size,
        entry.value,
      );
      final energized = poweredIds.contains(module.id);
      final trace = Paint()
        ..color = energized ? RelayColors.amber : const Color(0xFF705A35)
        ..strokeWidth = energized ? 4 : 3
        ..strokeCap = StrokeCap.round;
      final glow = Paint()
        ..color = energized
            ? RelayColors.amber.withValues(alpha: 0.28)
            : const Color(0x33705A35)
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
        secondSpec
            .worldPorts(second.orientation)
            .contains(direction.opposite);
  }

  @override
  bool shouldRepaint(covariant _CircuitTracePainter oldDelegate) => true;
}
