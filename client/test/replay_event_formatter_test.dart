import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/game/replay_event_formatter.dart';
import 'package:project_relay_client/src/models/relay_models.dart';
import 'package:project_relay_client/src/widgets/replay_event_feed.dart';

void main() {
  test('teknik modül kimliklerini Türkçe olay metnine dönüştürür', () {
    final formatter = ReplayEventFormatter(_match());
    const event = BattleEvent(
      tick: 9,
      side: 'left',
      type: 'destroyed',
      actorId: 'P-LASER',
      targetId: 'BOT-SHIELD',
      amount: 0,
    );

    final label = formatter.eventLabel(event);

    expect(label, contains('Kıvılcım Kalkan'));
    expect(label, contains('imha edildi'));
    expect(label, isNot(contains('BOT-SHIELD')));
  });

  test('enerji ve çekirdek olaylarını açıklayıcı Türkçe yazar', () {
    final formatter = ReplayEventFormatter(_match());

    expect(
      formatter.eventLabel(
        const BattleEvent(
          tick: 2,
          side: 'left',
          type: 'energy_starved',
          actorId: 'P-LASER',
          amount: 2,
        ),
      ),
      contains('2.0 enerji eksik'),
    );
    expect(
      formatter.eventLabel(
        const BattleEvent(
          tick: 3,
          side: 'left',
          type: 'core_damage',
          actorId: 'P-LASER',
          targetId: 'enemy_core',
          amount: 8,
        ),
      ),
      contains('rakip çekirdeğe 8.0 hasar'),
    );
  });

  testWidgets('kompakt günlük son yedi olayla sınırlanmaz', (tester) async {
    final events = List<BattleEvent>.generate(
      12,
      (index) => BattleEvent(
        tick: index + 1,
        side: 'left',
        type: 'attack',
        actorId: 'P-LASER',
        targetId: 'BOT-SHIELD',
        amount: 1,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 420,
            child: ReplayEventFeed(
              events: events,
              visibleTick: 12,
              formatter: ReplayEventFormatter(_match()),
              match: _match(),
              replay: _replay(events),
              complete: false,
              compact: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('#12'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('#1'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('#1'), findsOneWidget);
  });

  testWidgets(
    'olay günlüğü savaş başlangıcı ve yeniden başlatmada denetleyiciyi korur',
    (tester) async {
      final events = List<BattleEvent>.generate(
        12,
        (index) => BattleEvent(
          tick: index + 1,
          side: 'left',
          type: 'attack',
          actorId: 'P-LASER',
          targetId: 'BOT-SHIELD',
          amount: 1,
        ),
      );

      await tester.pumpWidget(_eventFeed(const [], 0));
      var scrollbar = tester.widget<Scrollbar>(
        find.byKey(const ValueKey('replay-event-scrollbar')),
      );
      final controller = scrollbar.controller;
      expect(controller, isNotNull);
      expect(controller!.hasClients, isTrue);
      expect(find.byType(Scrollbar), findsOneWidget);

      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(
          find.byKey(const ValueKey('replay-event-scrollbar')),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(_eventFeed(events, 12));
      scrollbar = tester.widget<Scrollbar>(
        find.byKey(const ValueKey('replay-event-scrollbar')),
      );
      expect(identical(scrollbar.controller, controller), isTrue);
      expect(scrollbar.controller!.hasClients, isTrue);
      expect(find.byType(Scrollbar), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('replay-event-list')),
        const Offset(0, -180),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(_eventFeed(const [], 0));
      scrollbar = tester.widget<Scrollbar>(
        find.byKey(const ValueKey('replay-event-scrollbar')),
      );
      expect(identical(scrollbar.controller, controller), isTrue);
      expect(scrollbar.controller!.hasClients, isTrue);
      await mouse.moveTo(
        tester.getCenter(
          find.byKey(const ValueKey('replay-event-scrollbar')),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await mouse.removePointer();
    },
  );

  testWidgets(
    'sunucu sonucu savaş boyunca görünür ve canlı değerleri günceller',
    (tester) async {
      final events = <BattleEvent>[
        const BattleEvent(
          tick: 1,
          side: 'left',
          type: 'core_damage',
          actorId: 'P-LASER',
          targetId: 'enemy_core',
          amount: 8,
        ),
      ];

      await tester.pumpWidget(
        _eventFeed(
          events,
          1,
          currentLeftHp: 87,
          currentRightHp: 64,
        ),
      );
      expect(find.text('SUNUCU SONUCU'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('inline-server-result')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('live-server-metrics')),
        findsOneWidget,
      );
      expect(find.textContaining('CANLI • ADIM 1/24'), findsOneWidget);
      expect(find.text('87'), findsOneWidget);
      expect(find.text('64'), findsOneWidget);

      await tester.pumpWidget(_eventFeed(events, 1, complete: true));
      expect(
        find.byKey(const ValueKey('inline-server-result')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('live-server-metrics')),
        findsNothing,
      );
      expect(find.text('ZAFER'), findsOneWidget);
    },
  );

  testWidgets(
    'kompakt panel taşmaz ve kontroller savaş bitince yer değiştirmez',
    (tester) async {
      final events = List<BattleEvent>.generate(
        12,
        (index) => BattleEvent(
          tick: index + 1,
          side: index.isEven ? 'left' : 'right',
          type: 'attack',
          actorId: 'P-LASER',
          targetId: 'BOT-SHIELD',
          amount: 3,
        ),
      );
      const controls = SizedBox(
        key: ValueKey('fixed-test-controls'),
        height: 82,
      );

      await tester.pumpWidget(
        _eventFeed(
          events,
          6,
          height: 402,
          controls: controls,
        ),
      );
      final duringTop = tester.getTopLeft(
        find.byKey(const ValueKey('fixed-test-controls')),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _eventFeed(
          events,
          12,
          complete: true,
          height: 402,
          controls: controls,
        ),
      );
      final completedTop = tester.getTopLeft(
        find.byKey(const ValueKey('fixed-test-controls')),
      );

      expect(completedTop.dy, closeTo(duringTop.dy, 0.01));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'süre sonu sonucu kararı veren ilk ölçütü ve bütün değerleri gösterir',
    (tester) async {
      final match = _timeoutMatch();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 420,
              child: ReplayEventFeed(
                events: const [],
                visibleTick: 90,
                formatter: ReplayEventFormatter(match),
                match: match,
                replay: _replay(const []),
                complete: true,
                compact: true,
              ),
            ),
          ),
        ),
      );

      expect(
        find.textContaining('Modül canı; daha yüksek değer kazandırdı'),
        findsOneWidget,
      );
      expect(find.textContaining('Modül canı  ← KARAR'), findsOneWidget);
      expect(find.text('%70.0'), findsOneWidget);
      expect(find.text('%80.0'), findsOneWidget);
      expect(find.text('Hasar/enerji'), findsOneWidget);
      expect(find.text('Toplam ısı ↓'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'oynatma kontrolleri sunucu sonucunun altında gösterilir',
    (tester) async {
      final match = _match();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 500,
              child: ReplayEventFeed(
                events: const [],
                visibleTick: 90,
                formatter: ReplayEventFormatter(match),
                match: match,
                replay: _replay(const []),
                complete: true,
                compact: true,
                controls: const SizedBox(
                  key: ValueKey('test-replay-controls'),
                  height: 34,
                ),
              ),
            ),
          ),
        ),
      );

      final resultBottom = tester.getBottomRight(
        find.textContaining('sunucu doğrulaması'),
      );
      final controlsTop = tester.getTopLeft(
        find.byKey(const ValueKey('test-replay-controls')),
      );

      expect(
        find.byKey(const ValueKey('inline-server-result')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('test-replay-controls')),
        findsOneWidget,
      );
      expect(controlsTop.dy, greaterThan(resultBottom.dy));
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _eventFeed(
  List<BattleEvent> events,
  int visibleTick, {
  bool complete = false,
  double currentLeftHp = 120,
  double currentRightHp = 120,
  double height = 420,
  Widget? controls,
}) {
  final match = _match();
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 500,
        height: height,
        child: ReplayEventFeed(
          key: const ValueKey('persistent-replay-event-feed'),
          events: events,
          visibleTick: visibleTick,
          formatter: ReplayEventFormatter(match),
          match: match,
          replay: _replay(events),
          complete: complete,
          currentLeftHp: currentLeftHp,
          currentRightHp: currentRightHp,
          compact: true,
          controls: controls,
        ),
      ),
    ),
  );
}

ReplayResponse _replay(List<BattleEvent> events) {
  return ReplayResponse(
    matchId: 'match-1',
    rulesVersion: '0.8',
    checksum: List.filled(64, 'a').join(),
    events: events,
    stateFrames: const [],
  );
}

MatchResponse _match() {
  return MatchResponse.fromJson({
    'match_id': 'match-1',
    'opponent': {
      'bot_id': 'starter_laser',
      'display_name': 'Kıvılcım',
      'difficulty': 'easy',
      'description': 'Sade devre',
      'available_module_counts': [1, 2, 3, 4, 5, 6],
    },
    'player_board': {
      'name': 'Mavi Devre',
      'modules': [
        {
          'module_id': 'P-LASER',
          'kind': 'laser',
          'row': 1,
          'column': 2,
          'orientation': 'east',
          'level': 1,
        },
      ],
    },
    'opponent_board': {
      'name': 'Kıvılcım',
      'modules': [
        {
          'module_id': 'BOT-SHIELD',
          'kind': 'shield',
          'row': 2,
          'column': 1,
          'orientation': 'west',
          'level': 1,
        },
      ],
    },
    'result': {
      'winner': 'left',
      'reason': 'core_destroyed',
      'ticks': 24,
      'decision': {
        'criterion': 'core_destroyed',
        'metrics': [
          {
            'key': 'core_hp_ratio',
            'left_value': 0.833333,
            'right_value': 0,
            'preferred': 'higher',
          },
          {
            'key': 'surviving_modules',
            'left_value': 1,
            'right_value': 0,
            'preferred': 'higher',
          },
          {
            'key': 'module_hp_ratio',
            'left_value': 1,
            'right_value': 0,
            'preferred': 'higher',
          },
          {
            'key': 'total_damage',
            'left_value': 120,
            'right_value': 20,
            'preferred': 'higher',
          },
          {
            'key': 'damage_efficiency',
            'left_value': 1,
            'right_value': 0.2,
            'preferred': 'higher',
          },
          {
            'key': 'total_heat',
            'left_value': 14,
            'right_value': 0,
            'preferred': 'lower',
          },
        ],
      },
      'left': {
        'name': 'Mavi Devre',
        'core_hp': 100,
        'core_max_hp': 120,
        'total_damage': 120,
        'surviving_modules': 1,
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
      'event_count': 4,
      'path': '/api/v1/matches/match-1/replay',
    },
  });
}

MatchResponse _timeoutMatch() {
  final payload = _match();
  return MatchResponse.fromJson({
    'match_id': payload.id,
    'opponent': {
      'bot_id': payload.opponent.id,
      'display_name': payload.opponent.displayName,
      'difficulty': payload.opponent.difficulty,
      'description': payload.opponent.description,
      'available_module_counts': payload.opponent.availableModuleCounts,
    },
    'player_board': payload.playerBoard.toJson(),
    'opponent_board': payload.opponentBoard.toJson(),
    'result': {
      'winner': 'right',
      'reason': 'timeout_tiebreak',
      'ticks': 90,
      'decision': {
        'criterion': 'module_hp_ratio',
        'metrics': [
          {
            'key': 'core_hp_ratio',
            'left_value': 1,
            'right_value': 1,
            'preferred': 'higher',
          },
          {
            'key': 'surviving_modules',
            'left_value': 2,
            'right_value': 2,
            'preferred': 'higher',
          },
          {
            'key': 'module_hp_ratio',
            'left_value': 0.7,
            'right_value': 0.8,
            'preferred': 'higher',
          },
          {
            'key': 'total_damage',
            'left_value': 27,
            'right_value': 27,
            'preferred': 'higher',
          },
          {
            'key': 'damage_efficiency',
            'left_value': 0.45,
            'right_value': 0.5,
            'preferred': 'higher',
          },
          {
            'key': 'total_heat',
            'left_value': 32,
            'right_value': 18,
            'preferred': 'lower',
          },
        ],
      },
      'left': {
        'name': 'Mavi Devre',
        'core_hp': 120,
        'core_max_hp': 120,
        'energy_spent': 60,
        'total_damage': 27,
        'surviving_modules': 2,
        'modules': const [],
      },
      'right': {
        'name': 'Kıvılcım',
        'core_hp': 120,
        'core_max_hp': 120,
        'energy_spent': 54,
        'total_damage': 27,
        'surviving_modules': 2,
        'modules': const [],
      },
    },
    'replay': {
      'checksum': List.filled(64, 'a').join(),
      'event_count': 40,
      'path': '/api/v1/matches/match-1/replay',
    },
  });
}
