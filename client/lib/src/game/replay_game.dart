import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import '../widgets/module_visuals.dart';
import 'replay_event_formatter.dart';
import 'replay_timeline.dart';

abstract final class ReplayCircuitGeometry {
  static ui.Rect moduleRect(
    ModulePlacement module,
    ui.Rect boardRect,
  ) {
    final cellSize = boardRect.width / relayBoardSize;
    return ui.Rect.fromLTWH(
      boardRect.left + module.column * cellSize,
      boardRect.top + module.row * cellSize,
      cellSize,
      cellSize,
    ).deflate(4);
  }

  static ui.Offset modulePortAnchor(
    ModulePlacement module,
    RelayDirection direction,
    ui.Rect boardRect,
  ) {
    final rect = moduleRect(module, boardRect);
    return switch (direction) {
      RelayDirection.north => ui.Offset(rect.center.dx, rect.top),
      RelayDirection.east => ui.Offset(rect.right, rect.center.dy),
      RelayDirection.south => ui.Offset(rect.center.dx, rect.bottom),
      RelayDirection.west => ui.Offset(rect.left, rect.center.dy),
    };
  }

  static ui.Rect coreRect(ui.Rect boardRect) {
    final cellSize = boardRect.width / relayBoardSize;
    return ui.Rect.fromLTWH(
      boardRect.left + cellSize,
      boardRect.top + cellSize,
      cellSize * 2,
      cellSize * 2,
    ).deflate(4);
  }

  static ui.Offset corePortAnchor(
    RelayDirection gateDirection,
    ui.Rect boardRect,
  ) {
    final cellSize = boardRect.width / relayBoardSize;
    final rect = coreRect(boardRect);
    return switch (gateDirection) {
      RelayDirection.south => ui.Offset(
          boardRect.left + cellSize * 1.5,
          rect.top,
        ),
      RelayDirection.west => ui.Offset(
          rect.right,
          boardRect.top + cellSize * 1.5,
        ),
      RelayDirection.north => ui.Offset(
          boardRect.left + cellSize * 2.5,
          rect.bottom,
        ),
      RelayDirection.east => ui.Offset(
          rect.left,
          boardRect.top + cellSize * 2.5,
        ),
    };
  }
}

class ReplaySnapshot {
  const ReplaySnapshot({
    required this.tick,
    required this.leftHp,
    required this.rightHp,
    required this.lastEvent,
    required this.visibleEventCount,
    required this.complete,
  });

  factory ReplaySnapshot.initial(MatchResponse match) {
    return ReplaySnapshot(
      tick: 0,
      leftHp: match.result.left.coreMaxHp,
      rightHp: match.result.right.coreMaxHp,
      lastEvent: 'Sistemler hazırlanıyor',
      visibleEventCount: 0,
      complete: false,
    );
  }

  final int tick;
  final double leftHp;
  final double rightHp;
  final String lastEvent;
  final int visibleEventCount;
  final bool complete;
}

class RelayReplayGame extends FlameGame {
  RelayReplayGame({
    required this.match,
    required this.replay,
    required this.moduleSpecs,
    required this.formatter,
    required this.onFrame,
    required this.onEvents,
  })  : _cursor = ReplayPlaybackCursor(replay.events),
        _leftHp = match.result.left.coreMaxHp,
        _rightHp = match.result.right.coreMaxHp {
    for (final summary in match.result.left.modules) {
      _leftModuleHp[summary.id] = summary.maxHp;
      _moduleMaxHp[summary.id] = summary.maxHp;
    }
    for (final summary in match.result.right.modules) {
      _rightModuleHp[summary.id] = summary.maxHp;
      _moduleMaxHp[summary.id] = summary.maxHp;
    }
    final initialFrame = replay.stateAt(0);
    _leftBoardState = initialFrame?.left ??
        _initialBoardState(match.result.left);
    _rightBoardState = initialFrame?.right ??
        _initialBoardState(match.result.right);
    _applyBoardState(
      _leftBoardState,
      hp: _leftModuleHp,
      states: _leftModuleStates,
      deltas: _leftModuleDeltas,
    );
    _applyBoardState(
      _rightBoardState,
      hp: _rightModuleHp,
      states: _rightModuleStates,
      deltas: _rightModuleDeltas,
    );
  }

  final MatchResponse match;
  final ReplayResponse replay;
  final Map<ModuleKind, ModuleSpec> moduleSpecs;
  final ReplayEventFormatter formatter;
  final ValueChanged<ReplaySnapshot> onFrame;
  final ValueChanged<List<BattleEvent>> onEvents;
  final ReplayPlaybackCursor _cursor;
  final List<_VisualPulse> _pulses = [];
  final Map<String, double> _leftModuleHp = {};
  final Map<String, double> _rightModuleHp = {};
  final Map<String, double> _moduleMaxHp = {};
  final Map<String, ModuleReplayState> _leftModuleStates = {};
  final Map<String, ModuleReplayState> _rightModuleStates = {};
  final Map<String, _ModuleDelta> _leftModuleDeltas = {};
  final Map<String, _ModuleDelta> _rightModuleDeltas = {};
  final Set<String> _destroyedIds = {};
  late BoardReplayState _leftBoardState;
  late BoardReplayState _rightBoardState;

  static const _secondsPerTick = 0.24;
  double speed = 1;
  double _elapsed = 0;
  double _animationTime = 0;
  double _leftHp;
  double _rightHp;
  int _tick = 0;
  int _processedEventCount = 0;
  String _lastEvent = 'Sistemler hazırlanıyor';
  BattleEvent? _lastEventData;
  bool _completionSent = false;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt * speed;
    _animationTime += dt * speed;
    while (_elapsed >= _secondsPerTick && !_cursor.isComplete) {
      _elapsed -= _secondsPerTick;
      final frame = _cursor.next();
      if (frame != null) {
        _applyFrame(frame);
      }
    }

    for (final pulse in _pulses) {
      pulse.life -= dt * speed;
    }
    _pulses.removeWhere((pulse) => pulse.life <= 0);

    if (_cursor.isComplete && !_completionSent) {
      _completionSent = true;
      _tick = match.result.ticks;
      final finalFrame = replay.stateAt(match.result.ticks);
      if (finalFrame != null) {
        _setReplayState(finalFrame);
      }
      _leftHp = match.result.left.coreHp;
      _rightHp = match.result.right.coreHp;
      onFrame(
        ReplaySnapshot(
          tick: _tick,
          leftHp: _leftHp,
          rightHp: _rightHp,
          lastEvent: _resultLabel(match.result.winner),
          visibleEventCount: _processedEventCount,
          complete: true,
        ),
      );
    }
  }

  void _applyFrame(ReplayFrame frame) {
    _tick = frame.tick;
    final stateFrame = replay.stateAt(frame.tick);
    if (stateFrame != null) {
      _setReplayState(stateFrame);
    }
    for (final event in frame.events) {
      if (stateFrame == null) {
        _applyEventState(event);
      }
      _pulses.add(_VisualPulse.fromEvent(event));
      _lastEventData = event;
      _lastEvent = formatter.eventLabel(event);
      _processedEventCount += 1;
    }
    onEvents(frame.events);
    onFrame(
      ReplaySnapshot(
        tick: _tick,
        leftHp: _leftHp,
        rightHp: _rightHp,
        lastEvent: _lastEvent,
        visibleEventCount: _processedEventCount,
        complete: false,
      ),
    );
  }

  void _setReplayState(ReplayStateFrame frame) {
    _leftBoardState = frame.left;
    _rightBoardState = frame.right;
    _leftHp = frame.left.coreHp;
    _rightHp = frame.right.coreHp;
    _applyBoardState(
      frame.left,
      hp: _leftModuleHp,
      states: _leftModuleStates,
      deltas: _leftModuleDeltas,
    );
    _applyBoardState(
      frame.right,
      hp: _rightModuleHp,
      states: _rightModuleStates,
      deltas: _rightModuleDeltas,
    );
  }

  void _applyBoardState(
    BoardReplayState board, {
    required Map<String, double> hp,
    required Map<String, ModuleReplayState> states,
    required Map<String, _ModuleDelta> deltas,
  }) {
    final previousStates =
        Map<String, ModuleReplayState>.from(states);
    states
      ..clear()
      ..addEntries(
        board.modules.map(
          (module) => MapEntry(module.id, module),
        ),
      );
    deltas.clear();
    for (final module in board.modules) {
      final previous = previousStates[module.id];
      deltas[module.id] = _ModuleDelta(
        hp: previous == null ? 0 : module.hp - previous.hp,
        heat: previous == null ? 0 : module.heat - previous.heat,
      );
      hp[module.id] = module.hp;
      _moduleMaxHp[module.id] = module.maxHp;
      if (module.hp <= 0) {
        _destroyedIds.add(module.id);
      } else {
        _destroyedIds.remove(module.id);
      }
    }
  }

  void _applyEventState(BattleEvent event) {
    if (event.type == 'core_damage') {
      if (event.side == 'left') {
        _rightHp = math.max(0.0, _rightHp - event.amount);
      } else {
        _leftHp = math.max(0.0, _leftHp - event.amount);
      }
      return;
    }

    final targetId = event.targetId;
    if (targetId == null) {
      return;
    }
    if (event.type == 'attack') {
      final targetHp =
          event.side == 'left' ? _rightModuleHp : _leftModuleHp;
      final targetDeltas =
          event.side == 'left' ? _rightModuleDeltas : _leftModuleDeltas;
      final current = targetHp[targetId];
      if (current != null) {
        targetHp[targetId] = math.max(0.0, current - event.amount);
        targetDeltas[targetId] = _ModuleDelta(
          hp: -event.amount,
          heat: 0,
        );
      }
    } else if (event.type == 'repair') {
      final targetHp =
          event.side == 'left' ? _leftModuleHp : _rightModuleHp;
      final targetDeltas =
          event.side == 'left' ? _leftModuleDeltas : _rightModuleDeltas;
      final current = targetHp[targetId];
      final maximum = _moduleMaxHp[targetId];
      if (current != null && maximum != null) {
        targetHp[targetId] = math.min(maximum, current + event.amount);
        targetDeltas[targetId] = _ModuleDelta(
          hp: event.amount,
          heat: 0,
        );
      }
    } else if (event.type == 'destroyed') {
      _destroyedIds.add(targetId);
      final targetHp =
          event.side == 'left' ? _rightModuleHp : _leftModuleHp;
      targetHp[targetId] = 0;
    }
  }

  static BoardReplayState _initialBoardState(BoardSummary summary) {
    return BoardReplayState(
      coreHp: summary.coreMaxHp,
      shield: 0,
      energyReserve: 0,
      energyOutput: 0,
      energySpent: 0,
      modules: [
        for (final module in summary.modules)
          ModuleReplayState(
            id: module.id,
            hp: module.maxHp,
            maxHp: module.maxHp,
            heat: 0,
            cooldown: 0,
            powered: module.powered,
            overheated: false,
          ),
      ],
    );
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final width = size.x;
    final height = size.y;
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width, height),
      Paint()..color = RelayColors.background,
    );
    _drawCircuitBackground(canvas, width, height);

    final boardSize = math.min(width * 0.36, height * 0.60);
    final boardTop = height * 0.13;
    final leftBoard = ui.Rect.fromLTWH(
      width * 0.055,
      boardTop,
      boardSize,
      boardSize,
    );
    final rightBoard = ui.Rect.fromLTWH(
      width - width * 0.055 - boardSize,
      boardTop,
      boardSize,
      boardSize,
    );
    final leftCore = leftBoard.center;
    final rightCore = rightBoard.center;

    _drawBoard(
      canvas,
      rect: leftBoard,
      board: match.playerBoard,
      hp: _leftModuleHp,
      states: _leftModuleStates,
      deltas: _leftModuleDeltas,
      boardState: _leftBoardState,
      color: RelayColors.cyan,
      label: 'SEN',
      coreHp: _leftHp,
      coreMaxHp: match.result.left.coreMaxHp,
    );
    _drawBoard(
      canvas,
      rect: rightBoard,
      board: match.opponentBoard,
      hp: _rightModuleHp,
      states: _rightModuleStates,
      deltas: _rightModuleDeltas,
      boardState: _rightBoardState,
      color: RelayColors.coral,
      label: match.opponent.displayName.toUpperCase(),
      coreHp: _rightHp,
      coreMaxHp: match.result.right.coreMaxHp,
    );

    for (final pulse in _pulses) {
      _drawPulse(
        canvas,
        pulse,
        leftBoard: leftBoard,
        rightBoard: rightBoard,
        leftCore: leftCore,
        rightCore: rightCore,
      );
    }
    _drawText(
      canvas,
      'ADIM $_tick / ${match.result.ticks}',
      ui.Offset(width / 2, 12),
      color: RelayColors.muted,
      size: 12,
      centered: true,
    );
  }

  void _drawCircuitBackground(ui.Canvas canvas, double width, double height) {
    final paint = Paint()
      ..color = const Color(0x1838E8FF)
      ..strokeWidth = 1;
    for (var index = 1; index < 10; index += 1) {
      final y = height * index / 10;
      canvas.drawLine(ui.Offset(0, y), ui.Offset(width, y), paint);
    }
    for (var index = 1; index < 14; index += 1) {
      final x = width * index / 14;
      canvas.drawLine(ui.Offset(x, 0), ui.Offset(x, height), paint);
    }
  }

  void _drawBoard(
    ui.Canvas canvas, {
    required ui.Rect rect,
    required BoardDraft board,
    required Map<String, double> hp,
    required Map<String, ModuleReplayState> states,
    required Map<String, _ModuleDelta> deltas,
    required BoardReplayState boardState,
    required Color color,
    required String label,
    required double coreHp,
    required double coreMaxHp,
  }) {
    final cellSize = rect.width / 4;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(10)),
      Paint()..color = const Color(0xDD0B1C24),
    );
    for (var row = 0; row < 4; row += 1) {
      for (var column = 0; column < 4; column += 1) {
        final cell = ui.Rect.fromLTWH(
          rect.left + column * cellSize,
          rect.top + row * cellSize,
          cellSize,
          cellSize,
        ).deflate(2);
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(cell, const ui.Radius.circular(5)),
          Paint()
            ..color = const Color(0xFF112730)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(cell, const ui.Radius.circular(5)),
          Paint()
            ..color = const Color(0xFF31515C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    _drawEnergyTransmission(
      canvas,
      rect: rect,
      board: board,
      states: states,
    );

    _drawBoardCore(
      canvas,
      rect: rect,
      color: color,
      hp: coreHp,
      maxHp: coreMaxHp,
    );

    for (final module in board.modules) {
      final cell = ReplayCircuitGeometry.moduleRect(module, rect);
      final moduleColorValue = moduleColor(module.kind);
      final state = states[module.id];
      final delta = deltas[module.id] ?? const _ModuleDelta();
      final currentHp = hp[module.id] ?? state?.hp ?? 0;
      final destroyed = currentHp <= 0;
      final active = _lastEventData?.actorId == module.id ||
          _lastEventData?.targetId == module.id;
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(cell, const ui.Radius.circular(6)),
        Paint()
          ..color = moduleColorValue.withValues(
            alpha: destroyed ? 0.05 : 0.20,
          ),
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(cell, const ui.Radius.circular(6)),
        Paint()
          ..color = active ? RelayColors.amber : moduleColorValue
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 3 : 1.5,
      );
      _drawModulePorts(
        canvas,
        boardRect: rect,
        module: module,
        powered: state?.powered ?? false,
        destroyed: destroyed,
      );
      _drawText(
        canvas,
        _moduleCode(module.kind),
        ui.Offset(cell.center.dx, cell.top + 3),
        color: destroyed ? RelayColors.muted : moduleColorValue,
        size: math.max(7.0, cellSize * 0.15),
        centered: true,
        maxWidth: cell.width - 4,
      );

      final maximumHp = _moduleMaxHp[module.id] ?? 1;
      final ratio = (currentHp / maximumHp).clamp(0.0, 1.0).toDouble();
      if (cellSize >= 54) {
        _drawText(
          canvas,
          'Can: ${currentHp.toStringAsFixed(0)}/'
          '${maximumHp.toStringAsFixed(0)}${_deltaSuffix(delta.hp)}',
          ui.Offset(cell.center.dx, cell.center.dy - 13),
          color: delta.hp < 0
              ? RelayColors.coral
              : delta.hp > 0
                  ? RelayColors.mint
                  : ratio > 0.35
                      ? Colors.white70
                      : RelayColors.coral,
          size: math.max(5.3, cellSize * 0.075),
          centered: true,
          maxWidth: cell.width - 4,
        );
      }
      if (cellSize >= 54 && state != null) {
        _drawText(
          canvas,
          _moduleEnergyLabel(module, state, boardState),
          ui.Offset(cell.center.dx, cell.center.dy - 2),
          color: state.overheated
              ? RelayColors.amber
              : state.powered
                  ? Colors.white60
                  : RelayColors.coral,
          size: math.max(5.3, cellSize * 0.075),
          centered: true,
          maxWidth: cell.width - 4,
        );
        _drawText(
          canvas,
          'Isı: ${state.heat.toStringAsFixed(0)}'
          '${_deltaSuffix(delta.heat)}',
          ui.Offset(cell.center.dx, cell.center.dy + 9),
          color: delta.heat > 0
              ? RelayColors.amber
              : delta.heat < 0
                  ? RelayColors.cyan
                  : state.overheated
                      ? RelayColors.amber
                      : Colors.white60,
          size: math.max(5.3, cellSize * 0.075),
          centered: true,
          maxWidth: cell.width - 4,
        );
        _drawText(
          canvas,
          state.cooldown > 0
              ? 'Doluyor: ${state.cooldown}'
              : 'Hazır',
          ui.Offset(cell.center.dx, cell.center.dy + 20),
          color:
              state.cooldown > 0 ? RelayColors.amber : Colors.white54,
          size: math.max(5.3, cellSize * 0.075),
          centered: true,
          maxWidth: cell.width - 4,
        );
      }
      final bar = ui.Rect.fromLTWH(
        cell.left + 3,
        cell.bottom - 6,
        cell.width - 6,
        3,
      );
      canvas.drawRect(bar, Paint()..color = const Color(0xFF263F48));
      canvas.drawRect(
        ui.Rect.fromLTWH(bar.left, bar.top, bar.width * ratio, bar.height),
        Paint()..color = ratio > 0.35 ? RelayColors.mint : RelayColors.coral,
      );
      if (destroyed) {
        canvas
          ..drawLine(
            cell.topLeft,
            cell.bottomRight,
            Paint()
              ..color = RelayColors.coral
              ..strokeWidth = 2,
          )
          ..drawLine(
            cell.topRight,
            cell.bottomLeft,
            Paint()
              ..color = RelayColors.coral
              ..strokeWidth = 2,
          );
      }
    }

    _drawText(
      canvas,
      label,
      ui.Offset(rect.center.dx, rect.top - 35),
      color: color,
      size: 11,
      centered: true,
    );
    _drawText(
      canvas,
      'Kalkan: ${boardState.shield.toStringAsFixed(0)}  •  '
      'Rezerv: ${boardState.energyReserve.toStringAsFixed(0)}  •  '
      'Üretim: ${boardState.energyOutput.toStringAsFixed(0)}',
      ui.Offset(rect.center.dx, rect.top - 19),
      color: Colors.white60,
      size: 8.5,
      centered: true,
      maxWidth: rect.width,
    );
  }

  void _drawModulePorts(
    ui.Canvas canvas, {
    required ui.Rect boardRect,
    required ModulePlacement module,
    required bool powered,
    required bool destroyed,
  }) {
    final spec = moduleSpecs[module.kind];
    if (spec == null) {
      return;
    }
    for (final direction in spec.worldPorts(module.orientation)) {
      final point = ReplayCircuitGeometry.modulePortAnchor(
        module,
        direction,
        boardRect,
      );
      canvas
        ..drawCircle(
          point,
          4,
          Paint()..color = const Color(0xFF07161C),
        )
        ..drawCircle(
          point,
          2.5,
          Paint()
            ..color = destroyed
                ? RelayColors.muted.withValues(alpha: 0.45)
                : powered
                    ? RelayColors.amber
                    : RelayColors.muted,
        );
    }
  }

  void _drawEnergyTransmission(
    ui.Canvas canvas, {
    required ui.Rect rect,
    required BoardDraft board,
    required Map<String, ModuleReplayState> states,
  }) {
    final powered = board.modules
        .where(
          (module) =>
              (states[module.id]?.powered ?? false) &&
              (states[module.id]?.hp ?? 0) > 0,
        )
        .toList(growable: false);
    if (powered.isEmpty) {
      return;
    }
    final generators = powered
        .where((module) => module.kind == ModuleKind.generator)
        .toList(growable: false);
    if (generators.isEmpty) {
      return;
    }

    final distances = <String, int>{generators.first.id: 0};
    final frontier = <ModulePlacement>[generators.first];
    while (frontier.isNotEmpty) {
      final current = frontier.removeAt(0);
      final nextDistance = distances[current.id]! + 1;
      for (final candidate in powered) {
        if (distances.containsKey(candidate.id) ||
            !_energyConnected(current, candidate)) {
          continue;
        }
        distances[candidate.id] = nextDistance;
        frontier.add(candidate);
      }
    }

    var linkIndex = 0;
    for (var firstIndex = 0;
        firstIndex < powered.length;
        firstIndex += 1) {
      for (var secondIndex = firstIndex + 1;
          secondIndex < powered.length;
          secondIndex += 1) {
        var fromModule = powered[firstIndex];
        var toModule = powered[secondIndex];
        if (!_modulesConnected(fromModule, toModule)) {
          continue;
        }
        final firstDistance = distances[fromModule.id] ?? 99;
        final secondDistance = distances[toModule.id] ?? 99;
        if (secondDistance < firstDistance ||
            (secondDistance == firstDistance &&
                toModule.cellIndex < fromModule.cellIndex)) {
          final temporary = fromModule;
          fromModule = toModule;
          toModule = temporary;
        }
        final direction = _directionBetween(fromModule, toModule);
        if (direction == null) {
          continue;
        }
        final from = ReplayCircuitGeometry.modulePortAnchor(
          fromModule,
          direction,
          rect,
        );
        final to = ReplayCircuitGeometry.modulePortAnchor(
          toModule,
          direction.opposite,
          rect,
        );
        final phase =
            ((_animationTime * 1.65 + linkIndex * 0.27) % 1).toDouble();
        final pulse = ui.Offset.lerp(from, to, phase)!;
        final glow =
            0.65 + 0.35 * math.sin((_animationTime + linkIndex) * math.pi * 2);

        canvas.drawLine(
          from,
          to,
          Paint()
            ..color = RelayColors.amber.withValues(alpha: 0.24)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          pulse,
          6,
          Paint()
            ..color = RelayColors.amber.withValues(alpha: 0.16 * glow),
        );
        canvas.drawCircle(
          pulse,
          2.6,
          Paint()
            ..color = RelayColors.amber.withValues(alpha: 0.94 * glow),
        );
        linkIndex += 1;
      }
    }

    for (final module in powered.where(_moduleHasCorePort)) {
      final generatorToCore = module.kind == ModuleKind.generator;
      final gateDirection = coreGateDirections[module.cellIndex]!;
      final modulePort = ReplayCircuitGeometry.modulePortAnchor(
        module,
        gateDirection,
        rect,
      );
      final corePort = ReplayCircuitGeometry.corePortAnchor(
        gateDirection,
        rect,
      );
      final from = generatorToCore ? modulePort : corePort;
      final to = generatorToCore ? corePort : modulePort;
      final phase =
          ((_animationTime * 1.65 + linkIndex * 0.27) % 1).toDouble();
      final pulse = ui.Offset.lerp(from, to, phase)!;
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = RelayColors.amber.withValues(alpha: 0.30)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        pulse,
        5.5,
        Paint()..color = RelayColors.amber.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        pulse,
        2.5,
        Paint()..color = RelayColors.amber.withValues(alpha: 0.96),
      );
      linkIndex += 1;
    }
  }

  bool _energyConnected(
    ModulePlacement first,
    ModulePlacement second,
  ) {
    return _modulesConnected(first, second) ||
        (_moduleHasCorePort(first) && _moduleHasCorePort(second));
  }

  bool _modulesConnected(
    ModulePlacement first,
    ModulePlacement second,
  ) {
    final direction = _directionBetween(first, second);
    if (direction == null) {
      return false;
    }
    final firstSpec = moduleSpecs[first.kind];
    final secondSpec = moduleSpecs[second.kind];
    if (firstSpec == null || secondSpec == null) {
      return false;
    }
    return firstSpec.worldPorts(first.orientation).contains(direction) &&
        secondSpec
            .worldPorts(second.orientation)
            .contains(direction.opposite);
  }

  bool _moduleHasCorePort(ModulePlacement module) {
    final coreDirection = coreGateDirections[module.cellIndex];
    final spec = moduleSpecs[module.kind];
    return coreDirection != null &&
        spec != null &&
        spec.worldPorts(module.orientation).contains(coreDirection);
  }

  RelayDirection? _directionBetween(
    ModulePlacement first,
    ModulePlacement second,
  ) {
    final rowDelta = second.row - first.row;
    final columnDelta = second.column - first.column;
    return switch ((rowDelta, columnDelta)) {
      (-1, 0) => RelayDirection.north,
      (0, 1) => RelayDirection.east,
      (1, 0) => RelayDirection.south,
      (0, -1) => RelayDirection.west,
      _ => null,
    };
  }

  String _moduleEnergyLabel(
    ModulePlacement module,
    ModuleReplayState state,
    BoardReplayState boardState,
  ) {
    if (!state.powered || state.hp <= 0) {
      return 'Enerji: Kapalı';
    }
    final spec = moduleSpecs[module.kind];
    if (spec == null) {
      return 'Enerji: ?';
    }
    final levelScale = 1 + 0.18 * (module.level - 1);
    if (spec.energyOutput > 0) {
      return 'Enerji: +'
          '${(spec.energyOutput * levelScale).toStringAsFixed(0)}';
    }
    if (spec.batteryCapacity > 0) {
      return 'Rezerv: ${boardState.energyReserve.toStringAsFixed(0)}/'
          '${(spec.batteryCapacity * levelScale).toStringAsFixed(0)}';
    }
    if (spec.energyCost > 0) {
      return 'Enerji: -'
          '${(spec.energyCost * levelScale).toStringAsFixed(0)}';
    }
    return 'Enerji: Aktarım';
  }

  String _deltaSuffix(double delta) {
    if (delta.abs() < 0.001) {
      return '';
    }
    final sign = delta > 0 ? '+' : '';
    return ' ($sign${delta.toStringAsFixed(0)})';
  }

  void _drawBoardCore(
    ui.Canvas canvas, {
    required ui.Rect rect,
    required Color color,
    required double hp,
    required double maxHp,
  }) {
    final cellSize = rect.width / 4;
    final coreRect = ReplayCircuitGeometry.coreRect(rect);
    final center = coreRect.center;
    final ratio = (hp / maxHp).clamp(0.0, 1.0).toDouble();
    canvas
      ..drawRRect(
        ui.RRect.fromRectAndRadius(coreRect, const ui.Radius.circular(12)),
        Paint()..color = const Color(0xF20A2028),
      )
      ..drawRRect(
        ui.RRect.fromRectAndRadius(coreRect, const ui.Radius.circular(12)),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      )
      ..drawCircle(
        center,
        coreRect.shortestSide * 0.23,
        Paint()..color = color.withValues(alpha: 0.15),
      )
      ..drawCircle(
        center,
        coreRect.shortestSide * 0.15,
        Paint()..color = color.withValues(alpha: 0.72),
      )
      ..drawArc(
        ui.Rect.fromCircle(
          center: center,
          radius: coreRect.shortestSide * 0.27,
        ),
        -math.pi / 2,
        math.pi * 2 * ratio,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    for (final direction in RelayDirection.values) {
      final point = ReplayCircuitGeometry.corePortAnchor(direction, rect);
      canvas
        ..drawCircle(
          point,
          5,
          Paint()..color = const Color(0xFF07161C),
        )
        ..drawCircle(
          point,
          3.2,
          Paint()..color = RelayColors.amber,
        );
    }
    _drawText(
      canvas,
      'ÇEKİRDEK',
      ui.Offset(center.dx, coreRect.top + 7),
      color: color,
      size: math.max(7.0, cellSize * 0.12),
      centered: true,
      maxWidth: coreRect.width - 8,
    );
    _drawText(
      canvas,
      'Can: ${hp.toStringAsFixed(0)}/${maxHp.toStringAsFixed(0)}',
      ui.Offset(center.dx, coreRect.bottom - 17),
      color: Colors.white70,
      size: math.max(7.0, cellSize * 0.11),
      centered: true,
      maxWidth: coreRect.width - 8,
    );
  }

  void _drawPulse(
    ui.Canvas canvas,
    _VisualPulse pulse, {
    required ui.Rect leftBoard,
    required ui.Rect rightBoard,
    required ui.Offset leftCore,
    required ui.Offset rightCore,
  }) {
    final event = pulse.event;
    final from = _modulePoint(
          event.actorId,
          event.side == 'left' ? match.playerBoard : match.opponentBoard,
          event.side == 'left' ? leftBoard : rightBoard,
        ) ??
        (event.side == 'left' ? leftCore : rightCore);
    final targetOnEnemy = event.type == 'attack' ||
        event.type == 'destroyed' ||
        event.type == 'core_damage' ||
        event.type == 'shield_absorb';
    final targetBoard = targetOnEnemy
        ? (event.side == 'left' ? match.opponentBoard : match.playerBoard)
        : (event.side == 'left' ? match.playerBoard : match.opponentBoard);
    final targetRect = targetOnEnemy
        ? (event.side == 'left' ? rightBoard : leftBoard)
        : (event.side == 'left' ? leftBoard : rightBoard);
    final targetCore = event.side == 'left' ? rightCore : leftCore;
    final to = event.type == 'core_damage'
        ? targetCore
        : _modulePoint(event.targetId, targetBoard, targetRect) ??
            (targetOnEnemy ? targetRect.center : from);
    final opacity = pulse.life.clamp(0.0, 1.0).toDouble();
    final color = pulse.color.withValues(alpha: opacity);

    if (pulse.isBeam) {
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = color
          ..strokeWidth = 2 + 5 * opacity
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(to, 5 + 8 * opacity, Paint()..color = color);
      return;
    }
    canvas.drawCircle(
      to,
      12 + (1 - opacity) * 26,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  ui.Offset? _modulePoint(
    String? id,
    BoardDraft board,
    ui.Rect rect,
  ) {
    if (id == null) {
      return null;
    }
    for (final module in board.modules) {
      if (module.id == id) {
        final cellSize = rect.width / 4;
        return ui.Offset(
          rect.left + (module.column + 0.5) * cellSize,
          rect.top + (module.row + 0.5) * cellSize,
        );
      }
    }
    return null;
  }

  String _moduleCode(ModuleKind kind) => switch (kind) {
        ModuleKind.generator => 'JN',
        ModuleKind.battery => 'BT',
        ModuleKind.laser => 'LZ',
        ModuleKind.pulseCannon => 'DT',
        ModuleKind.shield => 'KL',
        ModuleKind.cooler => 'SĞ',
        ModuleKind.amplifier => 'GÇ',
        ModuleKind.repair => 'ON',
      };

  void _drawText(
    ui.Canvas canvas,
    String text,
    ui.Offset offset, {
    required Color color,
    required double size,
    bool centered = false,
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(
        maxWidth: maxWidth ?? math.max(80.0, this.size.x * 0.74),
      );
    final paintOffset = centered
        ? ui.Offset(offset.dx - painter.width / 2, offset.dy)
        : offset;
    painter.paint(canvas, paintOffset);
  }

  String _resultLabel(String? winner) => switch (winner) {
        'left' => 'ZAFER',
        'right' => 'YENİLGİ',
        _ => 'BERABERE',
      };
}

class _VisualPulse {
  _VisualPulse({
    required this.event,
    required this.color,
    required this.isBeam,
  });

  factory _VisualPulse.fromEvent(BattleEvent event) {
    return _VisualPulse(
      event: event,
      color: switch (event.type) {
        'attack' || 'core_damage' => RelayColors.coral,
        'shield' || 'shield_absorb' => const Color(0xFF74A7FF),
        'cool' => RelayColors.cyan,
        'repair' || 'recovered' => RelayColors.mint,
        'overheat' => RelayColors.amber,
        'destroyed' => RelayColors.coral,
        _ => RelayColors.muted,
      },
      isBeam: event.type == 'attack' || event.type == 'core_damage',
    );
  }

  final BattleEvent event;
  final Color color;
  final bool isBeam;
  double life = 1;
}

class _ModuleDelta {
  const _ModuleDelta({
    this.hp = 0,
    this.heat = 0,
  });

  final double hp;
  final double heat;
}
