import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../game/event_sound_player.dart';
import '../game/replay_event_formatter.dart';
import '../game/replay_game.dart';
import '../models/relay_models.dart';
import '../state/app_settings.dart';
import '../theme/cosmetic_visuals.dart';
import '../theme/relay_theme.dart';
import '../widgets/relay_notice.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/replay_attack_overlay.dart';
import '../widgets/replay_event_feed.dart';
import '../widgets/replay_playback_controls.dart';

class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({
    required this.match,
    required this.replay,
    required this.modules,
    this.battleModeLabel,
    this.primaryActionLabel = 'YENİ OYUN',
    this.primaryActionKey = 'replay-new-game-button',
    this.primaryActionRequiresCompletion = false,
    this.completionReward,
    this.completionRewardTitle = 'SAVAŞ ÖDÜLÜ',
    this.onPrimaryAction,
    super.key,
  });

  final MatchResponse match;
  final ReplayResponse replay;
  final List<ModuleSpec> modules;
  final String? battleModeLabel;
  final String primaryActionLabel;
  final String primaryActionKey;
  final bool primaryActionRequiresCompletion;
  final ProgressionReward? completionReward;
  final String completionRewardTitle;
  final VoidCallback? onPrimaryAction;

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
  bool _rewardNoticeShown = false;
  EquippedVisuals _leftVisuals = const EquippedVisuals.defaults();

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
    unawaited(_loadEquippedVisuals());
  }

  RelayReplayGame _createGame() {
    return RelayReplayGame(
      match: widget.match,
      replay: widget.replay,
      moduleSpecs: _moduleSpecs,
      formatter: _formatter,
      leftVisuals: _leftVisuals,
      onFrame: (snapshot) {
        if (!mounted) return;
        _snapshot.value = snapshot;
        if (snapshot.complete) {
          _showCompletionRewardNotice();
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

  Future<void> _loadEquippedVisuals() async {
    try {
      final collection = await ref.read(collectionProvider.future);
      final next = EquippedVisuals.fromCollection(collection);
      if (!mounted ||
          (next.board.id == _leftVisuals.board.id &&
              next.modules.id == _leftVisuals.modules.id)) {
        return;
      }
      setState(() {
        _leftVisuals = next;
        _snapshot.value = ReplaySnapshot.initial(widget.match);
        _attackOverlayEvents.value = const [];
        _game = _createGame();
      });
    } catch (_) {
      // Kozmetik servisi kullanılamazsa savaş varsayılan görünümle devam eder.
    }
  }

  void _showCompletionRewardNotice() {
    final reward = widget.completionReward ??
        (widget.match.source == 'async'
            ? widget.match.progressionReward
            : null);
    if (_rewardNoticeShown || reward == null) {
      return;
    }
    _rewardNoticeShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (reward.levelUp) {
        RelayNotice.showLevelUp(
          context,
          level: reward.levelAfter,
          xp: reward.xp,
          credits: reward.credits,
          unlockLabel: levelUnlockLabel(
            reward.levelAfter,
            previousLevel: reward.levelBefore,
          ),
        );
      } else {
        final season = widget.match.seasonChange;
        final seasonLine = season == null
            ? ''
            : '\n+${season.pointsGained} Sezon Puanı • Toplam ${season.totalPoints}';
        RelayNotice.show(
          context,
          '${widget.completionRewardTitle}\n+${reward.xp} XP • '
          '+${reward.credits} Devre Kredisi • SV ${reward.levelAfter}'
          '$seasonLine',
          tone: RelayNoticeTone.success,
          duration: const Duration(seconds: 7),
        );
      }
      if (widget.match.seasonChange != null) {
        ref.invalidate(seasonProvider);
      }
    });
  }

  @override
  void dispose() {
    RelayNotice.dismiss();
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
    final mediaSize = MediaQuery.sizeOf(context);
    final useInlineEventFeed = mediaSize.width >= 1500;
    final stageHeight = (mediaSize.height - 130)
        .clamp(540.0, 620.0)
        .toDouble();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: AppHeaderActions(),
            ),
            const SizedBox(height: 6),
            if (widget.battleModeLabel != null) ...[
              Center(
                child: Text(
                  widget.battleModeLabel!,
                  key: const ValueKey('replay-battle-mode-label'),
                  style: const TextStyle(
                    color: RelayColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
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
                height: stageHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stageSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final leftBoard = ReplayStageGeometry.leftBoard(stageSize);
                    final feedInset = leftBoard.right + 14;
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
                            top: 48,
                            bottom: 24,
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 540),
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
                                      controls: _playbackControls(
                                        complete: snapshot.complete,
                                      ),
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
                            leftVisuals: _leftVisuals,
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
                    controls: _playbackControls(
                      complete: snapshot.complete,
                    ),
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
    RelayNotice.dismiss();
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

  Widget _playbackControls({required bool complete}) {
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
      onNewGame: _primaryAction,
      primaryActionLabel: widget.primaryActionLabel,
      primaryActionKey: widget.primaryActionKey,
      primaryActionEnabled:
          !widget.primaryActionRequiresCompletion || complete,
    );
  }

  void _primaryAction() {
    RelayNotice.dismiss();
    final callback = widget.onPrimaryAction;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).pop();
  }
}
