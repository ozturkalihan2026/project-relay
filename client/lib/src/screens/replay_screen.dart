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
import '../widgets/ambient_music.dart';
import '../widgets/replay_attack_overlay.dart';
import '../widgets/battle_analysis_panel.dart';
import '../widgets/battle_arena_atmosphere.dart';
import '../widgets/battle_camera_rig.dart';
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
    this.moduleUpgradeBranches = const {},
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
  final Map<String, String> moduleUpgradeBranches;

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
  double _speed = 0.75;
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
    _moduleSpecs = {for (final module in widget.modules) module.kind: module};
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
      moduleUpgradeBranches: widget.moduleUpgradeBranches,
      onFrame: (snapshot) {
        if (!mounted) return;
        _snapshot.value = snapshot;
        if (snapshot.complete) {
          _showCompletionRewardNotice();
        }
      },
      onEvents: (events) {
        final visualEvents = events
            .where(
              (event) =>
                  event.type == 'attack' ||
                  event.type == 'core_damage' ||
                  event.type == 'shield_absorb' ||
                  event.type == 'shield' ||
                  event.type == 'repair' ||
                  event.type == 'recovered' ||
                  event.type == 'destroyed' ||
                  event.type == 'overheat' ||
                  event.type == 'cool' ||
                  event.type == 'energy_starved',
            )
            .toList(growable: false);
        if (visualEvents.isNotEmpty) {
          _attackOverlayEvents.value = List<BattleEvent>.unmodifiable(
            visualEvents,
          );
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
    final reward =
        widget.completionReward ??
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
        RelayNotice.showReward(
          context,
          title: widget.completionRewardTitle,
          xp: reward.xp,
          credits: reward.credits,
          kind: widget.match.result.winner == 'left'
              ? RelayRewardKind.victory
              : RelayRewardKind.generic,
          detail: seasonLine.trim().isEmpty
              ? 'SV ${reward.levelAfter}'
              : 'SV ${reward.levelAfter} • ${seasonLine.trim()}',
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
    final stageHeight = (mediaSize.height - 130).clamp(540.0, 620.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 224,
        leading: const AppHeaderProfile(),
        centerTitle: true,
        title: AppHeaderTitle(
          pageTitle: (widget.battleModeLabel ?? 'SAVAŞ').toUpperCase(),
        ),
        actions: const [AppHeaderActions(), SizedBox(width: 8)],
      ),
      body: AmbientMusic(
        asset: 'sounds/battle_ambient.wav',
        enabled: _soundEnabled,
        volume: 0.12,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
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
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
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
                  child: BattleArenaAtmosphere(
                    events: _attackOverlayEvents,
                    child: BattleCameraRig(
                      events: _attackOverlayEvents,
                      match: widget.match,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: GameWidget<RelayReplayGame>(
                              key: ValueKey(_game),
                              game: _game,
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
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<ReplaySnapshot>(
                valueListenable: _snapshot,
                builder: (context, snapshot, child) {
                  return Column(
                    children: [
                      _playbackControls(complete: snapshot.complete),
                      if (snapshot.complete) ...[
                        const SizedBox(height: 20),
                        BattleAnalysisPanel(
                          match: widget.match,
                          replay: widget.replay,
                          modules: widget.modules,
                          onRematch: _primaryAction,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
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
        ref.read(appSettingsProvider.notifier).setReplaySoundEnabled(enabled);
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
      primaryActionEnabled: !widget.primaryActionRequiresCompletion || complete,
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
