import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import 'module_visuals.dart';

/// Çevrimiçi ve kariyer hazırlığının ortak sahne iskeleti.
///
/// Büyük ekranda devre kartını merkezde, bağlamsal bilgiyi sağda ve modül
/// rafını sabit biçimde altta tutar. Dar ekranda içerik kayar, raf erişilebilir
/// kalmaya devam eder.
class PreparationWorkspace extends StatelessWidget {
  const PreparationWorkspace({
    required this.boardStage,
    required this.sidePanel,
    required this.moduleShelf,
    super.key,
  });

  final Widget boardStage;
  final Widget sidePanel;
  final Widget moduleShelf;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        if (wide) {
          final sideWidth = math.min(370.0, constraints.maxWidth * 0.30);
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: boardStage),
                      const SizedBox(width: 18),
                      SizedBox(
                        width: sideWidth,
                        child: SingleChildScrollView(
                          key: const ValueKey('preparation-side-scroll'),
                          child: sidePanel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                moduleShelf,
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('preparation-main-scroll'),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: math.min(560, constraints.maxWidth + 76),
                      child: boardStage,
                    ),
                    const SizedBox(height: 12),
                    sidePanel,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: moduleShelf,
            ),
          ],
        );
      },
    );
  }
}

/// Çevrimiçi ve kariyer hazırlığında kullanılan ortak devre sahnesi.
class PreparationBoardStage extends StatelessWidget {
  const PreparationBoardStage({
    required this.board,
    required this.moduleCount,
    required this.maxModules,
    required this.onReset,
    this.title = 'DEVRE KARTI',
    this.subtitle = 'Modülü alttaki raftan sürükle veya seçip hücreye dokun.',
    this.accent = RelayColors.cyan,
    super.key,
  });

  final Widget board;
  final int moduleCount;
  final int maxModules;
  final VoidCallback? onReset;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.developer_board_outlined, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RelayColors.muted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$moduleCount/$maxModules',
                  style: const TextStyle(
                    color: RelayColors.amber,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  key: const ValueKey('preparation-reset-board'),
                  tooltip: 'Devreyi sıfırla',
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = math.min(
                    620.0,
                    math.min(constraints.maxWidth, constraints.maxHeight),
                  );
                  return Center(
                    child: ClipRect(
                      child: SizedBox.square(dimension: size, child: board),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Raf ve devre seçimini ayrıntılı ama ikincil bir panelde açıklar.
class SelectedModuleInspector extends StatelessWidget {
  const SelectedModuleInspector({
    required this.placement,
    required this.spec,
    super.key,
  });

  final ModulePlacement? placement;
  final ModuleSpec? spec;

  @override
  Widget build(BuildContext context) {
    final module = spec;
    if (module == null) {
      return const Card(
        key: ValueKey('selected-module-inspector-empty'),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.touch_app_outlined,
                color: RelayColors.muted,
                size: 30,
              ),
              SizedBox(height: 8),
              Text('MODÜL SEÇ', style: TextStyle(fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text(
                'Raftan veya devre kartından bir modül seçtiğinde ayrıntıları burada görünür.',
                textAlign: TextAlign.center,
                style: TextStyle(color: RelayColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }
    final color = moduleColor(module.kind);
    final location = placement == null
        ? 'RAFTAN SEÇİLDİ'
        : 'HÜCRE ${placement!.row + 1},${placement!.column + 1} • SV. ${placement!.level}';
    final stats = <String>[
      'Can ${module.maxHp.toStringAsFixed(0)}',
      if (module.energyOutput > 0)
        'Enerji +${module.energyOutput.toStringAsFixed(0)}',
      if (module.batteryCapacity > 0)
        'Depo ${module.batteryCapacity.toStringAsFixed(0)}',
      if (module.energyCost > 0)
        'Maliyet ${module.energyCost.toStringAsFixed(0)}',
      if (module.damage > 0) 'Hasar ${module.damage.toStringAsFixed(0)}',
      if (module.shield > 0) 'Kalkan ${module.shield.toStringAsFixed(0)}',
      if (module.cooling > 0) 'Soğutma ${module.cooling.toStringAsFixed(0)}',
      if (module.repair > 0) 'Onarım ${module.repair.toStringAsFixed(0)}',
    ];
    return Card(
      key: const ValueKey('selected-module-inspector'),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ModuleHardware(
                      kind: module.kind,
                      color: color,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.displayName.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        location,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              module.description,
              style: const TextStyle(
                color: RelayColors.muted,
                fontSize: 10.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final stat in stats)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: color.withValues(alpha: 0.35)),
                    label: Text(stat, style: const TextStyle(fontSize: 9)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
