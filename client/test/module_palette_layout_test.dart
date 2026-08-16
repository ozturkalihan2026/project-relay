import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/models/relay_models.dart';
import 'package:project_relay_client/src/widgets/module_palette.dart';

void main() {
  testWidgets('dar palette geri bırakma uyarısı taşmadan render edilir', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 162,
              child: ModulePaletteReturnBanner(),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('return')), findsOneWidget);
    expect(find.text('BURAYA BIRAK: KARTTAN KALDIR'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final bannerSize = tester.getSize(
      find.byType(ModulePaletteReturnBanner),
    );
    expect(bannerSize.width, 162);
    expect(bannerSize.height, greaterThan(0));
  });

  testWidgets('raf sürükleme geri bildirimi taşmadan render edilir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModuleShelf(
            modules: const [_generator, _longNamedLaser],
            selectedKind: null,
            onSelected: (_) {},
            onBoardModuleReturned: (_) {},
            remainingByKind: const {ModuleKind.generator: 3, ModuleKind.laser: 2},
            kitName: 'Test Kiti',
            onEditKit: null,
          ),
        ),
      ),
    );

    final item = find.byType(Draggable<ModuleDragData>).first;
    expect(item, findsOneWidget);

    await tester.drag(item, const Offset(70, 90));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

const _generator = ModuleSpec(
  kind: ModuleKind.generator,
  displayName: 'Jeneratör',
  description: 'Enerji üretir.',
  maxHp: 52,
  ports: {RelayDirection.east, RelayDirection.south},
  energyOutput: 8,
  batteryCapacity: 0,
  energyCost: 0,
  cooldownTicks: 0,
  heatPerAction: 0,
  damage: 0,
  shield: 0,
  cooling: 0,
  repair: 0,
  threat: 0,
);

const _longNamedLaser = ModuleSpec(
  kind: ModuleKind.laser,
  displayName: 'Süper Ağır Lazer Sistemi',
  description: 'Uzun isimli modül.',
  maxHp: 27,
  ports: {RelayDirection.west},
  energyOutput: 0,
  batteryCapacity: 0,
  energyCost: 4,
  cooldownTicks: 2,
  heatPerAction: 8,
  damage: 8,
  shield: 0,
  cooling: 0,
  repair: 0,
  threat: 0,
);
