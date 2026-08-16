import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class _NoopPositionUpdater extends PositionUpdater {
  _NoopPositionUpdater() : super(getPosition: () async => null);

  @override
  void start() {}

  @override
  void stop() {}
}

class AmbientMusic extends StatefulWidget {
  const AmbientMusic({
    required this.asset,
    required this.enabled,
    required this.child,
    this.volume = 0.16,
    super.key,
  });

  final String asset;
  final bool enabled;
  final double volume;
  final Widget child;

  @override
  State<AmbientMusic> createState() => _AmbientMusicState();
}

class _AmbientMusicState extends State<AmbientMusic>
    with WidgetsBindingObserver {
  late final AudioPlayer _player;
  bool _unlocked = false;
  bool _autoplayAttempted = false;
  bool _routeActive = true;
  bool _sourceLoaded = false;
  bool _sourceChanged = false;
  bool _syncing = false;
  bool _syncRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = AudioPlayer(playerId: 'ambient-${widget.asset}')
      ..positionUpdater = _NoopPositionUpdater()
      ..setReleaseMode(ReleaseMode.loop);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeActive = TickerMode.valuesOf(context).enabled;
    if (!_autoplayAttempted && _routeActive && widget.enabled) {
      _autoplayAttempted = true;
      _unlocked = true;
    }
    unawaited(_sync());
  }

  @override
  void didUpdateWidget(covariant AmbientMusic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _sourceLoaded = false;
      _sourceChanged = true;
      _autoplayAttempted = true;
      _unlocked = true;
    } else if (!oldWidget.enabled && widget.enabled) {
      _autoplayAttempted = true;
      _unlocked = true;
    }
    unawaited(_sync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_sync());
    } else {
      unawaited(_player.pause());
    }
  }

  Future<void> _sync() async {
    if (_syncing) {
      _syncRequested = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _syncRequested = false;
        try {
          if (_sourceChanged) {
            await _player.stop();
            _sourceChanged = false;
          }
          if (!widget.enabled || !_routeActive || !_unlocked) {
            if (_sourceLoaded) await _player.pause();
            continue;
          }
          await _player.setVolume(widget.volume);
          if (_sourceLoaded) {
            await _player.resume();
          } else {
            await _player.play(AssetSource(widget.asset));
            _sourceLoaded = true;
          }
        } catch (_) {
          // Web otomatik oynatmayı engellerse ilk kullanıcı etkileşimi yeniden dener.
          _unlocked = false;
          _sourceLoaded = false;
        }
      } while (_syncRequested);
    } finally {
      _syncing = false;
    }
  }

  void _unlock() {
    if (_unlocked) return;
    _unlocked = true;
    unawaited(_sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(onPointerDown: (_) => _unlock(), child: widget.child);
  }
}
