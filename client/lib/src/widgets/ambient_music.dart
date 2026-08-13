import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = AudioPlayer(playerId: 'ambient-${widget.asset}')
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
      unawaited(_player.stop());
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
    try {
      if (!widget.enabled || !_routeActive || !_unlocked) {
        await _player.pause();
        return;
      }
      await _player.setVolume(widget.volume);
      await _player.play(AssetSource(widget.asset));
    } catch (_) {
      // Web otomatik oynatmayı engellerse ilk kullanıcı etkileşimi yeniden dener.
      _unlocked = false;
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
