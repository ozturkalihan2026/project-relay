import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/models/relay_models.dart';
import 'package:project_relay_client/src/screens/career_live_battle_screen.dart';
import 'package:project_relay_client/src/state/app_settings.dart';
import 'package:project_relay_client/src/theme/cosmetic_visuals.dart';

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
    expect(find.byKey(const ValueKey('live-player-board')), findsOneWidget);
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
}

CareerBattleSessionSnapshot _session({required bool active}) {
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
  return CareerBattleSessionSnapshot(
    sessionId: 'session-1',
    runId: 'run-1',
    stageIndex: 0,
    totalStages: 5,
    status: 'active',
    tick: active ? 60 : 12,
    complete: false,
    playerBoard: playerBoard,
    opponentBoard: opponentBoard,
    frame: ReplayStateFrame(
      tick: active ? 60 : 12,
      left: _boardState(const ['player-generator', 'player-laser']),
      right: _boardState(const ['bot-generator', 'bot-laser']),
    ),
    intervention: CareerInterventionState(
      tick: active ? 60 : 12,
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
    events: const [],
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
    match: null,
  );
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
