import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/game/event_sound_player.dart';
import 'package:project_relay_client/src/models/relay_models.dart';

void main() {
  test('hızlı olaylar çalmakta olan ses kanalını yeniden kullanmaz', () async {
    final channels = <_FakeSoundChannel>[];
    final soundPlayer = EventSoundPlayer(
      _match(),
      channelFactory: () {
        final channel = _FakeSoundChannel();
        channels.add(channel);
        return channel;
      },
    );

    await Future.wait(
      List.generate(
        12,
        (index) => soundPlayer.playFrame([
          BattleEvent(
            tick: index + 1,
            side: 'left',
            type: 'shield',
            actorId: 'P-SHIELD',
            amount: 4,
          ),
        ]),
      ),
    );

    expect(channels, hasLength(12));
    expect(
      channels.map((channel) => channel.asset).toSet(),
      {'sounds/shield_charge.wav'},
    );
    expect(channels.every((channel) => !channel.isDisposed), isTrue);

    for (final channel in channels) {
      channel.complete();
    }
    await Future.wait(
      channels.map((channel) => channel.whenDisposed),
    );

    expect(channels.every((channel) => channel.isDisposed), isTrue);
    await soundPlayer.dispose();
  });

  test('ekran kapanışı etkin kanalları güvenle kapatır', () async {
    final channels = <_FakeSoundChannel>[];
    final soundPlayer = EventSoundPlayer(
      _match(),
      channelFactory: () {
        final channel = _FakeSoundChannel();
        channels.add(channel);
        return channel;
      },
    );

    await soundPlayer.playFrame([
      const BattleEvent(
        tick: 1,
        side: 'left',
        type: 'attack',
        actorId: 'P-LASER',
        targetId: 'BOT-SHIELD',
        amount: 8,
      ),
      const BattleEvent(
        tick: 1,
        side: 'right',
        type: 'repair',
        actorId: 'BOT-REPAIR',
        targetId: 'BOT-SHIELD',
        amount: 5,
      ),
    ]);

    expect(channels, hasLength(2));
    await soundPlayer.dispose();
    expect(channels.every((channel) => channel.isDisposed), isTrue);

    await soundPlayer.playFrame([
      const BattleEvent(
        tick: 2,
        side: 'left',
        type: 'cool',
        actorId: 'P-COOLER',
        amount: 5,
      ),
    ]);
    expect(channels, hasLength(2));
  });
}

class _FakeSoundChannel implements EventSoundChannel {
  final StreamController<void> _completion =
      StreamController<void>.broadcast();
  final Completer<void> _disposed = Completer<void>();

  String? asset;
  double? volume;

  bool get isDisposed => _disposed.isCompleted;
  Future<void> get whenDisposed => _disposed.future;

  @override
  Stream<void> get onComplete => _completion.stream;

  @override
  Future<void> play(String asset, double volume) async {
    this.asset = asset;
    this.volume = volume;
  }

  void complete() {
    if (!isDisposed) {
      _completion.add(null);
    }
  }

  @override
  Future<void> dispose() async {
    if (isDisposed) {
      return;
    }
    _disposed.complete();
    await _completion.close();
  }
}

MatchResponse _match() {
  return MatchResponse.fromJson({
    'match_id': 'match-1',
    'created_at': '2026-07-31T09:00:00+00:00',
    'opponent': {
      'bot_id': 'shield_wall',
      'display_name': 'Kalkan Duvarı',
      'difficulty': 'medium',
      'description': 'Savunma düzeni',
      'available_module_counts': [1, 2, 3, 4, 5, 6],
    },
    'player_board': {
      'name': 'Mavi Devre',
      'modules': [
        {
          'module_id': 'P-LASER',
          'kind': 'laser',
          'row': 1,
          'column': 1,
          'orientation': 'east',
          'level': 1,
        },
        {
          'module_id': 'P-SHIELD',
          'kind': 'shield',
          'row': 1,
          'column': 2,
          'orientation': 'west',
          'level': 1,
        },
      ],
    },
    'opponent_board': {
      'name': 'Kalkan Duvarı',
      'modules': [
        {
          'module_id': 'BOT-SHIELD',
          'kind': 'shield',
          'row': 2,
          'column': 1,
          'orientation': 'west',
          'level': 1,
        },
        {
          'module_id': 'BOT-REPAIR',
          'kind': 'repair',
          'row': 2,
          'column': 2,
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
        ],
      },
      'left': {
        'name': 'Mavi Devre',
        'core_hp': 100,
        'core_max_hp': 120,
        'total_damage': 120,
        'surviving_modules': 2,
        'modules': const [],
      },
      'right': {
        'name': 'Kalkan Duvarı',
        'core_hp': 0,
        'core_max_hp': 120,
        'total_damage': 20,
        'surviving_modules': 1,
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
