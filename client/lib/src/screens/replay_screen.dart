import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/event_sound_player.dart';
import '../game/replay_event_formatter.dart';
import '../game/replay_game.dart';
import '../models/relay_models.dart';
import '../state/app_settings.dart';
import '../theme/relay_theme.dart';
import '../widgets/replay_attack_overlay.dart';
import '../widgets/replay_event_feed.dart';
import '../widgets/replay_playback_controls.dart';

class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({
    required this.match,
    required this.replay,
    required this.modules,
    super.key,
  });

  final MatchResponse match;
  final ReplayResponse replay;
  final List<ModuleSpec> modules;

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  late final ValueNotifier<ReplaySnapshot> _snapshot;
  late final ReplayEventFormatter _formatter;
  late final EventSoundPlayer _soundPlayer;
  late final Map<ModuleKind, ModuleSpec> _moduleSpecs;
  late final ValueNotifier<List<BattleEvent>> _attackOverlayEvents;
  late RelayReplayGame _game;
  double _speed = 1;
  bool _playing = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _speed = settings.replaySpeed;
    _soundEnabled = settings.replaySoundEnabled;
    _formatter = ReplayEventFormatter(widget.match);
    _soundPlayer = EventSoundPlayer(widget.match);
    _moduleSpecs = {
      for (final module in widget.modules) module.kind: module,
    };
    _attackOverlayEvents = ValueNotifier<List<BattleEvent>>(const []);
    _snapshot = ValueNotifier(ReplaySnapshot.initial(widget.match));
    _game = _createGame();
  }

  RelayReplayGame _createGame() {
    return RelayReplayGame(
      match: widget.match,
      replay: widget.replay,
      moduleSpecs: _moduleSpecs,
      formatter: _formatter,
      onFrame: (snapshot) {
        if (mounted) {
          _snapshot.value = snapshot;
        }
      },
      onEvents: (events) {
        final attacks = events
            .where(
              (event) =>
                  event.type == 'attack' ||
                  event.type == 'core_damage' ||
                  event.type == 'shield_absorb',
            )
            .toList(growable: false);
        if (attacks.isNotEmpty) {
          _attackOverlayEvents.value =
              List<BattleEvent>.unmodifiable(attacks);
        }
        if (_soundEnabled) {
          unawaited(_soundPlayer.playFrame(events));
        }
      },
    )..speed = _speed;
  }

  @override
  void dispose() {
    unawaited(_soundPlayer.dispose());
    _attackOverlayEvents.dispose();
    _snapshot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.match.result;
    final resultLabel = switch (result.winner) {
      'left' => 'ZAFER',
      'right' => 'YENİLGİ',
      _ => 'BERABERE',
    };
    final resultColor = switch (result.winner) {
      'left' => RelayColors.mint,
      'right' => RelayColors.coral,
      _ => RelayColors.amber,
    };
    final useInlineEventFeed =
        MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            ValueListenableBuilder<ReplaySnapshot>(
              valueListenable: _snapshot,
              builder: (context, snapshot, child) {
                return Center(
                  child: Text(
                    snapshot.complete ? resultLabel : 'SAVAŞ SÜRÜYOR',
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: snapshot.complete
                                  ? resultColor
                                  : RelayColors.amber,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                '${result.left.name}  ×  ${widget.match.opponent.displayName}',
                style: const TextStyle(color: RelayColors.muted),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: 520,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardSize = math.min(
                      constraints.maxWidth * 0.36,
                      constraints.maxHeight * 0.60,
                    );
                    final sideInset = constraints.maxWidth * 0.055;
                    final feedInset = sideInset + boardSize + 18;
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: GameWidget<RelayReplayGame>(
                            key: ValueKey(_game),
                            game: _game,
                          ),
                        ),
                        if (useInlineEventFeed)
                          Positioned(
                            left: feedInset,
                            right: feedInset,
                            top: 54,
                            bottom: 42,
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 440),
                                child:
                                    ValueListenableBuilder<ReplaySnapshot>(
                                  valueListenable: _snapshot,
                                  builder: (context, snapshot, child) {
                                    return ReplayEventFeed(
                                      events: widget.replay.events,
                                      visibleTick: snapshot.tick,
                                      formatter: _formatter,
                                      match: widget.match,
                                      replay: widget.replay,
                                      complete: snapshot.complete,
                                      currentLeftHp: snapshot.leftHp,
                                      currentRightHp: snapshot.rightHp,
                                      compact: true,
                                      controls: _playbackControls(),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: ReplayAttackOverlay(
                            events: _attackOverlayEvents,
                            match: widget.match,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (!useInlineEventFeed) ...[
              const SizedBox(height: 16),
              ValueListenableBuilder<ReplaySnapshot>(
                valueListenable: _snapshot,
                builder: (context, snapshot, child) {
                  return ReplayEventFeed(
                    events: widget.replay.events,
                    visibleTick: snapshot.tick,
                    formatter: _formatter,
                    match: widget.match,
                    replay: widget.replay,
                    complete: snapshot.complete,
                    currentLeftHp: snapshot.leftHp,
                    currentRightHp: snapshot.rightHp,
                    controls: _playbackControls(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _restart() {
    _snapshot.value = ReplaySnapshot.initial(widget.match);
    _attackOverlayEvents.value = const [];
    setState(() {
      _playing = true;
      _game = _createGame();
    });
  }

  void _togglePlayback() {
    setState(() {
      _playing = !_playing;
      if (_playing) {
        _game.resumeEngine();
      } else {
        _game.pauseEngine();
      }
    });
  }

  Widget _playbackControls() {
    return ReplayPlaybackControls(
      playing: _playing,
      soundEnabled: _soundEnabled,
      speed: _speed,
      onTogglePlayback: _togglePlayback,
      onRestart: _restart,
      onToggleSound: () {
        final enabled = !_soundEnabled;
        ref
            .read(appSettingsProvider.notifier)
            .setReplaySoundEnabled(enabled);
        setState(() => _soundEnabled = enabled);
      },
      onSpeedChanged: (value) {
        ref.read(appSettingsProvider.notifier).setReplaySpeed(value);
        setState(() {
          _speed = value;
          _game.speed = value;
        });
      },
      onNewGame: _newGame,
    );
  }

  void _newGame() {
    Navigator.of(context).pop();
  }
}
