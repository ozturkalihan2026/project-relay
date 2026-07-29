import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/game/replay_game.dart';
import 'package:project_relay_client/src/models/relay_models.dart';
import 'package:project_relay_client/src/widgets/circuit_board.dart';

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
      CircuitTraceGeometry.corePortAnchor(
        boardSize,
        RelayDirection.south,
      ),
      154.5,
      109,
    );
    _expectOffset(
      CircuitTraceGeometry.corePortAnchor(
        boardSize,
        RelayDirection.west,
      ),
      291,
      154.5,
    );
    _expectOffset(
      CircuitTraceGeometry.corePortAnchor(
        boardSize,
        RelayDirection.north,
      ),
      245.5,
      291,
    );
    _expectOffset(
      CircuitTraceGeometry.corePortAnchor(
        boardSize,
        RelayDirection.east,
      ),
      109,
      245.5,
    );
  });

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
