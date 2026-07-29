import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/models/relay_models.dart';

void main() {
  test('misafir oturumu ve kalıcı kart yanıtını ayrıştırır', () {
    final session = GuestSession.fromJson({
      'player': {
        'player_id': 'player-1',
        'display_name': 'MaviRole-2026',
        'created_at': '2026-07-29T12:00:00+00:00',
      },
      'tokens': {
        'access_token': 'access',
        'refresh_token': 'refresh',
        'token_type': 'bearer',
        'access_expires_in': 900,
        'refresh_expires_in': 2592000,
      },
    });
    final saved = SavedBoard.fromJson({
      'board_id': 'board-1',
      'fingerprint': List.filled(64, 'a').join(),
      'updated_at': '2026-07-29T12:01:00+00:00',
      'board': {
        'name': 'Kalıcı Devre',
        'modules': [
          {
            'module_id': 'P-GEN',
            'kind': 'generator',
            'row': 0,
            'column': 1,
            'orientation': 'south',
            'level': 1,
          },
        ],
      },
      'powered_module_ids': ['P-GEN'],
      'unpowered_module_ids': const <String>[],
    });

    expect(session.player.displayName, 'MaviRole-2026');
    expect(session.tokens.accessExpiresIn, 900);
    expect(saved.board.name, 'Kalıcı Devre');
    expect(saved.poweredIds, {'P-GEN'});
  });

  test('modül portlarını yerleştirme yönüne göre döndürür', () {
    final laser = ModuleSpec.fromJson({
      'kind': 'laser',
      'display_name': 'Lazer',
      'description': 'Az enerjiyle sık ateş eder.',
      'max_hp': 27,
      'ports': ['west'],
      'energy_output': 0,
      'energy_cost': 4,
      'cooldown_ticks': 2,
      'heat_per_action': 14,
      'damage': 8,
      'shield': 0,
      'cooling': 0,
      'repair': 0,
    });

    expect(
      laser.worldPorts(RelayDirection.east),
      {RelayDirection.west},
    );
    expect(
      laser.worldPorts(RelayDirection.south),
      {RelayDirection.north},
    );
    expect(
      laser.worldPorts(RelayDirection.west),
      {RelayDirection.east},
    );
    expect(
      laser.worldPorts(RelayDirection.north),
      {RelayDirection.south},
    );
  });

  test('iki portlu aktarma modülleri her yönde hattı sürdürür', () {
    final battery = ModuleSpec.fromJson({
      'kind': 'battery',
      'display_name': 'Batarya',
      'description': 'Enerjiyi depolar ve dört yöne aktarır.',
      'max_hp': 38,
      'ports': ['north', 'east', 'south', 'west'],
      'energy_output': 0,
      'battery_capacity': 20,
      'energy_cost': 0,
      'cooldown_ticks': 0,
      'heat_per_action': 0,
      'damage': 0,
      'shield': 0,
      'cooling': 0,
      'repair': 0,
      'threat': 40,
    });

    expect(
      battery.worldPorts(RelayDirection.east),
      RelayDirection.values.toSet(),
    );
    expect(
      battery.worldPorts(RelayDirection.south),
      RelayDirection.values.toSet(),
    );
    expect(
      battery.worldPorts(RelayDirection.west),
      RelayDirection.values.toSet(),
    );
    expect(
      battery.worldPorts(RelayDirection.north),
      RelayDirection.values.toSet(),
    );
    expect(battery.batteryCapacity, 20);
    expect(battery.threat, 40);
  });

  test('jeneratör üç portunu kapı yönüne göre döndürür', () {
    final generator = ModuleSpec.fromJson({
      'kind': 'generator',
      'display_name': 'Jeneratör',
      'description': 'Çekirdek kapısında çalışır.',
      'max_hp': 52,
      'ports': ['north', 'east', 'south'],
      'energy_output': 5,
      'battery_capacity': 0,
      'energy_cost': 0,
      'cooldown_ticks': 0,
      'heat_per_action': 0,
      'damage': 0,
      'shield': 0,
      'cooling': 0,
      'repair': 0,
      'threat': 60,
    });

    expect(
      generator.worldPorts(RelayDirection.south),
      {
        RelayDirection.east,
        RelayDirection.south,
        RelayDirection.west,
      },
    );
    expect(reservedCoreCells, {5, 6, 9, 10});
    expect(coreGateDirections[1], RelayDirection.south);
    expect(coreGateDirections[7], RelayDirection.west);
    expect(coreGateDirections[14], RelayDirection.north);
    expect(coreGateDirections[8], RelayDirection.east);
  });

  test('bütün modül türlerinin Türkçe yedek adları vardır', () {
    expect(
      ModuleKind.values.map((kind) => kind.displayName),
      [
        'Jeneratör',
        'Batarya',
        'Lazer',
        'Darbe Topu',
        'Kalkan',
        'Soğutucu',
        'Güçlendirici',
        'Onarım Ünitesi',
      ],
    );
  });

  test('kart API sözleşmesindeki snake_case alanlarını üretir', () {
    const board = BoardDraft(
      name: 'Test',
      modules: [
        ModulePlacement(
          id: 'P-PULSE',
          kind: ModuleKind.pulseCannon,
          row: 0,
          column: 1,
          orientation: RelayDirection.north,
        ),
      ],
    );

    final json = board.toJson();
    final module = (json['modules'] as List<dynamic>).single
        as Map<String, dynamic>;

    expect(module['kind'], 'pulse_cannon');
    expect(module['orientation'], 'north');
    expect(module['level'], 1);
  });

  test('maç ve replay yanıtlarını istemci modellerine dönüştürür', () {
    final match = MatchResponse.fromJson({
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
            'module_id': 'P-GEN',
            'kind': 'generator',
            'row': 1,
            'column': 1,
            'orientation': 'east',
            'level': 1,
          },
        ],
      },
      'opponent_board': {
        'name': 'Kıvılcım',
        'modules': [
          {
            'module_id': 'BOT-GEN',
            'kind': 'generator',
            'row': 1,
            'column': 1,
            'orientation': 'east',
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
          ],
        },
        'left': {
          'name': 'Mavi Devre',
          'core_hp': 100,
          'core_max_hp': 120,
          'total_damage': 120,
          'surviving_modules': 2,
          'modules': [
            {
              'module_id': 'P-GEN',
              'kind': 'generator',
              'hp': 52,
              'max_hp': 52,
              'heat': 0,
              'powered': true,
              'overheated': false,
            },
          ],
        },
        'right': {
          'name': 'Kıvılcım',
          'core_hp': 0,
          'core_max_hp': 120,
          'total_damage': 20,
          'surviving_modules': 1,
          'modules': [
            {
              'module_id': 'BOT-GEN',
              'kind': 'generator',
              'hp': 12,
              'max_hp': 52,
              'heat': 0,
              'powered': true,
              'overheated': false,
            },
          ],
        },
      },
      'replay': {
        'checksum': List.filled(64, 'a').join(),
        'event_count': 4,
        'path': '/api/v1/matches/match-1/replay',
      },
    });

    expect(match.id, 'match-1');
    expect(match.result.winner, 'left');
    expect(match.result.right.coreHp, 0);
    expect(match.replayEventCount, 4);
    expect(match.playerBoard.modules.single.kind, ModuleKind.generator);
    expect(match.opponentBoard.name, 'Kıvılcım');
    expect(match.result.left.modules.single.maxHp, 52);
    expect(match.result.decision.criterion, 'core_destroyed');
    expect(match.result.decision.metrics.single.leftValue, 0.833333);
  });

  test('savaş durum karelerini can enerji ve ısıyla ayrıştırır', () {
    final replay = ReplayResponse.fromJson({
      'match_id': 'match-1',
      'rules_version': '0.7',
      'checksum': List.filled(64, 'b').join(),
      'events': [
        {
          'tick': 1,
          'side': 'left',
          'type': 'attack',
          'actor_id': 'P-LASER',
          'target_id': 'BOT-GEN',
          'amount': 8,
        },
      ],
      'state_frames': [
        {
          'tick': 0,
          'left': {
            'core_hp': 120,
            'shield': 0,
            'energy_reserve': 0,
            'energy_output': 5,
            'energy_spent': 0,
            'modules': [
              {
                'module_id': 'P-LASER',
                'hp': 27,
                'max_hp': 27,
                'heat': 0,
                'cooldown': 0,
                'powered': true,
                'overheated': false,
              },
            ],
          },
          'right': {
            'core_hp': 120,
            'shield': 0,
            'energy_reserve': 0,
            'energy_output': 5,
            'energy_spent': 0,
            'modules': <Map<String, Object>>[],
          },
        },
        {
          'tick': 1,
          'left': {
            'core_hp': 120,
            'shield': 12,
            'energy_reserve': 1,
            'energy_output': 5,
            'energy_spent': 4,
            'modules': [
              {
                'module_id': 'P-LASER',
                'hp': 27,
                'max_hp': 27,
                'heat': 14,
                'cooldown': 2,
                'powered': true,
                'overheated': false,
              },
            ],
          },
          'right': {
            'core_hp': 120,
            'shield': 0,
            'energy_reserve': 0,
            'energy_output': 5,
            'energy_spent': 0,
            'modules': <Map<String, Object>>[],
          },
        },
      ],
    });

    expect(replay.stateFrames, hasLength(2));
    expect(replay.stateAt(0)!.left.energyOutput, 5);
    expect(replay.stateAt(1)!.left.energyReserve, 1);
    expect(replay.stateAt(1)!.left.shield, 12);
    expect(replay.stateAt(1)!.left.modules.single.heat, 14);
    expect(replay.stateAt(1)!.left.modules.single.cooldown, 2);
  });
}
