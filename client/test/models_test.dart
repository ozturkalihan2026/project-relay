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

  test('Batarya ve Güçlendirici dört yönde hattı sürdürür', () {
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

    final amplifier = ModuleSpec.fromJson({
      'kind': 'amplifier',
      'display_name': 'Güçlendirici',
      'description': 'Dört portlu, yönlü etki veren enerji kavşağı.',
      'max_hp': 25,
      'ports': ['north', 'east', 'south', 'west'],
      'energy_output': 0,
      'battery_capacity': 0,
      'energy_cost': 0,
      'cooldown_ticks': 0,
      'heat_per_action': 0,
      'damage': 0,
      'shield': 0,
      'cooling': 0,
      'repair': 0,
      'threat': 90,
    });

    for (final orientation in RelayDirection.values) {
      expect(
        amplifier.worldPorts(orientation),
        RelayDirection.values.toSet(),
      );
    }
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
      'created_at': '2026-07-31T09:00:00+00:00',
      'source': 'async',
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
      'progression_reward': {
        'source_type': 'match',
        'source_id': 'match-1',
        'reason': 'Asenkron savaş: win',
        'xp': 50,
        'credits': 30,
        'level_before': 1,
        'level_after': 1,
        'level_up': false,
        'total_xp_after': 50,
        'credits_after': 30,
        'granted_at': '2026-07-31T09:00:00+00:00',
      },
      'season_change': {
        'season_key': '2026-08',
        'outcome': 'win',
        'points_gained': 5,
        'total_points': 18,
      },
      'rating_change': {
        'outcome': 'win',
        'rating_before': 1000,
        'rating_after': 1016,
        'rating_delta': 16,
        'week_key': '2026-W31',
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
    expect(match.source, 'async');
    expect(match.ratingChange?.ratingDelta, 16);
    expect(match.progressionReward?.xp, 50);
    expect(match.progressionReward?.credits, 30);
    expect(match.seasonChange?.pointsGained, 5);
    expect(match.seasonChange?.totalPoints, 18);
    expect(match.createdAt, DateTime.parse('2026-07-31T09:00:00+00:00'));
  });

  test('ilerleme görev başarım ve geçici güçlendiricileri ayrıştırır', () {
    final progression = ProgressionSnapshot.fromJson({
      'day_key': '2026-07-31',
      'profile': {
        'player_id': 'player-1',
        'total_xp': 50,
        'level': 1,
        'xp_into_level': 50,
        'xp_for_next_level': 100,
        'credits': 30,
        'matches_completed': 1,
        'wins': 1,
        'draws': 0,
        'losses': 0,
      },
      'daily_missions': [
        {
          'mission_id': 'first_signal',
          'title': 'İlk Sinyal',
          'description': 'Bir savaş tamamla.',
          'progress': 1,
          'target': 1,
          'completed': true,
          'claimed': false,
          'reward_xp': 30,
          'reward_credits': 25,
        },
      ],
      'achievements': [
        {
          'achievement_id': 'first_battle',
          'title': 'Devreye Giriş',
          'description': 'İlk savaşını tamamla.',
          'progress': 1,
          'target': 1,
          'unlocked': true,
          'claimed': false,
          'reward_xp': 100,
          'reward_credits': 50,
        },
      ],
      'boosters': [
        {
          'booster_id': 'overcharge',
          'display_name': 'Aşırı Şarj',
          'description': 'Koşu içinde geçici etki.',
          'unlock_level': 1,
          'unlocked': true,
          'tier': 1,
          'effect_value': 5,
          'effect_label': 'Jeneratör üretimi +%5',
          'next_tier_level': 10,
        },
      ],
    });

    expect(progression.profile.level, 1);
    expect(progression.profile.levelProgress, 0.5);
    expect(progression.dailyMissions.single.completed, isTrue);
    expect(progression.achievements.single.unlocked, isTrue);
    expect(progression.boosters.single.tier, 1);
    expect(progression.boosters.single.description, contains('geçici'));
  });

  test('derece haftalık lig ve maç geçmişini ayrıştırır', () {
    final career = CareerSnapshot.fromJson({
      'profile': {
        'player_id': 'player-1',
        'rating': 1016,
        'peak_rating': 1016,
        'rated_matches': 1,
        'wins': 1,
        'draws': 0,
        'losses': 0,
        'win_rate': 1.0,
      },
      'league': {
        'week_key': '2026-W31',
        'starts_at': '2026-07-27T00:00:00+00:00',
        'ends_at': '2026-08-03T00:00:00+00:00',
        'points': 3,
        'wins': 1,
        'draws': 0,
        'losses': 0,
        'position': 1,
        'participant_count': 2,
      },
      'leaderboard': [
        {
          'position': 1,
          'player_id': 'player-1',
          'display_name': 'MaviRole-2026',
          'points': 3,
          'wins': 1,
          'draws': 0,
          'losses': 0,
          'rating': 1016,
          'is_current_player': true,
        },
      ],
      'recent_matches': [
        {
          'match_id': 'match-1',
          'created_at': '2026-07-31T09:00:00+00:00',
          'opponent_kind': 'player',
          'opponent_name': 'BakirAkım-2027',
          'outcome': 'win',
          'rated': true,
          'rating_delta': 16,
          'rating_after': 1016,
          'reason': 'core_destroyed',
          'replay_path': '/api/v1/matches/match-1/replay',
        },
      ],
      'matchmaking': {
        'searches': 1,
        'human_opponents': 1,
        'bot_fallbacks': 0,
        'human_opponent_rate': 1.0,
      },
    });

    expect(career.profile.rating, 1016);
    expect(career.league.points, 3);
    expect(career.leaderboard.single.isCurrentPlayer, isTrue);
    expect(career.recentMatches.single.ratingDelta, 16);
    expect(career.matchmaking.humanOpponentRate, 1);
  });

  test('savaş durum karelerini can enerji ve ısıyla ayrıştırır', () {
    final replay = ReplayResponse.fromJson({
      'match_id': 'match-1',
      'rules_version': '0.8',
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
  test('savaş modlarına ait başlangıç sekizlilerini ayrı ayrıştırır', () {
    final snapshot = CollectionSnapshot.fromJson({
      'player_id': 'player-1',
      'credits': 0,
      'cosmetics': <Map<String, Object?>>[],
      'kit': {
        'name': 'Çevrimiçi',
        'module_kinds': [
          'generator', 'battery', 'laser', 'pulse_cannon',
          'shield', 'cooler', 'amplifier', 'repair',
        ],
        'updated_at': '2026-08-06T00:00:00+00:00',
      },
      'kits': {
        'online': {
          'name': 'Çevrimiçi',
          'module_kinds': [
            'generator', 'battery', 'laser', 'pulse_cannon',
            'shield', 'cooler', 'amplifier', 'repair',
          ],
          'updated_at': '2026-08-06T00:00:00+00:00',
        },
        'training': {
          'name': 'Antrenman',
          'module_kinds': [
            'generator', 'battery', 'battery', 'laser',
            'shield', 'cooler', 'amplifier', 'repair',
          ],
          'updated_at': '2026-08-06T00:01:00+00:00',
        },
        'career': {
          'name': 'Kariyer',
          'module_kinds': [
            'generator', 'battery', 'laser', 'shield',
            'shield', 'cooler', 'repair', 'repair',
          ],
          'updated_at': '2026-08-06T00:02:00+00:00',
        },
      },
      'equipped_module_skin_id': 'module_neon_cyan',
      'equipped_board_theme_id': 'board_midnight_grid',
      'equipped_profile_frame_id': 'frame_circuit_basic',
    });

    expect(snapshot.kitFor(KitMode.online).name, 'Çevrimiçi');
    expect(snapshot.kitFor(KitMode.training).name, 'Antrenman');
    expect(snapshot.kitFor(KitMode.career).name, 'Kariyer');
    expect(
      snapshot.kitFor(KitMode.career).counts[ModuleKind.repair],
      2,
    );
  });

}
