import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import 'module_visuals.dart';

class ModulePalette extends StatelessWidget {
  const ModulePalette({
    required this.modules,
    required this.selectedKind,
    required this.onSelected,
    required this.onBoardModuleReturned,
    super.key,
  });

  final List<ModuleSpec> modules;
  final ModuleKind? selectedKind;
  final ValueChanged<ModuleKind> onSelected;
  final ValueChanged<ModuleDragData> onBoardModuleReturned;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ModuleDragData>(
      hitTestBehavior: HitTestBehavior.opaque,
      onWillAcceptWithDetails: (details) => details.data.isFromBoard,
      onAcceptWithDetails: (details) =>
          onBoardModuleReturned(details.data),
      builder: (context, candidateData, rejectedData) {
        final returning = candidateData.any(
          (data) => data?.isFromBoard ?? false,
        );
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: returning
                ? RelayColors.coral.withValues(alpha: 0.13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: returning
                  ? RelayColors.coral
                  : const Color(0x002B5361),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                child: returning
                    ? const Row(
                        key: ValueKey('return'),
                        children: [
                          Icon(
                            Icons.remove_circle_outline,
                            color: RelayColors.coral,
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'BURAYA BIRAK: KARTTAN KALDIR',
                            style: TextStyle(
                              color: RelayColors.coral,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(
                        key: ValueKey('hint'),
                        height: 0,
                      ),
              ),
              if (returning) const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final module in modules)
                    _PaletteItem(
                      module: module,
                      selected: module.kind == selectedKind,
                      onTap: () => onSelected(module.kind),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaletteItem extends StatelessWidget {
  const _PaletteItem({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final ModuleSpec module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${module.description}\n${_statistics(module)}',
      child: Draggable<ModuleDragData>(
        data: ModuleDragData.palette(module.kind),
        maxSimultaneousDrags: 1,
        onDragStarted: onTap,
        feedback: _DragFeedback(module: module),
        childWhenDragging: Opacity(
          opacity: 0.38,
          child: _PaletteTile(
            module: module,
            selected: selected,
            onTap: onTap,
          ),
        ),
        child: _PaletteTile(
          module: module,
          selected: selected,
          onTap: onTap,
        ),
      ),
    );
  }

  String _statistics(ModuleSpec spec) {
    final parts = <String>['Can ${spec.maxHp.toStringAsFixed(0)}'];
    if (spec.energyOutput > 0) {
      parts.add('Enerji +${spec.energyOutput.toStringAsFixed(0)}');
    }
    if (spec.batteryCapacity > 0) {
      parts.add('Depo ${spec.batteryCapacity.toStringAsFixed(0)}');
    }
    if (spec.energyCost > 0) {
      parts.add('Maliyet ${spec.energyCost.toStringAsFixed(0)}');
    }
    if (spec.damage > 0) {
      parts.add('Hasar ${spec.damage.toStringAsFixed(0)}');
    }
    if (spec.shield > 0) {
      parts.add('Kalkan ${spec.shield.toStringAsFixed(0)}');
    }
    if (spec.cooling > 0) {
      parts.add('Soğutma ${spec.cooling.toStringAsFixed(0)}');
    }
    if (spec.repair > 0) {
      parts.add('Onarım ${spec.repair.toStringAsFixed(0)}');
    }
    return parts.join(' • ');
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final ModuleSpec module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = moduleColor(module.kind);
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Material(
        key: ValueKey('palette-module-${module.kind.wireValue}'),
        color: selected
            ? color.withValues(alpha: 0.18)
            : RelayColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 128,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : const Color(0xFF2B5361),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(moduleIcon(module.kind), color: color, size: 20),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    module.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.drag_indicator,
                  color: RelayColors.muted,
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.module});

  final ModuleSpec module;

  @override
  Widget build(BuildContext context) {
    final color = moduleColor(module.kind);
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF2112730),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 18,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(moduleIcon(module.kind), color: color, size: 25),
              const SizedBox(width: 9),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const Text(
                    'KARTA BIRAK',
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
