import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../models/relay_models.dart';

typedef EventSoundChannelFactory = EventSoundChannel Function();

abstract interface class EventSoundChannel {
  Stream<void> get onComplete;

  Future<void> play(String asset, double volume);

  Future<void> dispose();
}

class EventSoundPlayer {
  EventSoundPlayer(
    MatchResponse match, {
    EventSoundChannelFactory? channelFactory,
  }) : this.fromBoards(
         playerBoard: match.playerBoard,
         opponentBoard: match.opponentBoard,
         channelFactory: channelFactory,
       );

  /// Canlı savaş modu için: henüz maç kaydı yokken ses türleri kartlardan okunur.
  EventSoundPlayer.fromBoards({
    required BoardDraft playerBoard,
    required BoardDraft opponentBoard,
    EventSoundChannelFactory? channelFactory,
  }) : _moduleKinds = {
         for (final module in playerBoard.modules) module.id: module.kind,
         for (final module in opponentBoard.modules) module.id: module.kind,
       },
       _channelFactory = channelFactory ?? _createEventSoundChannel;

  final Map<String, ModuleKind> _moduleKinds;
  final EventSoundChannelFactory _channelFactory;
  final Set<EventSoundChannel> _activeChannels = {};
  bool _disposed = false;

  Future<void> playFrame(List<BattleEvent> events) async {
    if (_disposed) {
      return;
    }
    final playedWeapons = <String>{};
    for (final event in events) {
      if (_disposed) {
        return;
      }
      final weaponEvent =
          event.type == 'attack' ||
          event.type == 'core_damage' ||
          event.type == 'shield_absorb';
      if (weaponEvent) {
        final actionKey = '${event.tick}:${event.side}:${event.actorId}';
        if (playedWeapons.add(actionKey)) {
          final layers = <Future<void>>[
            _play(_weaponAsset(event), _volume(event)),
            if (event.type == 'attack') _play('attack.wav', 0.30),
            if (event.type == 'core_damage') _play('core_damage.wav', 0.66),
          ];
          await Future.wait(layers);
        }
        if (event.type == 'shield_absorb') {
          await _play('shield_absorb.wav', 0.58);
        }
        continue;
      }
      final asset = _soundAsset(event);
      if (asset != null) {
        await _play(asset, _volume(event));
      }
    }
  }

  Future<void> _play(String asset, double volume) async {
    if (_disposed) {
      return;
    }
    final channel = _channelFactory();
    _activeChannels.add(channel);
    unawaited(
      channel.onComplete.first.then<void>(
        (_) => _release(channel),
        onError: (Object error, StackTrace stackTrace) => _release(channel),
      ),
    );
    try {
      await channel.play('sounds/$asset', volume);
    } on Object {
      await _release(channel);
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final channels = List<EventSoundChannel>.of(_activeChannels);
    _activeChannels.clear();
    await Future.wait(channels.map(_disposeSafely));
  }

  Future<void> _release(EventSoundChannel channel) async {
    if (!_activeChannels.remove(channel)) {
      return;
    }
    await _disposeSafely(channel);
  }

  Future<void> _disposeSafely(EventSoundChannel channel) async {
    try {
      await channel.dispose();
    } on Object {
      // A route can close while the web player is still starting. Disposal is
      // best-effort and must not surface an unhandled browser AbortError.
    }
  }

  String _weaponAsset(BattleEvent event) =>
      switch (_moduleKinds[event.actorId]) {
        ModuleKind.laser => 'laser.wav',
        ModuleKind.pulseCannon => 'pulse_cannon.wav',
        _ => 'attack.wav',
      };

  String? _soundAsset(BattleEvent event) => switch (event.type) {
    'shield' => 'shield_charge.wav',
    'cool' => 'cool.wav',
    'repair' => 'repair.wav',
    'recovered' => 'recovered.wav',
    'overheat' => 'overheat.wav',
    'energy_starved' => 'energy_starved.wav',
    'destroyed' => 'destroyed.wav',
    _ => null,
  };

  double _volume(BattleEvent event) => switch (event.type) {
    'attack' || 'core_damage' => 0.54,
    'shield' || 'shield_absorb' => 0.58,
    'destroyed' => 0.62,
    _ => 0.48,
  };
}

EventSoundChannel _createEventSoundChannel() => _AudioPlayerSoundChannel();

class _AudioPlayerSoundChannel implements EventSoundChannel {
  _AudioPlayerSoundChannel() : _player = AudioPlayer() {
    _player.positionUpdater = _NoopPositionUpdater();
  }

  final AudioPlayer _player;

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;

  @override
  Future<void> play(String asset, double volume) {
    return _player.play(AssetSource(asset), volume: volume);
  }

  @override
  Future<void> dispose() => _player.dispose();
}

/// Varsayılan [FramePositionUpdater] web'de her karede `getCurrentPosition`
/// çağırır. Oynatıcı kapanırken askıda kalan bir kare, oynatıcı platform
/// haritasından düşmüşse `PlatformException(WebAudioError, ...)` üretip
/// konsolu doldurur. Tek seferlik efekt seslerinde konum akışı kullanılmadığı
/// için boş bir updater ile bu çağrılar tamamen kesilir.
class _NoopPositionUpdater extends PositionUpdater {
  _NoopPositionUpdater() : super(getPosition: () async => null);

  @override
  void start() {}

  @override
  void stop() {}
}
