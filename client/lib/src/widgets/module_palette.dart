import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import 'module_visuals.dart';

class ModuleShelf extends StatelessWidget {
  const ModuleShelf({
    required this.modules,
    required this.selectedKind,
    required this.onSelected,
    required this.onBoardModuleReturned,
    required this.remainingByKind,
    required this.kitName,
    required this.onEditKit,
    this.highlighted = false,
    super.key,
  });

  final List<ModuleSpec> modules;
  final ModuleKind? selectedKind;
  final ValueChanged<ModuleKind> onSelected;
  final ValueChanged<ModuleDragData> onBoardModuleReturned;
  final Map<ModuleKind, int> remainingByKind;
  final String kitName;
  final VoidCallback? onEditKit;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ModuleDragData>(
      hitTestBehavior: HitTestBehavior.opaque,
      onWillAcceptWithDetails: (details) => details.data.isFromBoard,
      onAcceptWithDetails: (details) => onBoardModuleReturned(details.data),
      builder: (context, candidateData, rejectedData) {
        final returning = candidateData.any(
          (data) => data?.isFromBoard ?? false,
        );
        return AnimatedContainer(
          key: const ValueKey('module-shelf'),
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              (returning ? RelayColors.coral : RelayColors.cyan).withValues(
                alpha: returning ? 0.13 : 0.06,
              ),
              RelayColors.surfaceHigh,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  (returning
                          ? RelayColors.coral
                          : highlighted
                          ? RelayColors.amber
                          : RelayColors.cyan)
                      .withValues(alpha: returning || highlighted ? 0.9 : 0.35),
              width: returning || highlighted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (highlighted ? RelayColors.amber : RelayColors.cyan)
                    .withValues(alpha: highlighted ? 0.36 : 0.08),
                blurRadius: highlighted ? 22 : 18,
                spreadRadius: highlighted ? 1 : -8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (returning) ...[
                const ModulePaletteReturnBanner(),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'MODÜL RAFI',
                          style: TextStyle(
                            color: RelayColors.cyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kitName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: RelayColors.muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('module-shelf-scroll'),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (
                            var index = 0;
                            index < modules.length;
                            index++
                          ) ...[
                            _PaletteItem(
                              module: modules[index],
                              selected: modules[index].kind == selectedKind,
                              width: 78,
                              remaining:
                                  remainingByKind[modules[index].kind] ?? 0,
                              dense: false,
                              compact: true,
                              onTap: () => onSelected(modules[index].kind),
                            ),
                            if (index < modules.length - 1)
                              const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    key: const ValueKey('module-shelf-edit-kit'),
                    tooltip: 'Başlangıç sekizlisini değiştir',
                    onPressed: onEditKit,
                    icon: const Icon(Icons.tune, size: 19),
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

class ModulePalette extends StatelessWidget {
  const ModulePalette({
    required this.modules,
    required this.selectedKind,
    required this.onSelected,
    required this.onBoardModuleReturned,
    required this.remainingByKind,
    this.vertical = false,
    this.compact = false,
    this.fixedColumns,
    super.key,
  });

  final List<ModuleSpec> modules;
  final ModuleKind? selectedKind;
  final ValueChanged<ModuleKind> onSelected;
  final ValueChanged<ModuleDragData> onBoardModuleReturned;
  final Map<ModuleKind, int> remainingByKind;
  final bool vertical;
  final bool compact;
  final int? fixedColumns;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ModuleDragData>(
      hitTestBehavior: HitTestBehavior.opaque,
      onWillAcceptWithDetails: (details) => details.data.isFromBoard,
      onAcceptWithDetails: (details) => onBoardModuleReturned(details.data),
      builder: (context, candidateData, rejectedData) {
        final returning = candidateData.any(
          (data) => data?.isFromBoard ?? false,
        );
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: returning
                ? RelayColors.coral.withValues(alpha: 0.13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: returning ? RelayColors.coral : const Color(0x002B5361),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                child: returning
                    ? const ModulePaletteReturnBanner()
                    : const SizedBox(key: ValueKey('hint'), height: 0),
              ),
              if (returning) const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 5.0;
                  const runSpacing = 4.0;
                  if (vertical) {
                    return Column(
                      children: [
                        for (
                          var index = 0;
                          index < modules.length;
                          index++
                        ) ...[
                          _PaletteItem(
                            module: modules[index],
                            selected: modules[index].kind == selectedKind,
                            width: constraints.maxWidth,
                            remaining:
                                remainingByKind[modules[index].kind] ?? 0,
                            dense: true,
                            compact: false,
                            onTap: () => onSelected(modules[index].kind),
                          ),
                          if (index < modules.length - 1)
                            const SizedBox(height: runSpacing),
                        ],
                      ],
                    );
                  }
                  final columnCount =
                      fixedColumns ??
                      (constraints.maxWidth >= 720
                          ? 4
                          : constraints.maxWidth >= 520
                          ? 3
                          : 2);
                  final computedTileWidth =
                      (constraints.maxWidth - spacing * (columnCount - 1)) /
                      columnCount;
                  final compactTileWidth = math.max(
                    0.0,
                    computedTileWidth - 6.0,
                  );
                  final tileWidth = columnCount == 4
                      ? math.min(235.0, compactTileWidth)
                      : compactTileWidth;
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: spacing,
                    runSpacing: runSpacing,
                    children: [
                      for (final module in modules)
                        _PaletteItem(
                          module: module,
                          selected: module.kind == selectedKind,
                          width: tileWidth,
                          remaining: remainingByKind[module.kind] ?? 0,
                          dense: false,
                          compact: compact,
                          onTap: () => onSelected(module.kind),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModulePaletteReturnBanner extends StatelessWidget {
  const ModulePaletteReturnBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: ValueKey('return'),
      children: [
        Icon(Icons.remove_circle_outline, color: RelayColors.coral, size: 18),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            'BURAYA BIRAK: KARTTAN KALDIR',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: RelayColors.coral,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaletteItem extends StatelessWidget {
  const _PaletteItem({
    required this.module,
    required this.selected,
    required this.width,
    required this.remaining,
    required this.dense,
    required this.compact,
    required this.onTap,
  });

  final ModuleSpec module;
  final bool selected;
  final double width;
  final int remaining;
  final bool dense;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = remaining <= 0;
    return Tooltip(
      message:
          '${module.displayName}\n${module.description}\n${_moduleStatistics(module)}\nKitte kalan: $remaining',
      child: Draggable<ModuleDragData>(
        data: ModuleDragData.palette(module.kind),
        maxSimultaneousDrags: disabled ? 0 : 1,
        onDragStarted: disabled ? null : onTap,
        feedback: _DragFeedback(module: module),
        childWhenDragging: Opacity(
          opacity: 0.38,
          child: _PaletteTile(
            module: module,
            selected: selected,
            width: width,
            remaining: remaining,
            dense: dense,
            compact: compact,
            onTap: disabled ? null : onTap,
          ),
        ),
        child: _PaletteTile(
          module: module,
          selected: selected,
          width: width,
          remaining: remaining,
          dense: dense,
          compact: compact,
          onTap: disabled ? null : onTap,
        ),
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.module,
    required this.selected,
    required this.width,
    required this.remaining,
    required this.dense,
    required this.compact,
    required this.onTap,
  });

  final ModuleSpec module;
  final bool selected;
  final double width;
  final int remaining;
  final bool dense;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = moduleColor(module.kind);
    final disabled = remaining <= 0;
    if (compact) {
      return _CompactPaletteTile(
        module: module,
        color: color,
        selected: selected,
        disabled: disabled,
        width: width,
        remaining: remaining,
        onTap: onTap,
      );
    }
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.grab,
      child: Material(
        key: ValueKey('palette-module-${module.kind.wireValue}'),
        color: disabled
            ? RelayColors.surfaceHigh.withValues(alpha: 0.45)
            : selected
            ? color.withValues(alpha: 0.18)
            : RelayColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: width,
            height: dense
                ? 46
                : compact
                ? 44
                : 66,
            padding: EdgeInsets.symmetric(
              horizontal: dense
                  ? 4
                  : compact
                  ? 4
                  : 5,
              vertical: dense
                  ? 2
                  : compact
                  ? 1
                  : 3,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: disabled
                    ? RelayColors.muted.withValues(alpha: 0.35)
                    : selected
                    ? color
                    : const Color(0xFF2B5361),
                width: selected && !disabled ? 2 : 1,
              ),
            ),
            child: Opacity(
              opacity: disabled ? 0.48 : 1,
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          key: ValueKey(
                            'palette-module-remaining-${module.kind.wireValue}',
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: disabled
                                ? RelayColors.coral.withValues(alpha: 0.16)
                                : color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$remaining',
                            style: TextStyle(
                              color: disabled ? RelayColors.coral : color,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.drag_indicator,
                          color: RelayColors.muted,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ModuleHardware(
                                kind: module.kind,
                                color: color,
                                size: dense
                                    ? 20
                                    : compact
                                    ? 20
                                    : 28,
                              ),
                              SizedBox(width: dense ? 4 : 6),
                              Flexible(
                                child: Text(
                                  module.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: dense
                                        ? 10.5
                                        : compact
                                        ? 10
                                        : 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: dense
                              ? 1
                              : compact
                              ? 1
                              : 3,
                        ),
                        Text(
                          _moduleStatistics(module),
                          key: ValueKey(
                            'palette-module-properties-${module.kind.wireValue}',
                          ),
                          maxLines: dense || compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: RelayColors.muted,
                            fontSize: dense
                                ? 7.5
                                : compact
                                ? 7.5
                                : 9.5,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactPaletteTile extends StatelessWidget {
  const _CompactPaletteTile({
    required this.module,
    required this.color,
    required this.selected,
    required this.disabled,
    required this.width,
    required this.remaining,
    required this.onTap,
  });

  final ModuleSpec module;
  final Color color;
  final bool selected;
  final bool disabled;
  final double width;
  final int remaining;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !disabled,
      selected: selected,
      label: '${module.displayName}, kitte kalan $remaining',
      child: MouseRegion(
        cursor: disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.grab,
        child: Material(
          key: ValueKey('palette-module-${module.kind.wireValue}'),
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Opacity(
              opacity: disabled ? 0.42 : 1,
              child: SizedBox(
                width: width,
                height: 68,
                child: ModuleChassis(
                  accent: color,
                  lifted: selected && !disabled,
                  compact: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.alphaBlend(
                            color.withValues(alpha: selected ? 0.28 : 0.16),
                            const Color(0xFF17323D),
                          ),
                          const Color(0xFF08161C),
                        ],
                      ),
                      border: Border.all(
                        color: selected ? color : const Color(0xFF2B5361),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ModuleHardware(
                          kind: module.kind,
                          color: color,
                          size: 48,
                        ),
                        Positioned(
                          right: 5,
                          top: 4,
                          child: Container(
                            key: ValueKey(
                              'palette-module-remaining-${module.kind.wireValue}',
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: disabled
                                  ? RelayColors.coral.withValues(alpha: 0.22)
                                  : color.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$remaining',
                              style: TextStyle(
                                color: disabled ? RelayColors.coral : color,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        if (selected && !disabled)
                          Positioned(
                            left: 15,
                            right: 15,
                            bottom: 5,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: [
                                  BoxShadow(color: color, blurRadius: 7),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
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
      child: SizedBox(
        width: 112,
        height: 86,
        child: ModuleChassis(
          accent: color,
          lifted: true,
          compact: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    color.withValues(alpha: 0.24),
                    const Color(0xFF17323D),
                  ),
                  const Color(0xFF0B1C24),
                ],
              ),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.24), blurRadius: 15),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  ModuleHardware(kind: module.kind, color: color, size: 40),
                  const SizedBox(height: 4),
                  Text(
                    module.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'DEVREYE TAK',
                    style: TextStyle(
                      color: RelayColors.cyan,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _moduleStatistics(ModuleSpec spec) {
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
