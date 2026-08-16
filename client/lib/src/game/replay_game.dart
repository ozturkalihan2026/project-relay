import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/circuit_cable.dart';
import '../theme/circuit_presentation.dart';
import '../theme/cosmetic_visuals.dart';
import '../theme/relay_theme.dart';
import '../widgets/module_visuals.dart';
import '../widgets/relay_emblem.dart';
import 'replay_event_formatter.dart';
import 'replay_timeline.dart';

abstract final class ReplayStageGeometry {
  static const double maxBoardExtent = 488;

  static double boardExtent(ui.Size size) =>
      math.min(maxBoardExtent, math.min(size.width * 0.36, size.height * 0.78));

  static double sideInset(ui.Size size) => math.max(20.0, size.width * 0.025);

  static double boardTop(ui.Size size, double boardExtent) =>
      math.max(70.0, (size.height - boardExtent) / 2 - 6);

  static ui.Rect leftBoard(ui.Size size) {
    final extent = boardExtent(size);
    return ui.Rect.fromLTWH(
      sideInset(size),
      boardTop(size, extent),
      extent,
      extent,
    );
  }

  static ui.Rect rightBoard(ui.Size size) {
    final extent = boardExtent(size);
    return ui.Rect.fromLTWH(
      size.width - sideInset(size) - extent,
      boardTop(size, extent),
      extent,
      extent,
    );
  }

  static const double perspectiveShear =
      CircuitPresentationSpec.battlePerspectiveShear;
  static const double platformDepth = CircuitPresentationSpec.platformDepth;

  static ui.Offset perspectivePoint(
    ui.Offset point,
    ui.Rect boardRect, {
    required bool leftSide,
  }) {
    final shear = leftSide ? perspectiveShear : -perspectiveShear;
    return ui.Offset(
      point.dx + shear * (point.dy - boardRect.center.dy),
      point.dy,
    );
  }

  static ui.Path boardFacePath(ui.Rect rect, {required bool leftSide}) {
    final topLeft = perspectivePoint(rect.topLeft, rect, leftSide: leftSide);
    final topRight = perspectivePoint(rect.topRight, rect, leftSide: leftSide);
    final bottomRight = perspectivePoint(
      rect.bottomRight,
      rect,
      leftSide: leftSide,
    );
    final bottomLeft = perspectivePoint(
      rect.bottomLeft,
      rect,
      leftSide: leftSide,
    );
    return ui.Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
  }
}

abstract final class ReplayCircuitGeometry {
  static ui.Rect moduleRect(ModulePlacement module, ui.Rect boardRect) {
    final cellSize = boardRect.width / CircuitPresentationSpec.gridSize;
    return ui.Rect.fromLTWH(
      boardRect.left + module.column * cellSize,
      boardRect.top + module.row * cellSize,
      cellSize,
      cellSize,
    ).deflate(CircuitPresentationSpec.cellInset);
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
    final extent = boardRect.width * CircuitPresentationSpec.coreExtentFactor;
    return ui.Rect.fromCenter(
      center: boardRect.center,
      width: extent,
      height: extent,
    );
  }

  static ui.Offset corePortAnchor(
    RelayDirection gateDirection,
    ui.Rect boardRect,
  ) {
    final cellSize = boardRect.width / CircuitPresentationSpec.gridSize;
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
    required MatchResponse match,
    required this.replay,
    required this.moduleSpecs,
    required this.formatter,
    required this.onFrame,
    required this.onEvents,
    this.leftVisuals = const EquippedVisuals.defaults(),
    this.rightVisuals = const EquippedVisuals.defaults(),
    this.moduleUpgradeBranches = const {},
  }) : live = false,
       match = match,
       _cursor = ReplayPlaybackCursor(replay.events),
       _leftHp = match.result.left.coreMaxHp,
       _rightHp = match.result.right.coreMaxHp {
    _leftCoreMaxHp = match.result.left.coreMaxHp;
    _rightCoreMaxHp = match.result.right.coreMaxHp;
    _rightLabel = match.opponent.displayName.toUpperCase();
    _leftLayout = match.playerBoard;
    _rightLayout = match.opponentBoard;
    for (final module in [
      ...match.playerBoard.modules,
      ...match.opponentBoard.modules,
    ]) {
      _knownPlacements[module.id] = module;
    }
    for (final summary in match.result.left.modules) {
      _leftModuleHp[summary.id] = summary.maxHp;
      _moduleMaxHp[summary.id] = summary.maxHp;
    }
    for (final summary in match.result.right.modules) {
      _rightModuleHp[summary.id] = summary.maxHp;
      _moduleMaxHp[summary.id] = summary.maxHp;
    }
    final initialFrame = replay.stateAt(0);
    _leftBoardState =
        initialFrame?.left ?? _initialBoardState(match.result.left);
    _rightBoardState =
        initialFrame?.right ?? _initialBoardState(match.result.right);
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

  /// Canlı savaş modu: tüm kareler önceden yüklenmiş bir replay yerine
  /// [feedLiveFrame] ile dışarıdan beslenir; kursor oynatması yapılmaz.
  RelayReplayGame.live({
    required BoardDraft playerBoard,
    required BoardDraft opponentBoard,
    required ReplayStateFrame initialFrame,
    required String opponentName,
    required double leftCoreMaxHp,
    required double rightCoreMaxHp,
    required this.moduleSpecs,
    required this.formatter,
    required this.onFrame,
    required this.onEvents,
    this.leftVisuals = const EquippedVisuals.defaults(),
    this.rightVisuals = const EquippedVisuals.defaults(),
    this.moduleUpgradeBranches = const {},
  }) : live = true,
       match = null,
       replay = const ReplayResponse(
         matchId: '',
         rulesVersion: '',
         checksum: '',
         events: [],
         stateFrames: [],
       ),
       _cursor = ReplayPlaybackCursor(const []),
       _leftHp = leftCoreMaxHp,
       _rightHp = rightCoreMaxHp {
    _leftCoreMaxHp = leftCoreMaxHp;
    _rightCoreMaxHp = rightCoreMaxHp;
    _rightLabel = opponentName.toUpperCase();
    _leftLayout = playerBoard;
    _rightLayout = opponentBoard;
    for (final module in [...playerBoard.modules, ...opponentBoard.modules]) {
      _knownPlacements[module.id] = module;
    }
    for (final module in initialFrame.left.modules) {
      _leftModuleHp[module.id] = module.hp;
      _moduleMaxHp[module.id] = module.maxHp;
    }
    for (final module in initialFrame.right.modules) {
      _rightModuleHp[module.id] = module.hp;
      _moduleMaxHp[module.id] = module.maxHp;
    }
    _leftBoardState = initialFrame.left;
    _rightBoardState = initialFrame.right;
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
    _tick = initialFrame.tick;
  }

  final MatchResponse? match;
  final ReplayResponse replay;
  final bool live;
  final Map<ModuleKind, ModuleSpec> moduleSpecs;
  final ReplayEventFormatter formatter;
  final ValueChanged<ReplaySnapshot> onFrame;
  final ValueChanged<List<BattleEvent>> onEvents;
  final EquippedVisuals leftVisuals;
  final EquippedVisuals rightVisuals;
  final Map<String, String> moduleUpgradeBranches;
  final ReplayPlaybackCursor _cursor;
  final List<_VisualPulse> _pulses = [];
  final Map<String, double> _leftModuleHp = {};
  final Map<String, double> _rightModuleHp = {};
  final Map<String, double> _moduleMaxHp = {};
  final Map<String, ModuleReplayState> _leftModuleStates = {};
  final Map<String, ModuleReplayState> _rightModuleStates = {};
  final Map<String, _ModuleDelta> _leftModuleDeltas = {};
  final Map<String, _ModuleDelta> _rightModuleDeltas = {};
  final Map<String, ModulePlacement> _knownPlacements = {};
  final Map<String, double> _moduleActionStartedAt = {};
  final Set<String> _destroyedIds = {};
  late BoardReplayState _leftBoardState;
  late BoardReplayState _rightBoardState;
  late BoardDraft _leftLayout;
  late BoardDraft _rightLayout;
  late double _leftCoreMaxHp;
  late double _rightCoreMaxHp;
  late String _rightLabel;

  static const _defaultFrameDelay = 0.58;
  double speed = 1;
  double _elapsed = 0;
  double _frameDelay = _defaultFrameDelay;
  double _animationTime = 0;
  double _leftHp;
  double _rightHp;
  int _tick = 0;
  int _processedEventCount = 0;
  String _lastEvent = 'Sistemler hazırlanıyor';
  BattleEvent? _lastEventData;
  bool _completionSent = false;
  bool _complete = false;

  @visibleForTesting
  BoardDraft get debugLeftLayout => _leftLayout;

  @visibleForTesting
  int get debugPulseCount => _pulses.length;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt * speed;
    _animationTime += dt * speed;
    if (!live) {
      while (_elapsed >= _frameDelay && !_cursor.isComplete) {
        _elapsed -= _frameDelay;
        final frame = _cursor.next();
        if (frame != null) {
          _applyFrame(frame);
        }
      }
    }

    for (final pulse in _pulses) {
      pulse.life -= dt * speed;
    }
    _pulses.removeWhere((pulse) => pulse.life <= 0);

    if (!live && _cursor.isComplete && !_completionSent) {
      _completionSent = true;
      _tick = match!.result.ticks;
      final finalFrame = replay.stateAt(match!.result.ticks);
      if (finalFrame != null) {
        _setReplayState(finalFrame);
      }
      _leftHp = match!.result.left.coreHp;
      _rightHp = match!.result.right.coreHp;
      onFrame(
        ReplaySnapshot(
          tick: _tick,
          leftHp: _leftHp,
          rightHp: _rightHp,
          lastEvent: _resultLabel(match!.result.winner),
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
      _applyModuleSwapLayout(event);
      if (stateFrame == null) {
        _applyEventState(event);
      }
      _pulses.add(
        _VisualPulse.fromEvent(
          event,
          attackColor: event.side == 'left'
              ? leftVisuals.modules.attack
              : rightVisuals.modules.attack,
        ),
      );
      _lastEventData = event;
      _moduleActionStartedAt[event.actorId] = _animationTime;
      _lastEvent = formatter.eventLabel(event);
      _processedEventCount += 1;
    }
    _frameDelay = _delayFor(frame.events);
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

  /// Canlı savaşta sunucudan gelen kareyi ve bu karedeki yeni olayları işler.
  void feedLiveFrame({
    required ReplayStateFrame frame,
    required List<BattleEvent> newEvents,
  }) {
    assert(live);
    _tick = frame.tick;
    _setReplayState(frame);
    _leftCoreMaxHp = math.max(_leftCoreMaxHp, frame.left.coreHp);
    _rightCoreMaxHp = math.max(_rightCoreMaxHp, frame.right.coreHp);
    for (final event in newEvents) {
      _applyModuleSwapLayout(event);
      _pulses.add(
        _VisualPulse.fromEvent(
          event,
          attackColor: event.side == 'left'
              ? leftVisuals.modules.attack
              : rightVisuals.modules.attack,
        ),
      );
      _lastEventData = event;
      _moduleActionStartedAt[event.actorId] = _animationTime;
      _lastEvent = formatter.eventLabel(event);
      _processedEventCount += 1;
    }
    onEvents(newEvents);
    onFrame(
      ReplaySnapshot(
        tick: _tick,
        leftHp: _leftHp,
        rightHp: _rightHp,
        lastEvent: _lastEvent,
        visibleEventCount: _processedEventCount,
        complete: _complete,
      ),
    );
  }

  /// Canlı savaş tamamlandığında son kareye işaret eden bildirimi yayınlar.
  void markLiveComplete({required int finalTick, required String resultLabel}) {
    assert(live);
    _complete = true;
    _tick = finalTick;
    _lastEvent = resultLabel;
    onFrame(
      ReplaySnapshot(
        tick: _tick,
        leftHp: _leftHp,
        rightHp: _rightHp,
        lastEvent: resultLabel,
        visibleEventCount: _processedEventCount,
        complete: true,
      ),
    );
  }

  void _applyModuleSwapLayout(BattleEvent event) {
    if (event.type != 'module_swap' || event.targetId == null) return;
    final current = event.side == 'left' ? _leftLayout : _rightLayout;
    final outgoingIndex = current.modules.indexWhere(
      (module) => module.id == event.targetId,
    );
    if (outgoingIndex < 0) return;
    final fields = <String, String>{};
    for (final field in (event.detail ?? '').split(';')) {
      final separator = field.indexOf('=');
      if (separator <= 0 || separator == field.length - 1) continue;
      fields[field.substring(0, separator)] = field.substring(separator + 1);
    }
    final row = int.tryParse(fields['row'] ?? '');
    final column = int.tryParse(fields['column'] ?? '');
    if (row == null || column == null || fields['kind'] == null) return;
    try {
      final previous = _knownPlacements[event.actorId];
      final incoming = ModulePlacement(
        id: event.actorId,
        kind: ModuleKind.parse(fields['kind']!),
        row: row,
        column: column,
        orientation: RelayDirection.parse(fields['orientation'] ?? 'east'),
        level: previous?.level ?? 1,
      );
      _knownPlacements[incoming.id] = incoming;
      final modules = List<ModulePlacement>.from(current.modules);
      modules[outgoingIndex] = incoming;
      final next = BoardDraft(name: current.name, modules: modules);
      if (event.side == 'left') {
        _leftLayout = next;
      } else {
        _rightLayout = next;
      }
    } on FormatException {
      // Bozuk eski replay ayrıntısı görsel akışı durdurmamalıdır.
    }
  }

  double _delayFor(List<BattleEvent> events) {
    if (events.any(
      (event) => event.type == 'destroyed' || event.type == 'core_damage',
    )) {
      return 1.42;
    }
    if (events.any((event) => event.type == 'shield_absorb')) return 1.02;
    if (events.any((event) => event.type == 'attack')) return 0.92;
    if (events.any(
      (event) => event.type == 'repair' || event.type == 'shield',
    )) {
      return 0.84;
    }
    return _defaultFrameDelay;
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
    final previousStates = Map<String, ModuleReplayState>.from(states);
    states
      ..clear()
      ..addEntries(board.modules.map((module) => MapEntry(module.id, module)));
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
      final targetHp = event.side == 'left' ? _rightModuleHp : _leftModuleHp;
      final targetDeltas = event.side == 'left'
          ? _rightModuleDeltas
          : _leftModuleDeltas;
      final current = targetHp[targetId];
      if (current != null) {
        targetHp[targetId] = math.max(0.0, current - event.amount);
        targetDeltas[targetId] = _ModuleDelta(hp: -event.amount, heat: 0);
      }
    } else if (event.type == 'repair') {
      final targetHp = event.side == 'left' ? _leftModuleHp : _rightModuleHp;
      final targetDeltas = event.side == 'left'
          ? _leftModuleDeltas
          : _rightModuleDeltas;
      final current = targetHp[targetId];
      final maximum = _moduleMaxHp[targetId];
      if (current != null && maximum != null) {
        targetHp[targetId] = math.min(maximum, current + event.amount);
        targetDeltas[targetId] = _ModuleDelta(hp: event.amount, heat: 0);
      }
    } else if (event.type == 'destroyed') {
      _destroyedIds.add(targetId);
      final targetHp = event.side == 'left' ? _rightModuleHp : _leftModuleHp;
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
      Paint()..color = const Color(0xFF071B24),
    );
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width, height),
      Paint()
        ..shader = ui.Gradient.radial(
          ui.Offset(width / 2, height * 0.48),
          math.max(width, height) * 0.62,
          [const Color(0xFF123C49).withValues(alpha: 0.58), Colors.transparent],
        ),
    );
    _drawCircuitBackground(canvas, width, height);

    final stageSize = ui.Size(width, height);
    final leftBoard = ReplayStageGeometry.leftBoard(stageSize);
    final rightBoard = ReplayStageGeometry.rightBoard(stageSize);
    final leftCore = leftBoard.center;
    final rightCore = rightBoard.center;

    _drawBoardPlatform(
      canvas,
      rect: leftBoard,
      leftSide: true,
      accent: leftVisuals.board.core,
      visuals: leftVisuals,
    );
    _drawPerspectiveBoard(
      canvas,
      leftSide: true,
      rect: leftBoard,
      draw: () => _drawBoard(
        canvas,
        rect: leftBoard,
        board: _leftLayout,
        hp: _leftModuleHp,
        states: _leftModuleStates,
        deltas: _leftModuleDeltas,
        boardState: _leftBoardState,
        color: leftVisuals.board.core,
        label: 'SEN',
        visuals: leftVisuals,
        coreHp: _leftHp,
        coreMaxHp: _leftCoreMaxHp,
      ),
    );
    _drawBoardPlatform(
      canvas,
      rect: rightBoard,
      leftSide: false,
      accent: RelayColors.coral,
      visuals: rightVisuals,
    );
    _drawPerspectiveBoard(
      canvas,
      leftSide: false,
      rect: rightBoard,
      draw: () => _drawBoard(
        canvas,
        rect: rightBoard,
        board: _rightLayout,
        hp: _rightModuleHp,
        states: _rightModuleStates,
        deltas: _rightModuleDeltas,
        boardState: _rightBoardState,
        color: RelayColors.coral,
        label: _rightLabel,
        visuals: rightVisuals,
        coreHp: _rightHp,
        coreMaxHp: _rightCoreMaxHp,
      ),
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
      'SİNYAL AKIŞI • CANLI',
      ui.Offset(width / 2, 12),
      color: RelayColors.muted,
      size: 12,
      centered: true,
    );
  }

  void _drawPerspectiveBoard(
    ui.Canvas canvas, {
    required bool leftSide,
    required ui.Rect rect,
    required void Function() draw,
  }) {
    final shear = leftSide
        ? ReplayStageGeometry.perspectiveShear
        : -ReplayStageGeometry.perspectiveShear;
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.skew(shear, 0);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    draw();
    canvas.restore();
  }

  void _drawBoardPlatform(
    ui.Canvas canvas, {
    required ui.Rect rect,
    required bool leftSide,
    required Color accent,
    required EquippedVisuals visuals,
  }) {
    final face = ReplayStageGeometry.boardFacePath(rect, leftSide: leftSide);
    final depth = ReplayStageGeometry.platformDepth;
    final shifted = face.shift(ui.Offset(0, depth));
    canvas.drawPath(
      shifted,
      Paint()
        ..color = const Color(0xAA071017)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10),
    );
    final bottomLeft = ReplayStageGeometry.perspectivePoint(
      rect.bottomLeft,
      rect,
      leftSide: leftSide,
    );
    final bottomRight = ReplayStageGeometry.perspectivePoint(
      rect.bottomRight,
      rect,
      leftSide: leftSide,
    );
    final side = ui.Path()
      ..moveTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy + depth)
      ..lineTo(bottomLeft.dx, bottomLeft.dy + depth)
      ..close();
    canvas.drawPath(
      side,
      Paint()
        ..color = Color.alphaBlend(
          accent.withValues(alpha: 0.16),
          const Color(0xFF091820),
        ),
    );
    canvas.drawPath(
      face,
      Paint()
        ..color = accent.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
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

    // Savaş alanını boş bir ızgara olmaktan çıkaran yavaş tarama ve enerji düğümleri.
    final scanPhase = (_animationTime * 0.11) % 1;
    final scanX = width * scanPhase;
    canvas.drawRect(
      ui.Rect.fromLTWH(scanX - 34, 0, 68, height),
      Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(scanX - 34, 0),
          ui.Offset(scanX + 34, 0),
          [
            Colors.transparent,
            RelayColors.cyan.withValues(alpha: 0.055),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        ),
    );
    for (var index = 0; index < 12; index += 1) {
      final phase =
          ((_animationTime * (0.08 + index * 0.004)) + index * 0.137) % 1;
      final x = width * phase;
      final lane = (index * 37) % 9 + 1;
      final y = height * lane / 10;
      final color = index % 3 == 0
          ? RelayColors.amber
          : index % 3 == 1
          ? RelayColors.cyan
          : RelayColors.violet;
      final glow = 0.55 + 0.45 * math.sin((_animationTime * 2.1) + index);
      canvas.drawCircle(
        ui.Offset(x, y),
        5.5,
        Paint()..color = color.withValues(alpha: 0.045 * glow),
      );
      canvas.drawCircle(
        ui.Offset(x, y),
        1.6,
        Paint()..color = color.withValues(alpha: 0.42 * glow),
      );
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
    required EquippedVisuals visuals,
    required double coreHp,
    required double coreMaxHp,
  }) {
    final cellSize = rect.width / CircuitPresentationSpec.gridSize;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        rect,
        const ui.Radius.circular(CircuitPresentationSpec.boardCornerRadius),
      ),
      Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          Color.alphaBlend(
            color.withValues(alpha: 0.13),
            visuals.board.background,
          ),
          visuals.board.background,
        ]),
    );
    final boardBreath = 0.34 + 0.16 * math.sin(_animationTime * math.pi * 1.6);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        rect.inflate(1.5),
        const ui.Radius.circular(CircuitPresentationSpec.boardCornerRadius + 1),
      ),
      Paint()
        ..color = color.withValues(alpha: boardBreath)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    for (var row = 0; row < CircuitPresentationSpec.gridSize; row += 1) {
      for (
        var column = 0;
        column < CircuitPresentationSpec.gridSize;
        column += 1
      ) {
        final cell = ui.Rect.fromLTWH(
          rect.left + column * cellSize,
          rect.top + row * cellSize,
          cellSize,
          cellSize,
        ).deflate(CircuitPresentationSpec.boardBorderWidth);
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            cell,
            const ui.Radius.circular(CircuitPresentationSpec.cellCornerRadius),
          ),
          Paint()
            ..color = visuals.board.cell
            ..style = PaintingStyle.fill,
        );
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            cell,
            const ui.Radius.circular(CircuitPresentationSpec.cellCornerRadius),
          ),
          Paint()
            ..color = visuals.board.border.withValues(alpha: 0.78)
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
      visuals: visuals,
    );

    _drawBoardCore(
      canvas,
      rect: rect,
      color: color,
      hp: coreHp,
      maxHp: coreMaxHp,
      visuals: visuals,
    );

    for (final module in board.modules) {
      final cell = ReplayCircuitGeometry.moduleRect(module, rect);
      final moduleColorValue = visuals.modules.moduleColorFor(module.kind);
      final upgradeBranch = moduleUpgradeBranches[module.id];
      final upgradeColor = upgradeBranch == 'overclock'
          ? RelayColors.amber
          : upgradeBranch == 'efficient'
          ? RelayColors.mint
          : null;
      final state = states[module.id];
      final delta = deltas[module.id] ?? const _ModuleDelta();
      final currentHp = hp[module.id] ?? state?.hp ?? 0;
      final destroyed = currentHp <= 0;
      final active =
          _lastEventData?.actorId == module.id ||
          _lastEventData?.targetId == module.id;
      final isActor = _lastEventData?.actorId == module.id;
      final isTarget = _lastEventData?.targetId == module.id;
      final chassisDepth = math.max(
        CircuitPresentationSpec.compactModuleDepth,
        cellSize * CircuitPresentationSpec.battleModuleDepthFactor,
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          cell.shift(ui.Offset(0, chassisDepth)),
          const ui.Radius.circular(7),
        ),
        Paint()
          ..color = Color.alphaBlend(
            moduleColorValue.withValues(alpha: destroyed ? 0.04 : 0.16),
            const Color(0xFF02080B),
          ),
      );
      if (!destroyed) {
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            cell.shift(ui.Offset(0, chassisDepth * 0.62)),
            const ui.Radius.circular(7),
          ),
          Paint()
            ..color = moduleColorValue.withValues(alpha: 0.20)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
      if (active && !destroyed) {
        final activeColor = isTarget && delta.hp < 0
            ? RelayColors.coral
            : isActor
            ? RelayColors.amber
            : moduleColorValue;
        final activePulse =
            0.45 + 0.35 * math.sin(_animationTime * math.pi * 5.5);
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            cell.inflate(4),
            const ui.Radius.circular(9),
          ),
          Paint()
            ..color = activeColor.withValues(alpha: 0.14 * activePulse)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7),
        );
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            cell.inflate(2),
            const ui.Radius.circular(8),
          ),
          Paint()
            ..color = activeColor.withValues(alpha: 0.60 * activePulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (delta.hp < 0 && !destroyed) {
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            cell.deflate(2),
            const ui.Radius.circular(6),
          ),
          Paint()..color = RelayColors.coral.withValues(alpha: 0.10),
        );
      } else if (delta.hp > 0 && !destroyed) {
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            cell.deflate(2),
            const ui.Radius.circular(6),
          ),
          Paint()..color = RelayColors.mint.withValues(alpha: 0.10),
        );
      }
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(cell, const ui.Radius.circular(6)),
        Paint()
          ..shader = ui.Gradient.linear(cell.topCenter, cell.bottomCenter, [
            moduleColorValue.withValues(alpha: destroyed ? 0.05 : 0.32),
            const Color(0xFF061116).withValues(alpha: destroyed ? 0.80 : 0.96),
          ]),
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(cell, const ui.Radius.circular(6)),
        Paint()
          ..color = active ? RelayColors.amber : moduleColorValue
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 3 : 1.5,
      );
      if (upgradeColor != null) {
        final upgradePulse = 0.72 + 0.28 * math.sin(_animationTime * 3.4).abs();
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            cell.inflate(3),
            const ui.Radius.circular(9),
          ),
          Paint()
            ..color = upgradeColor.withValues(alpha: 0.72 * upgradePulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = upgradeBranch == 'overclock' ? 2.6 : 2.0,
        );
        canvas.drawCircle(
          cell.topLeft + const ui.Offset(9, 9),
          4.5,
          Paint()..color = upgradeColor.withValues(alpha: upgradePulse),
        );
      }
      _drawModulePorts(
        canvas,
        boardRect: rect,
        module: module,
        powered: state?.powered ?? false,
        destroyed: destroyed,
        visuals: visuals,
      );
      _drawModuleHardware(
        canvas,
        module.kind,
        ui.Offset(cell.center.dx, cell.top + math.max(18.0, cellSize * 0.20)),
        color: destroyed ? RelayColors.muted : moduleColorValue,
        size: math.max(28.0, cellSize * 0.34),
      );
      if (!destroyed) {
        final actionStartedAt = _moduleActionStartedAt[module.id];
        final actionProgress = actionStartedAt == null
            ? 1.0
            : ((_animationTime - actionStartedAt) / 0.64)
                  .clamp(0.0, 1.0)
                  .toDouble();
        _drawModuleMechanism(
          canvas,
          kind: module.kind,
          cell: cell,
          color: moduleColorValue,
          powered: state?.powered ?? false,
          overheated: state?.overheated ?? false,
          actionProgress: actionProgress,
        );
      }

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
          state.cooldown > 0 ? 'Doluyor: ${state.cooldown}' : 'Hazır',
          ui.Offset(cell.center.dx, cell.center.dy + 20),
          color: state.cooldown > 0 ? RelayColors.amber : Colors.white54,
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
        final flicker =
            0.32 +
            0.22 * math.sin(_animationTime * 5.2 + cell.center.dx * 0.01);
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            cell.deflate(3),
            const ui.Radius.circular(6),
          ),
          Paint()..color = const Color(0xFF071017).withValues(alpha: 0.72),
        );
        canvas.drawCircle(
          cell.center,
          math.max(8.0, cellSize * 0.13),
          Paint()
            ..color = RelayColors.coral.withValues(alpha: 0.10 * flicker)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
        );
        _drawText(
          canvas,
          'ENERJİ SÖNDÜ',
          ui.Offset(cell.center.dx, cell.bottom - 18),
          color: RelayColors.muted.withValues(alpha: 0.72),
          size: math.max(5.2, cellSize * 0.068),
          centered: true,
          maxWidth: cell.width - 6,
        );
      }
    }

    _drawText(
      canvas,
      label,
      ui.Offset(rect.center.dx, rect.top - 37),
      color: color,
      size: 14,
      centered: true,
      maxWidth: rect.width,
      fontWeight: FontWeight.w900,
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
    required EquippedVisuals visuals,
  }) {
    final spec = moduleSpecs[module.kind];
    if (spec == null) {
      return;
    }
    for (final direction in usableBoardPorts(
      module,
      spec.worldPorts(module.orientation),
    )) {
      final point = ReplayCircuitGeometry.modulePortAnchor(
        module,
        direction,
        boardRect,
      );
      if (powered && !destroyed) {
        final portPulse =
            0.62 +
            0.38 *
                math
                    .sin(_animationTime * math.pi * 4 + module.cellIndex * 0.7)
                    .abs();
        canvas.drawCircle(
          point,
          6.5,
          Paint()
            ..color = visuals.modules.accent.withValues(alpha: 0.16 * portPulse)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
        );
      }
      canvas
        ..drawCircle(point, 4, Paint()..color = const Color(0xFF07161C))
        ..drawCircle(
          point,
          powered && !destroyed ? 2.9 : 2.5,
          Paint()
            ..color = destroyed
                ? RelayColors.muted.withValues(alpha: 0.45)
                : powered
                ? visuals.modules.accent
                : RelayColors.muted,
        );
    }
  }

  void _drawEnergyTransmission(
    ui.Canvas canvas, {
    required ui.Rect rect,
    required BoardDraft board,
    required Map<String, ModuleReplayState> states,
    required EquippedVisuals visuals,
  }) {
    final installed = board.modules.toList(growable: false);
    final powered = installed
        .where(
          (module) =>
              (states[module.id]?.powered ?? false) &&
              (states[module.id]?.hp ?? 0) > 0,
        )
        .toList(growable: false);
    final poweredIds = powered.map((module) => module.id).toSet();
    final generators = powered
        .where((module) => module.kind == ModuleKind.generator)
        .toList(growable: false);

    final distances = <String, int>{
      for (final generator in generators) generator.id: 0,
    };
    final frontier = <ModulePlacement>[...generators];
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
    for (var firstIndex = 0; firstIndex < installed.length; firstIndex += 1) {
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < installed.length;
        secondIndex += 1
      ) {
        var fromModule = installed[firstIndex];
        var toModule = installed[secondIndex];
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
        final phase = ((_animationTime * 1.65 + linkIndex * 0.27) % 1)
            .toDouble();
        final glow =
            0.65 + 0.35 * math.sin((_animationTime + linkIndex) * math.pi * 2);
        final energized =
            poweredIds.contains(fromModule.id) &&
            poweredIds.contains(toModule.id) &&
            distances.containsKey(fromModule.id) &&
            distances.containsKey(toModule.id);

        _drawEnergyLink(
          canvas,
          from: from,
          to: to,
          color: energized
              ? _flowColor(source: fromModule, target: toModule)
              : visuals.board.traceMuted,
          phase: phase,
          glow: glow,
          energized: energized,
          bidirectional:
              fromModule.kind == ModuleKind.battery ||
              toModule.kind == ModuleKind.battery,
        );
        linkIndex += 1;
      }
    }

    for (final module in installed.where(_moduleHasCorePort)) {
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
      final phase = ((_animationTime * 1.65 + linkIndex * 0.27) % 1).toDouble();
      final energized =
          poweredIds.contains(module.id) && distances.containsKey(module.id);
      _drawEnergyLink(
        canvas,
        from: from,
        to: to,
        color: energized ? visuals.board.gate : visuals.board.traceMuted,
        phase: phase,
        glow: 1,
        energized: energized,
        stronger: true,
      );
      linkIndex += 1;
    }
  }

  void _drawEnergyLink(
    ui.Canvas canvas, {
    required ui.Offset from,
    required ui.Offset to,
    required Color color,
    required double phase,
    required double glow,
    required bool energized,
    bool stronger = false,
    bool bidirectional = false,
  }) {
    final cable = CircuitCableVisual.path(from, to);
    CircuitCableVisual.drawCable(
      canvas,
      cable,
      color: color,
      energized: energized,
      emphasized: stronger,
    );
    if (!energized) return;

    for (final seed in const [0.0, 0.50]) {
      CircuitCableVisual.drawPacket(
        canvas,
        cable,
        phase: (phase + seed) % 1,
        color: color,
        opacity: glow,
        emphasized: stronger,
      );
    }
    if (bidirectional) {
      CircuitCableVisual.drawPacket(
        canvas,
        cable,
        phase: 1 - ((phase * 0.72) % 1),
        color: color,
        opacity: 0.56 * glow,
        emphasized: stronger,
      );
    }
  }

  Color _flowColor({
    required ModulePlacement source,
    required ModulePlacement target,
  }) => switch (source.kind) {
    ModuleKind.repair => RelayColors.mint,
    ModuleKind.cooler => RelayColors.cyan,
    ModuleKind.amplifier => RelayColors.violet,
    _ when target.kind == ModuleKind.shield => RelayColors.electricBlue,
    _ => RelayColors.amber,
  };

  bool _energyConnected(ModulePlacement first, ModulePlacement second) {
    return _modulesConnected(first, second) ||
        (_moduleHasCorePort(first) && _moduleHasCorePort(second));
  }

  bool _modulesConnected(ModulePlacement first, ModulePlacement second) {
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
        secondSpec.worldPorts(second.orientation).contains(direction.opposite);
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
    required EquippedVisuals visuals,
  }) {
    final cellSize = rect.width / CircuitPresentationSpec.gridSize;
    final coreRect = ReplayCircuitGeometry.coreRect(rect);
    final center = coreRect.center;
    final ratio = (hp / maxHp).clamp(0.0, 1.0).toDouble();
    final criticalPulse = ratio <= 0.35
        ? 0.45 + 0.40 * math.sin(_animationTime * math.pi * 3.6).abs()
        : 0.0;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        coreRect.shift(const ui.Offset(0, 10)),
        const ui.Radius.circular(CircuitPresentationSpec.coreCornerRadius),
      ),
      Paint()
        ..color = Color.alphaBlend(
          color.withValues(alpha: 0.16),
          const Color(0xFF02080B),
        ),
    );
    if (criticalPulse > 0) {
      canvas.drawCircle(
        center,
        coreRect.shortestSide * (0.34 + 0.03 * criticalPulse),
        Paint()
          ..color = RelayColors.coral.withValues(alpha: 0.13 * criticalPulse)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12),
      );
      canvas.drawCircle(
        center,
        coreRect.shortestSide * 0.31,
        Paint()
          ..color = RelayColors.coral.withValues(alpha: 0.52 * criticalPulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }
    canvas
      ..drawRRect(
        ui.RRect.fromRectAndRadius(
          coreRect,
          const ui.Radius.circular(CircuitPresentationSpec.coreCornerRadius),
        ),
        Paint()..color = visuals.board.coreSurface,
      )
      ..drawRRect(
        ui.RRect.fromRectAndRadius(
          coreRect,
          const ui.Radius.circular(CircuitPresentationSpec.coreCornerRadius),
        ),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      )
      ..drawCircle(
        center,
        coreRect.shortestSide * 0.30,
        Paint()
          ..color = color.withValues(
            alpha:
                0.08 +
                0.08 * (0.5 + 0.5 * math.sin(_animationTime * math.pi * 1.8)),
          )
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10),
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
    final emblemPulse =
        0.74 + 0.26 * (0.5 + 0.5 * math.sin(_animationTime * math.pi * 1.55));
    RelayEmblemPainter.drawEmblem(
      canvas,
      center: center,
      radius: coreRect.shortestSide * 0.24,
      accent: color,
      secondary: RelayColors.violet,
      glow: true,
      opacity: emblemPulse,
    );

    for (final direction in RelayDirection.values) {
      final point = ReplayCircuitGeometry.corePortAnchor(direction, rect);
      canvas
        ..drawCircle(point, 5, Paint()..color = const Color(0xFF07161C))
        ..drawCircle(point, 3.2, Paint()..color = visuals.board.gate);
    }
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
    final endpoints = _beamEndpoints(
      event,
      leftBoard: leftBoard,
      rightBoard: rightBoard,
      leftCore: leftCore,
      rightCore: rightCore,
    );
    final from = endpoints.from;
    final to = endpoints.to;
    final opacity = pulse.life.clamp(0.0, 1.0).toDouble();
    final color = pulse.color.withValues(alpha: opacity);

    if (pulse.isBeam) {
      final muzzleRadius = 7 + 10 * opacity;
      canvas.drawCircle(
        from,
        muzzleRadius * 1.65,
        Paint()
          ..color = pulse.color.withValues(alpha: 0.20 * opacity)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        from,
        muzzleRadius,
        Paint()..color = pulse.color.withValues(alpha: 0.62 * opacity),
      );
      canvas.drawCircle(
        from,
        2.8 + 3.2 * opacity,
        Paint()..color = RelayColors.white.withValues(alpha: 0.96 * opacity),
      );
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

  /// Işın ve halka olaylarının sahne koordinatlarını hesaplar. Saldırı ışınları
  /// saldıran modülün hedefe bakan gerçek portundan (namlu/emitör) çıkar ve hedef
  /// modülün kaynağa bakan portuna düşer; kalkan/onarım halkaları hedefte çizilir.
  ({ui.Offset from, ui.Offset to}) _beamEndpoints(
    BattleEvent event, {
    required ui.Rect leftBoard,
    required ui.Rect rightBoard,
    required ui.Offset leftCore,
    required ui.Offset rightCore,
  }) {
    final fromIsLeft = event.side == 'left';
    final fromLayout = fromIsLeft ? _leftLayout : _rightLayout;
    final fromRect = fromIsLeft ? leftBoard : rightBoard;
    final fromModule = _layoutModule(event.actorId, fromLayout);
    final fromCenter = fromModule == null
        ? (fromIsLeft ? leftCore : rightCore)
        : _modulePoint(fromModule.id, fromLayout, fromRect) ??
              (fromIsLeft ? leftCore : rightCore);

    final targetOnEnemy =
        event.type == 'attack' ||
        event.type == 'destroyed' ||
        event.type == 'core_damage' ||
        event.type == 'shield_absorb';
    final targetLayout = targetOnEnemy
        ? (fromIsLeft ? _rightLayout : _leftLayout)
        : fromLayout;
    final targetRect = targetOnEnemy
        ? (fromIsLeft ? rightBoard : leftBoard)
        : fromRect;
    final targetCore = fromIsLeft ? rightCore : leftCore;
    final toModule = _layoutModule(event.targetId, targetLayout);
    final to = event.type == 'core_damage'
        ? targetCore
        : toModule == null
        ? (targetOnEnemy ? targetRect.center : fromCenter)
        : _facingPortPoint(
            module: toModule,
            boardRect: targetRect,
            leftSide: identical(targetLayout, _leftLayout),
            toward: fromCenter,
          );

    final beam = event.type == 'attack' || event.type == 'core_damage';
    final from = beam && fromModule != null
        ? _facingPortPoint(
            module: fromModule,
            boardRect: fromRect,
            leftSide: fromIsLeft,
            toward: to,
          )
        : fromCenter;
    return (from: from, to: to);
  }

  @visibleForTesting
  ({ui.Offset from, ui.Offset to}) debugBeamEndpoints(
    BattleEvent event,
    ui.Size stageSize,
  ) {
    final leftBoard = ReplayStageGeometry.leftBoard(stageSize);
    final rightBoard = ReplayStageGeometry.rightBoard(stageSize);
    return _beamEndpoints(
      event,
      leftBoard: leftBoard,
      rightBoard: rightBoard,
      leftCore: leftBoard.center,
      rightCore: rightBoard.center,
    );
  }

  ModulePlacement? _layoutModule(String? id, BoardDraft board) {
    if (id == null) {
      return null;
    }
    for (final module in board.modules) {
      if (module.id == id) {
        return module;
      }
    }
    return null;
  }

  /// Modülün [toward] yönüne bakan kenarındaki port noktasını döndürür. Savaş
  /// hedeflemesi motor tarafında yönelimden bağımsız yapıldığı için namlu/emitör
  /// görselde hedefe bakan kenarın orta portu olarak çizilir; böylece ışın her
  /// devrede görünür kenardan çıkar ve hedefin karşı kenarına düşer.
  ui.Offset _facingPortPoint({
    required ModulePlacement module,
    required ui.Rect boardRect,
    required bool leftSide,
    required ui.Offset toward,
  }) {
    final center = _modulePoint(
      module.id,
      leftSide ? _leftLayout : _rightLayout,
      boardRect,
    );
    if (center == null) {
      return boardRect.center;
    }
    final direction = _facingDirection(center, toward);
    final raw = ReplayCircuitGeometry.modulePortAnchor(
      module,
      direction,
      boardRect,
    );
    return ReplayStageGeometry.perspectivePoint(
      raw,
      boardRect,
      leftSide: leftSide,
    );
  }

  RelayDirection _facingDirection(ui.Offset from, ui.Offset toward) {
    final delta = toward - from;
    if (delta.dx.abs() >= delta.dy.abs()) {
      return delta.dx >= 0 ? RelayDirection.east : RelayDirection.west;
    }
    return delta.dy >= 0 ? RelayDirection.south : RelayDirection.north;
  }

  ui.Offset? _modulePoint(String? id, BoardDraft board, ui.Rect rect) {
    if (id == null) {
      return null;
    }
    for (final module in board.modules) {
      if (module.id == id) {
        final cellSize = rect.width / CircuitPresentationSpec.gridSize;
        final raw = ui.Offset(
          rect.left + (module.column + 0.5) * cellSize,
          rect.top + (module.row + 0.5) * cellSize,
        );
        return ReplayStageGeometry.perspectivePoint(
          raw,
          rect,
          leftSide: identical(board, _leftLayout),
        );
      }
    }
    return null;
  }

  void _drawModuleMechanism(
    ui.Canvas canvas, {
    required ModuleKind kind,
    required ui.Rect cell,
    required Color color,
    required bool powered,
    required bool overheated,
    required double actionProgress,
  }) {
    final center = ui.Offset(cell.center.dx, cell.top + cell.height * 0.23);
    final phase = _animationTime * (powered ? 3.2 : 1.1);
    final alpha = powered ? 0.88 : 0.32;
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final action = Curves.easeOutCubic.transform(1 - actionProgress);
    switch (kind) {
      case ModuleKind.generator:
        for (var i = 0; i < 3; i++) {
          final angle = phase + i * math.pi * 2 / 3;
          final tip = center + ui.Offset(math.cos(angle), math.sin(angle)) * 10;
          canvas.drawLine(center, tip, paint);
          canvas.drawCircle(
            tip,
            2.2,
            Paint()..color = color.withValues(alpha: alpha),
          );
        }
        canvas.drawCircle(
          center,
          4,
          Paint()..color = color.withValues(alpha: 0.38),
        );
        canvas.drawCircle(
          center,
          7 + 17 * (1 - action),
          Paint()
            ..color = color.withValues(alpha: action * 0.72)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 + action * 2,
        );
        break;
      case ModuleKind.battery:
        for (var i = 0; i < 3; i++) {
          final active = ((_animationTime * 2).floor() + i) % 3;
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(
              ui.Rect.fromLTWH(center.dx - 11 + i * 8, center.dy - 5, 5, 10),
              const ui.Radius.circular(2),
            ),
            Paint()..color = color.withValues(alpha: active == i ? 0.90 : 0.28),
          );
        }
        if (action > 0) {
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(
              ui.Rect.fromCenter(center: center, width: 28, height: 16),
              const ui.Radius.circular(4),
            ),
            Paint()
              ..color = RelayColors.white.withValues(alpha: action * 0.34)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        break;
      case ModuleKind.laser:
        final pulse = 0.45 + 0.45 * math.sin(phase * 1.4).abs();
        final recoil = action * 4;
        final laserCenter = center - ui.Offset(recoil, 0);
        canvas.drawCircle(
          laserCenter,
          5 + pulse * 2,
          Paint()..color = color.withValues(alpha: 0.22 + pulse * 0.38),
        );
        canvas.drawCircle(center, 9, paint);
        canvas.drawCircle(
          laserCenter,
          7 + (1 - action) * 18,
          Paint()
            ..color = color.withValues(alpha: action * 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        canvas.drawCircle(
          laserCenter,
          3 + action * 3,
          Paint()..color = RelayColors.white.withValues(alpha: action * 0.95),
        );
        break;
      case ModuleKind.pulseCannon:
        final recoil = action * 7 + math.sin(phase).abs() * 1.2;
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            ui.Rect.fromCenter(
              center: center + ui.Offset(recoil, 0),
              width: 22,
              height: 7,
            ),
            const ui.Radius.circular(3),
          ),
          Paint()..color = color.withValues(alpha: 0.55),
        );
        canvas.drawCircle(
          center + ui.Offset(11 + recoil, 0),
          4,
          Paint()..color = RelayColors.white.withValues(alpha: 0.55),
        );
        canvas.drawCircle(
          center + ui.Offset(11 + recoil, 0),
          5 + (1 - action) * 20,
          Paint()
            ..color = color.withValues(alpha: action * 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        break;
      case ModuleKind.shield:
        canvas.drawArc(
          ui.Rect.fromCenter(center: center, width: 24, height: 16),
          math.pi,
          math.pi,
          false,
          paint,
        );
        canvas.drawArc(
          ui.Rect.fromCenter(
            center: center,
            width: 24 + (1 - action) * 22,
            height: 16 + (1 - action) * 14,
          ),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = color.withValues(alpha: action * 0.72)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        break;
      case ModuleKind.cooler:
        for (var i = 0; i < 4; i++) {
          final angle = phase + i * math.pi / 2;
          final tip = center + ui.Offset(math.cos(angle), math.sin(angle)) * 9;
          canvas.drawLine(center, tip, paint);
        }
        canvas.drawCircle(
          center,
          3,
          Paint()..color = color.withValues(alpha: 0.65),
        );
        for (var i = 0; i < 3; i++) {
          final drift = (1 - action) * (10 + i * 4);
          canvas.drawCircle(
            center + ui.Offset((i - 1) * 6, -8 - drift),
            2 + action,
            Paint()..color = color.withValues(alpha: action * 0.42),
          );
        }
        break;
      case ModuleKind.amplifier:
        final x = center.dx - 12 + ((_animationTime * 22) % 24);
        canvas.drawLine(
          center + const ui.Offset(-13, 0),
          center + const ui.Offset(13, 0),
          paint,
        );
        canvas.drawCircle(
          ui.Offset(x, center.dy),
          3.2,
          Paint()..color = RelayColors.white.withValues(alpha: 0.76),
        );
        canvas.drawLine(
          center + const ui.Offset(-13, 0),
          center + ui.Offset(13 * action, 0),
          Paint()
            ..color = RelayColors.white.withValues(alpha: action * 0.78)
            ..strokeWidth = 3,
        );
        break;
      case ModuleKind.repair:
        final scan = center.dy - 8 + ((_animationTime * 14) % 16);
        canvas.drawLine(
          ui.Offset(center.dx - 10, scan),
          ui.Offset(center.dx + 10, scan),
          paint,
        );
        canvas.drawCircle(center, 8, paint);
        canvas.drawCircle(
          center,
          5 + (1 - action) * 15,
          Paint()
            ..color = color.withValues(alpha: action * 0.68)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        break;
    }
    if (overheated) {
      for (var i = 0; i < 3; i++) {
        final drift = ((_animationTime * 11 + i * 7) % 15);
        canvas.drawCircle(
          center + ui.Offset((i - 1) * 5.0, -9 - drift),
          2.1,
          Paint()..color = RelayColors.amber.withValues(alpha: 0.50),
        );
      }
    }
  }

  void _drawModuleHardware(
    ui.Canvas canvas,
    ModuleKind kind,
    ui.Offset center, {
    required Color color,
    required double size,
  }) {
    paintModuleHardware(canvas, kind, center, size, color);
  }

  void _drawText(
    ui.Canvas canvas,
    String text,
    ui.Offset offset, {
    required Color color,
    required double size,
    bool centered = false,
    double? maxWidth,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: fontWeight,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? math.max(80.0, this.size.x * 0.74));
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

  factory _VisualPulse.fromEvent(
    BattleEvent event, {
    required Color attackColor,
  }) {
    return _VisualPulse(
      event: event,
      color: switch (event.type) {
        'attack' || 'core_damage' => attackColor,
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
  const _ModuleDelta({this.hp = 0, this.heat = 0});

  final double hp;
  final double heat;
}
