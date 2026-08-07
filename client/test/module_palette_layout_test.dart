import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/models/relay_models.dart';
import 'package:project_relay_client/src/widgets/module_palette.dart';

void main() {
  testWidgets('dar paletteye kart geri bırakılırken taşma oluşmaz', (tester) async {
    ModuleDragData? returnedModule;
    const module = ModuleSpec(
      kind: ModuleKind.repair,
      displayName: 'Onarım',
      description: 'Hasar görmüş modülü onarır.',
      maxHp: 30,
      ports: {RelayDirection.west},
      energyOutput: 0,
      batteryCapacity: 0,
      energyCost: 5,
      cooldownTicks: 3,
      heatPerAction: 0,
      damage: 0,
      shield: 0,
      cooling: 0,
      repair: 11,
      threat: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 162,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Draggable<ModuleDragData>(
                    key: const ValueKey('board-module-drag-source'),
                    data: const ModuleDragData.board(
                      kind: ModuleKind.repair,
                      cellIndex: 7,
                    ),
                    feedback: const Material(
                      child: SizedBox(width: 40, height: 40),
                    ),
                    child: const SizedBox(width: 40, height: 40),
                  ),
                  ModulePalette(
                    modules: const [module],
                    selectedKind: null,
                    onSelected: (_) {},
                    onBoardModuleReturned: (data) => returnedModule = data,
                    remainingByKind: const {ModuleKind.repair: 1},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final source = find.byKey(const ValueKey('board-module-drag-source'));
    final palette = find.byType(ModulePalette);
    final sourceCenter = tester.getCenter(source);
    final paletteCenter = tester.getCenter(palette);

    final gesture = await tester.startGesture(sourceCenter);
    await tester.pump();

    // Draggable ancak dokunma sürükleme eşiği geçildikten sonra aktif olur.
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump();
    await gesture.moveTo(paletteCenter);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const ValueKey('return')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(returnedModule, isNotNull);
    expect(returnedModule!.isFromBoard, isTrue);
    expect(returnedModule!.sourceCell, 7);
    expect(tester.takeException(), isNull);
  });
}
