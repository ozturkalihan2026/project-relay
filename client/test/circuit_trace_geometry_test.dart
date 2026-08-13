import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/game/replay_game.dart';
import 'package:project_relay_client/src/models/relay_models.dart';
import 'package:project_relay_client/src/widgets/circuit_board.dart';
import 'package:project_relay_client/src/widgets/module_visuals.dart';

void main() {
  const boardSize = Size.square(400);

  test('komşu bağlantı çizgisi iki görünür port merkezini birleştirir', () {
    const first = ModulePlacement(
      id: 'first',
      kind: ModuleKind.battery,
      row: 0,
      column: 0,
    );
    const second = ModulePlacement(
      id: 'second',
      kind: ModuleKind.battery,
      row: 0,
      column: 1,
    );

    _expectOffset(
      CircuitTraceGeometry.modulePortAnchor(
        boardSize,
        first,
        RelayDirection.east,
      ),
      94.5,
      53,
    );
    _expectOffset(
      CircuitTraceGeometry.modulePortAnchor(
        boardSize,
        second,
        RelayDirection.west,
      ),
      109.5,
      53,
    );
  });

  test('çekirdek kapısı çizgisi hücre merkezi yerine iki porta gider', () {
    const generator = ModulePlacement(
      id: 'generator',
      kind: ModuleKind.generator,
      row: 0,
      column: 1,
      orientation: RelayDirection.south,
    );

    final modulePort = CircuitTraceGeometry.modulePortAnchor(
      boardSize,
      generator,
      RelayDirection.south,
    );
    final corePort = CircuitTraceGeometry.corePortAnchor(
      boardSize,
      RelayDirection.south,
    );

    _expectOffset(modulePort, 151, 94.5);
    _expectOffset(corePort, 154.5, 109);
    expect(modulePort, isNot(const Offset(151, 53)));
    expect(corePort, isNot(const Offset(200, 200)));
  });

  test('dört çekirdek kapısının her biri kendi görünür porta bağlanır', () {
    _expectOffset(
      CircuitTraceGeometry.corePortAnchor(boardSize, RelayDirection.south),
      154.5,
      109,
    );
    _expectOffset(
      CircuitTraceGeometry.corePortAnchor(boardSize, RelayDirection.west),
      291,
      154.5,
    );
    _expectOffset(
      CircuitTraceGeometry.corePortAnchor(boardSize, RelayDirection.north),
      245.5,
      291,
    );
    _expectOffset(
      CircuitTraceGeometry.corePortAnchor(boardSize, RelayDirection.east),
      109,
      245.5,
    );
  });

  test('kart dışına ve kapısız çekirdek kenarına bakan portları gizler', () {
    const cornerBattery = ModulePlacement(
      id: 'corner-battery',
      kind: ModuleKind.battery,
      row: 0,
      column: 0,
    );
    const gateAmplifier = ModulePlacement(
      id: 'gate-amplifier',
      kind: ModuleKind.amplifier,
      row: 0,
      column: 1,
    );
    const nonGateAmplifier = ModulePlacement(
      id: 'non-gate-amplifier',
      kind: ModuleKind.amplifier,
      row: 0,
      column: 2,
    );

    expect(usableBoardPorts(cornerBattery, RelayDirection.values), {
      RelayDirection.east,
      RelayDirection.south,
    });
    expect(usableBoardPorts(gateAmplifier, RelayDirection.values), {
      RelayDirection.east,
      RelayDirection.south,
      RelayDirection.west,
    });
    expect(usableBoardPorts(nonGateAmplifier, RelayDirection.values), {
      RelayDirection.east,
      RelayDirection.west,
    });
  });

  testWidgets(
    'güçlendirici yön oku döndürme düğmesinin karşısında görünür kalır',
    (tester) async {
      const amplifier = ModulePlacement(
        id: 'amplifier',
        kind: ModuleKind.amplifier,
        row: 0,
        column: 1,
      );
      const spec = ModuleSpec(
        kind: ModuleKind.amplifier,
        displayName: 'Güçlendirici',
        description: 'Ok yönündeki komşuyu güçlendirir.',
        maxHp: 25,
        ports: {
          RelayDirection.north,
          RelayDirection.east,
          RelayDirection.south,
          RelayDirection.west,
        },
        energyOutput: 0,
        batteryCapacity: 0,
        energyCost: 0,
        cooldownTicks: 0,
        heatPerAction: 0,
        damage: 0,
        shield: 0,
        cooling: 0,
        repair: 0,
        threat: 90,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 400,
              child: CircuitBoard(
                placements: const {1: amplifier},
                specs: const {ModuleKind.amplifier: spec},
                poweredIds: const {},
                validationVisible: false,
                selectedCell: 1,
                onCellTap: (_) {},
                onModuleDropped: (_, _) {},
                onRotateModule: (_) {},
              ),
            ),
          ),
        ),
      );

      final rotate = find.byKey(const ValueKey('rotate-module-1'));
      final direction = find.byKey(const ValueKey('module-direction-1'));
      expect(rotate, findsOneWidget);
      expect(direction, findsOneWidget);
      expect(
        tester.getCenter(rotate).dx,
        lessThan(tester.getCenter(direction).dx),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'çekirdek kapısındaki yerleşik modül donanım glifiyle gösterilir',
    (tester) async {
      const generator = ModulePlacement(
        id: 'gate-generator',
        kind: ModuleKind.generator,
        row: 0,
        column: 1,
        orientation: RelayDirection.south,
      );
      const spec = ModuleSpec(
        kind: ModuleKind.generator,
        displayName: 'Jeneratör',
        description: 'Enerji üretir.',
        maxHp: 52,
        ports: {
          RelayDirection.north,
          RelayDirection.east,
          RelayDirection.south,
        },
        energyOutput: 8,
        batteryCapacity: 0,
        energyCost: 0,
        cooldownTicks: 0,
        heatPerAction: 0,
        damage: 0,
        shield: 0,
        cooling: 0,
        repair: 0,
        threat: 60,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 400,
              child: CircuitBoard(
                placements: const {1: generator},
                specs: const {ModuleKind.generator: spec},
                poweredIds: const {'gate-generator'},
                validationVisible: true,
                selectedCell: null,
                onCellTap: (_) {},
                onModuleDropped: (_, _) {},
                onRotateModule: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('module-glyph-gate-generator')),
        findsOneWidget,
      );
      expect(find.byType(ModuleGlyph), findsOneWidget);
      expect(
        find.byKey(const ValueKey('module-name-gate-generator')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('module-stat-badges-gate-generator')),
        findsNothing,
      );
      expect(find.text('ÇEKİRDEK KAPISI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('savaş kartında enerji hattı modül portları arasında kalır', () {
    const first = ModulePlacement(
      id: 'first',
      kind: ModuleKind.battery,
      row: 0,
      column: 0,
    );
    const second = ModulePlacement(
      id: 'second',
      kind: ModuleKind.battery,
      row: 0,
      column: 1,
    );
    const boardRect = Rect.fromLTWH(100, 200, 400, 400);

    _expectOffset(
      ReplayCircuitGeometry.modulePortAnchor(
        first,
        RelayDirection.east,
        boardRect,
      ),
      196,
      250,
    );
    _expectOffset(
      ReplayCircuitGeometry.modulePortAnchor(
        second,
        RelayDirection.west,
        boardRect,
      ),
      204,
      250,
    );
  });

  test('savaş kartında kapı hattı modül ve çekirdek portuna gider', () {
    const generator = ModulePlacement(
      id: 'generator',
      kind: ModuleKind.generator,
      row: 0,
      column: 1,
      orientation: RelayDirection.south,
    );
    const boardRect = Rect.fromLTWH(100, 200, 400, 400);

    final modulePort = ReplayCircuitGeometry.modulePortAnchor(
      generator,
      RelayDirection.south,
      boardRect,
    );
    final corePort = ReplayCircuitGeometry.corePortAnchor(
      RelayDirection.south,
      boardRect,
    );

    _expectOffset(modulePort, 250, 296);
    _expectOffset(corePort, 250, 304);
    expect(modulePort, isNot(boardRect.center));
    expect(corePort, isNot(boardRect.center));
  });
}

void _expectOffset(Offset actual, double dx, double dy) {
  expect(actual.dx, closeTo(dx, 0.001));
  expect(actual.dy, closeTo(dy, 0.001));
}
