import 'dart:convert';

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_relay_client/src/api/relay_api.dart';
import 'package:project_relay_client/src/api/session_storage.dart';
import 'package:project_relay_client/src/game/replay_event_formatter.dart';
import 'package:project_relay_client/src/game/replay_game.dart';
import 'package:project_relay_client/src/models/relay_models.dart';
import 'package:project_relay_client/src/screens/career_battle_screen.dart';
import 'package:project_relay_client/src/screens/career_live_battle_screen.dart';
import 'package:project_relay_client/src/state/app_settings.dart';
import 'package:project_relay_client/src/theme/cosmetic_visuals.dart';
import 'package:project_relay_client/src/theme/circuit_presentation.dart';

void main() {
  testWidgets('müdahale penceresinde yalnız yedek rafı sürüklenebilir olur', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
      ],
    );
    addTearDown(container.dispose);
    container.read(appSettingsProvider.notifier).setReplaySoundEnabled(false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CareerLiveBattleScreen(
            initialSession: _session(active: true),
            modules: _moduleSpecs,
            visuals: const EquippedVisuals.defaults(),
            stageNumber: 1,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('career-live-intervention-shelf')),
      findsOneWidget,
    );
    expect(find.textContaining('MÜDAHALE RAFI AKTİF'), findsOneWidget);
    final draggables = find.byType(Draggable<ModuleDragData>);
    expect(draggables, findsOneWidget);
    final draggable = tester.widget<Draggable<ModuleDragData>>(draggables);
    expect(draggable.data!.moduleId, 'reserve-shield');
    expect(
      find.byKey(const ValueKey('career-live-battle-stage')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('live-player-board')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pencere kapalıyken raf görünür fakat sürüklenemez', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
      ],
    );
    addTearDown(container.dispose);
    container.read(appSettingsProvider.notifier).setReplaySoundEnabled(false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CareerLiveBattleScreen(
            initialSession: _session(active: false),
            modules: _moduleSpecs,
            visuals: const EquippedVisuals.defaults(),
            stageNumber: 1,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('SİNYAL BEKLENİYOR'), findsOneWidget);
    expect(find.byType(Draggable<ModuleDragData>), findsNothing);
    expect(
      find.byKey(const ValueKey('live-reserve-reserve-shield')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('yedek modül imlecin altındaki modüle bırakılır', (
    tester,
  ) async {
    final fake = _SwapRelayApi();
    final container = ProviderContainer(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        relayApiProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);
    container.read(appSettingsProvider.notifier).setReplaySoundEnabled(false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CareerLiveBattleScreen(
            initialSession: _session(active: true),
            modules: _moduleSpecs,
            visuals: const EquippedVisuals.defaults(),
            stageNumber: 1,
          ),
        ),
      ),
    );
    await tester.pump();

    final stageFinder = find.byKey(
      const ValueKey('career-live-battle-stage'),
    );
    final stageSize = tester.getSize(stageFinder);
    final stageTopLeft = tester.getTopLeft(stageFinder);
    final leftBoard = ReplayStageGeometry.leftBoard(stageSize);
    final cellSize = leftBoard.width / CircuitPresentationSpec.gridSize;

    final laser = _session(active: true).playerBoard.modules.firstWhere(
      (module) => module.id == 'player-laser',
    );
    final center = leftBoard.topLeft +
        Offset(
          (laser.column + 0.5) * cellSize,
          (laser.row + 0.5) * cellSize,
        );
    final shear = ReplayStageGeometry.perspectiveShear;
    final target =
        stageTopLeft +
        Offset(
          center.dx + shear * (center.dy - leftBoard.height / 2),
          center.dy,
        );

    final reserve = find.byKey(
      const ValueKey('live-reserve-reserve-shield'),
    );
    final reserveRect = tester.getRect(reserve);
    final gesture = await tester.startGesture(
      reserveRect.topLeft + const Offset(6, 6),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(fake.lastSwap?.$1, 'player-laser');
    expect(fake.lastSwap?.$2, 'reserve-shield');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tamamlanan savaş replay açmaz; aynı sahnede analiz gösterir', (
    tester,
  ) async {
    final match = _completedMatch();
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/matches/match-1/replay');
      return _jsonResponse({
        'match_id': 'match-1',
        'rules_version': '0.8',
        'checksum': match.replayChecksum,
        'events': const [],
        'state_frames': const [],
      }, 200);
    });
    final container = ProviderContainer(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        relayApiProvider.overrideWithValue(
          RelayApi(
            baseUrl: 'http://relay.test',
            client: client,
            sessionStorage: _MemorySessionStorage(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(appSettingsProvider.notifier).setReplaySoundEnabled(false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CareerLiveBattleScreen(
            initialSession: _session(
              active: false,
              complete: true,
              match: match,
            ),
            modules: _moduleSpecs,
            visuals: const EquippedVisuals.defaults(),
            stageNumber: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(CareerBattleScreen), findsNothing);
    expect(
      find.byKey(const ValueKey('career-live-battle-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('battle-center-analysis')),
      findsOneWidget,
    );
    expect(find.text('ZAFER'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('canlı besleme modül değişimini donanım yerleşimine uygular', () {
    final session = _session(active: true);
    final formatter = ReplayEventFormatter.fromBoards(
      playerBoard: session.playerBoard,
      opponentBoard: session.opponentBoard,
      opponentName: session.opponent.displayName,
    );
    final snapshots = <ReplaySnapshot>[];
    final eventBatches = <List<BattleEvent>>[];
    final game = RelayReplayGame.live(
      playerBoard: session.playerBoard,
      opponentBoard: session.opponentBoard,
      initialFrame: session.frame,
      opponentName: session.opponent.displayName,
      leftCoreMaxHp: 100,
      rightCoreMaxHp: 100,
      moduleSpecs: {for (final module in _moduleSpecs) module.kind: module},
      formatter: formatter,
      onFrame: snapshots.add,
      onEvents: eventBatches.add,
    );

    const swap = BattleEvent(
      tick: 61,
      side: 'left',
      type: 'module_swap',
      actorId: 'reserve-shield',
      targetId: 'player-laser',
      amount: 0,
      detail: 'window=60;kind=shield;row=0;column=2;orientation=west',
    );
    game.feedLiveFrame(frame: session.frame, newEvents: const [swap]);

    final layout = game.debugLeftLayout;
    expect(
      layout.modules.any((module) => module.id == 'reserve-shield'),
      isTrue,
    );
    expect(
      layout.modules.any((module) => module.id == 'player-laser'),
      isFalse,
    );
    expect(snapshots.last.tick, session.frame.tick);
    expect(eventBatches.last, const [swap]);

    game.markLiveComplete(finalTick: session.frame.tick, resultLabel: 'ZAFER');
    expect(snapshots.last.complete, isTrue);
    expect(snapshots.last.lastEvent, 'ZAFER');
  });

  test('saldırı ışını hedefe bakan kenar portundan çıkar', () {
    final session = _session(active: true);
    final formatter = ReplayEventFormatter.fromBoards(
      playerBoard: session.playerBoard,
      opponentBoard: session.opponentBoard,
      opponentName: session.opponent.displayName,
    );
    final game = RelayReplayGame.live(
      playerBoard: session.playerBoard,
      opponentBoard: session.opponentBoard,
      initialFrame: session.frame,
      opponentName: session.opponent.displayName,
      leftCoreMaxHp: 100,
      rightCoreMaxHp: 100,
      moduleSpecs: {for (final module in _moduleSpecs) module.kind: module},
      formatter: formatter,
      onFrame: (_) {},
      onEvents: (_) {},
    );

    const stageSize = Size(1280, 720);
    final leftBoard = ReplayStageGeometry.leftBoard(stageSize);
    final rightBoard = ReplayStageGeometry.rightBoard(stageSize);
    final laser = session.playerBoard.modules.firstWhere(
      (module) => module.id == 'player-laser',
    );
    final target = session.opponentBoard.modules.firstWhere(
      (module) => module.id == 'bot-generator',
    );

    final laserCenter = ReplayStageGeometry.perspectivePoint(
      ReplayCircuitGeometry.moduleRect(laser, leftBoard).center,
      leftBoard,
      leftSide: true,
    );
    final laserEastPort = ReplayStageGeometry.perspectivePoint(
      ReplayCircuitGeometry.modulePortAnchor(
        laser,
        RelayDirection.east,
        leftBoard,
      ),
      leftBoard,
      leftSide: true,
    );
    final targetCenter = ReplayStageGeometry.perspectivePoint(
      ReplayCircuitGeometry.moduleRect(target, rightBoard).center,
      rightBoard,
      leftSide: false,
    );
    final targetWestPort = ReplayStageGeometry.perspectivePoint(
      ReplayCircuitGeometry.modulePortAnchor(
        target,
        RelayDirection.west,
        rightBoard,
      ),
      rightBoard,
      leftSide: false,
    );

    const attack = BattleEvent(
      tick: 61,
      side: 'left',
      type: 'attack',
      actorId: 'player-laser',
      targetId: 'bot-generator',
      amount: 8,
    );
    final endpoints = game.debugBeamEndpoints(attack, stageSize);

    expect(endpoints.from.dx, closeTo(laserEastPort.dx, 0.001));
    expect(endpoints.from.dy, closeTo(laserEastPort.dy, 0.001));
    expect(endpoints.from.dx, greaterThan(laserCenter.dx));
    expect(endpoints.to.dx, closeTo(targetWestPort.dx, 0.001));
    expect(endpoints.to.dy, closeTo(targetWestPort.dy, 0.001));
    expect(endpoints.to.dx, lessThan(targetCenter.dx));
  });

  testWidgets('canlı saat saldırı olayını oyun kuyruğuna besler', (tester) async {
    final fake = _AdvanceRelayApi();
    fake.next = _session(
      active: true,
      tick: 61,
      events: const [
        BattleEvent(
          tick: 61,
          side: 'left',
          type: 'attack',
          actorId: 'player-laser',
          targetId: 'bot-generator',
          amount: 8,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        relayApiProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);
    container.read(appSettingsProvider.notifier).setReplaySoundEnabled(false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CareerLiveBattleScreen(
            initialSession: _session(active: true),
            modules: _moduleSpecs,
            visuals: const EquippedVisuals.defaults(),
            stageNumber: 1,
          ),
        ),
      ),
    );
    await tester.pump();

    final game = tester
        .widget<GameWidget<RelayReplayGame>>(
          find.byType(GameWidget<RelayReplayGame>),
        )
        .game!;
    expect(game.debugPulseCount, 0);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    await tester.pump();

    expect(fake.advanceCalls, greaterThan(0));
    expect(game.debugPulseCount, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

CareerBattleSessionSnapshot _session({
  required bool active,
  bool complete = false,
  MatchResponse? match,
  List<BattleEvent> events = const [],
  int? tick,
}) {
  const playerBoard = BoardDraft(
    name: 'Oyuncu',
    modules: [
      ModulePlacement(
        id: 'player-generator',
        kind: ModuleKind.generator,
        row: 0,
        column: 1,
        orientation: RelayDirection.south,
      ),
      ModulePlacement(
        id: 'player-laser',
        kind: ModuleKind.laser,
        row: 0,
        column: 2,
      ),
    ],
  );
  const opponentBoard = BoardDraft(
    name: 'Rakip',
    modules: [
      ModulePlacement(
        id: 'bot-generator',
        kind: ModuleKind.generator,
        row: 0,
        column: 1,
        orientation: RelayDirection.south,
      ),
      ModulePlacement(
        id: 'bot-laser',
        kind: ModuleKind.laser,
        row: 0,
        column: 2,
      ),
    ],
  );
  final resolvedTick = tick ?? (active || complete ? 60 : 12);
  return CareerBattleSessionSnapshot(
    sessionId: 'session-1',
    runId: 'run-1',
    stageIndex: 0,
    totalStages: 5,
    status: 'active',
    tick: resolvedTick,
    complete: complete,
    playerBoard: playerBoard,
    opponentBoard: opponentBoard,
    frame: ReplayStateFrame(
      tick: resolvedTick,
      left: _boardState(const ['player-generator', 'player-laser']),
      right: _boardState(const ['bot-generator', 'bot-laser']),
    ),
    intervention: CareerInterventionState(
      tick: resolvedTick,
      windowTick: active ? 60 : null,
      active: active,
      pending: false,
      swapsUsed: 0,
      swapsRemaining: 2,
      activeModuleIds: const {'player-generator', 'player-laser'},
      reserveModuleIds: const {'reserve-shield'},
    ),
    reserves: const [
      CareerReserveModule(
        id: 'reserve-shield',
        kind: ModuleKind.shield,
        level: 1,
      ),
    ],
    events: events,
    opponent: const CareerOpponentPreview(
      stageNumber: 1,
      totalStages: 5,
      title: 'İlk Sinyal',
      briefing: 'Rakip devreyi aş.',
      isBoss: false,
      opponentId: 'spark',
      displayName: 'Kıvılcım',
      description: 'Sade lazer devresi.',
      board: opponentBoard,
    ),
    run: const CareerRunSnapshot(
      runId: 'run-1',
      status: 'active',
      stageIndex: 0,
      totalStages: 5,
      wins: 0,
      selectedBoosters: [],
      offeredBoosters: [],
      opponent: null,
      lastMatchId: null,
      reward: null,
      boardRequired: false,
      canBattle: true,
      canChooseBooster: false,
      startedAt: null,
      endedAt: null,
    ),
    match: match,
  );
}

MatchResponse _completedMatch() {
  final session = _session(active: false);
  return MatchResponse.fromJson({
    'match_id': 'match-1',
    'created_at': '2026-08-15T09:00:00+00:00',
    'opponent': {
      'bot_id': 'spark',
      'display_name': 'Kıvılcım',
      'difficulty': 'easy',
      'description': 'Sade lazer devresi.',
      'available_module_counts': [1, 2, 3, 4, 5, 6],
    },
    'player_board': session.playerBoard.toJson(),
    'opponent_board': session.opponentBoard.toJson(),
    'result': {
      'winner': 'left',
      'reason': 'core_destroyed',
      'ticks': 60,
      'decision': {
        'criterion': 'core_destroyed',
        'metrics': [
          {
            'key': 'core_hp_ratio',
            'left_value': 0.833,
            'right_value': 0,
            'preferred': 'higher',
          },
        ],
      },
      'left': {
        'name': 'Oyuncu',
        'core_hp': 100,
        'core_max_hp': 120,
        'total_damage': 120,
        'surviving_modules': 2,
        'modules': const [],
      },
      'right': {
        'name': 'Kıvılcım',
        'core_hp': 0,
        'core_max_hp': 120,
        'total_damage': 20,
        'surviving_modules': 0,
        'modules': const [],
      },
    },
    'replay': {
      'checksum': List.filled(64, 'a').join(),
      'event_count': 0,
      'path': '/api/v1/matches/match-1/replay',
    },
  });
}

BoardReplayState _boardState(List<String> ids) {
  return BoardReplayState(
    coreHp: 100,
    shield: 0,
    energyReserve: 0,
    energyOutput: 8,
    energySpent: 0,
    modules: [
      for (final id in ids)
        ModuleReplayState(
          id: id,
          hp: 40,
          maxHp: 40,
          heat: 0,
          cooldown: 0,
          powered: true,
          overheated: false,
        ),
    ],
  );
}

const _moduleSpecs = [
  ModuleSpec(
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
  ),
  ModuleSpec(
    kind: ModuleKind.laser,
    displayName: 'Lazer',
    description: 'Sık ateş eder.',
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
  ),
  ModuleSpec(
    kind: ModuleKind.shield,
    displayName: 'Kalkan',
    description: 'Hasarı karşılar.',
    maxHp: 35,
    ports: {RelayDirection.west},
    energyOutput: 0,
    batteryCapacity: 0,
    energyCost: 5,
    cooldownTicks: 2,
    heatPerAction: 6,
    damage: 0,
    shield: 14,
    cooling: 0,
    repair: 0,
    threat: 0,
  ),
];

class _MemorySettingsStore implements AppSettingsStore {
  AppSettings value = const AppSettings(replaySoundEnabled: false);

  @override
  Future<AppSettings?> load() async => value;

  @override
  Future<void> save(AppSettings settings) async {
    value = settings;
  }
}

class _MemorySessionStorage implements SessionStorage {
  String? refreshToken;

  @override
  Future<void> clear() async {
    refreshToken = null;
  }

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeRefreshToken(String token) async {
    refreshToken = token;
  }
}

class _AdvanceRelayApi extends RelayApi {
  _AdvanceRelayApi()
    : super(
        baseUrl: 'http://relay.test',
        client: http.Client(),
        sessionStorage: _MemorySessionStorage(),
      );

  CareerBattleSessionSnapshot? next;
  int advanceCalls = 0;

  @override
  Future<CareerBattleSessionSnapshot> advanceCareerBattleSession({
    int ticks = 1,
  }) async {
    advanceCalls += 1;
    return next!;
  }
}

class _SwapRelayApi extends RelayApi {
  _SwapRelayApi()
    : super(
        baseUrl: 'http://relay.test',
        client: http.Client(),
        sessionStorage: _MemorySessionStorage(),
      );

  (String, String)? lastSwap;

  @override
  Future<CareerBattleSessionSnapshot> advanceCareerBattleSession({
    int ticks = 1,
  }) async {
    return _session(active: true);
  }

  @override
  Future<CareerBattleSessionSnapshot> swapCareerBattleModule({
    required String outgoingId,
    required String incomingId,
    RelayDirection? orientation,
  }) async {
    lastSwap = (outgoingId, incomingId);
    return _session(active: false);
  }
}

http.Response _jsonResponse(Object? body, int statusCode) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}
