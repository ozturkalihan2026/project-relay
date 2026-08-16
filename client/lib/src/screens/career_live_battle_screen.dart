import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../game/event_sound_player.dart';
import '../game/replay_event_formatter.dart';
import '../game/replay_game.dart';
import '../models/relay_models.dart';
import '../state/app_settings.dart';
import '../theme/circuit_presentation.dart';
import '../theme/cosmetic_visuals.dart';
import '../theme/relay_theme.dart';
import '../widgets/ambient_music.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/battle_analysis_panel.dart';
import '../widgets/battle_arena_atmosphere.dart';
import '../widgets/battle_camera_rig.dart';
import '../widgets/circuit_board.dart';
import '../widgets/module_visuals.dart';
import '../widgets/relay_notice.dart';
import '../widgets/replay_attack_overlay.dart';

/// Sunucu otoriteli kariyer savaşını müdahale için duraklatmadan canlı oynatır.
///
/// Savaşın görsel akışı replay ile aynı donanımı kullanır: gerçek portlar,
/// kablolar, enerji parçacıkları ve saldırı/kalkan/onarım olayları canlı sahnede
/// eş zamanlı oynatılır. Yedek rafı savaş boyunca görünür kalır, açık müdahale
/// penceresinde sürüklenebilir ve sıraya alınan değişim sonraki güvenli sunucu
/// tick'inde uygulanır. Savaş tamamlanınca sonuç aynı sahnede analiz paneliyle
/// gösterilir; otomatik replay ekranı açılmaz.
class CareerLiveBattleScreen extends ConsumerStatefulWidget {
  const CareerLiveBattleScreen({
    required this.initialSession,
    required this.modules,
    required this.visuals,
    required this.stageNumber,
    super.key,
  });

  final CareerBattleSessionSnapshot initialSession;
  final List<ModuleSpec> modules;
  final EquippedVisuals visuals;
  final int stageNumber;

  @override
  ConsumerState<CareerLiveBattleScreen> createState() =>
      _CareerLiveBattleScreenState();
}

const _visualEventTypes = <String>{
  'attack',
  'overload',
  'core_damage',
  'shield_absorb',
  'shield',
  'repair',
  'recovered',
  'destroyed',
  'overheat',
  'cool',
  'energy_starved',
};

class _CareerLiveBattleScreenState
    extends ConsumerState<CareerLiveBattleScreen> {
  static const _tickInterval = Duration(milliseconds: 540);

  late CareerBattleSessionSnapshot _session;
  late final Map<ModuleKind, ModuleSpec> _specs;
  late final ReplayEventFormatter _formatter;
  late final EventSoundPlayer _soundPlayer;
  late final ValueNotifier<List<BattleEvent>> _attackOverlayEvents;
  late final Timer _battleTimer;
  late RelayReplayGame _game;
  bool _advancing = false;
  bool _swapping = false;
  bool _resultLoading = false;
  int _processedEventCount = 0;
  ReplayResponse? _resultReplay;
  String? _lastAdvanceError;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _specs = {for (final module in widget.modules) module.kind: module};
    _formatter = ReplayEventFormatter.fromBoards(
      playerBoard: _session.playerBoard,
      opponentBoard: _session.opponentBoard,
      opponentName: _session.opponent.displayName,
    );
    _soundPlayer = EventSoundPlayer.fromBoards(
      playerBoard: _session.playerBoard,
      opponentBoard: _session.opponentBoard,
    );
    _attackOverlayEvents = ValueNotifier<List<BattleEvent>>(const []);
    _processedEventCount = _session.events.length;
    _game = _createLiveGame();
    _battleTimer = Timer.periodic(
      _tickInterval,
      (_) => unawaited(_advanceBattle()),
    );
    if (_session.complete) {
      _battleTimer.cancel();
      unawaited(_loadResultReplay());
    }
  }

  @override
  void dispose() {
    _battleTimer.cancel();
    unawaited(_soundPlayer.dispose());
    _attackOverlayEvents.dispose();
    super.dispose();
  }

  RelayReplayGame _createLiveGame() {
    return RelayReplayGame.live(
      playerBoard: _session.playerBoard,
      opponentBoard: _session.opponentBoard,
      initialFrame: _session.frame,
      opponentName: _session.opponent.displayName,
      leftCoreMaxHp: _session.frame.left.coreHp,
      rightCoreMaxHp: _session.frame.right.coreHp,
      moduleSpecs: _specs,
      formatter: _formatter,
      leftVisuals: widget.visuals,
      onFrame: (_) {},
      onEvents: (_) {},
    );
  }

  Future<void> _advanceBattle() async {
    if (_advancing || _session.complete) {
      return;
    }
    _advancing = true;
    try {
      final next = await ref
          .read(relayApiProvider)
          .advanceCareerBattleSession();
      if (!mounted) return;
      setState(() {
        _session = next;
        _lastAdvanceError = null;
      });
      _feedSession(next);
      if (next.complete) {
        _battleTimer.cancel();
        _game.markLiveComplete(
          finalTick: next.tick,
          resultLabel: _resultLabel(next.match?.result.winner),
        );
        unawaited(_loadResultReplay());
      }
    } on RelayApiException catch (error) {
      _showAdvanceError(error.message);
    } catch (error) {
      _showAdvanceError('Canlı savaş bağlantısı yenileniyor: $error');
    } finally {
      _advancing = false;
    }
  }

  void _feedSession(CareerBattleSessionSnapshot session) {
    final newEvents = session.events.length <= _processedEventCount
        ? const <BattleEvent>[]
        : session.events.sublist(_processedEventCount);
    _processedEventCount = session.events.length;
    _game.feedLiveFrame(frame: session.frame, newEvents: newEvents);
    if (newEvents.isNotEmpty &&
        ref.read(appSettingsProvider).replaySoundEnabled) {
      unawaited(_soundPlayer.playFrame(newEvents));
    }
    final visualEvents = newEvents
        .where((event) => _visualEventTypes.contains(event.type))
        .toList(growable: false);
    if (visualEvents.isNotEmpty) {
      _attackOverlayEvents.value = List<BattleEvent>.unmodifiable(visualEvents);
    }
  }

  void _showAdvanceError(String message) {
    if (!mounted || _lastAdvanceError == message) return;
    _lastAdvanceError = message;
    RelayNotice.show(context, message, tone: RelayNoticeTone.warning);
  }

  Future<void> _loadResultReplay() async {
    final match = _session.match;
    if (!mounted || _resultLoading || match == null) return;
    _resultLoading = true;
    try {
      final replay = await ref.read(relayApiProvider).fetchReplay(match.id);
      if (replay.checksum != match.replayChecksum) {
        throw const RelayApiException(
          'Kariyer tekrar özeti maç sonucuyla uyuşmuyor.',
        );
      }
      if (!mounted) return;
      setState(() => _resultReplay = replay);
    } on RelayApiException catch (error) {
      if (mounted) {
        RelayNotice.show(context, error.message, tone: RelayNoticeTone.error);
      }
    } catch (error) {
      if (mounted) {
        RelayNotice.show(
          context,
          'Savaş sonucu açılırken bağlantı kurulamadı: $error',
          tone: RelayNoticeTone.error,
        );
      }
    } finally {
      _resultLoading = false;
    }
  }

  Future<void> _queueSwap(int cellIndex, ModuleDragData data) async {
    final incomingId = data.moduleId;
    final outgoing = _placements(_session.playerBoard)[cellIndex];
    if (!_interventionUsable || incomingId == null || outgoing == null) return;
    setState(() => _swapping = true);
    try {
      final next = await ref
          .read(relayApiProvider)
          .swapCareerBattleModule(
            outgoingId: outgoing.id,
            incomingId: incomingId,
            orientation: outgoing.orientation,
          );
      if (!mounted) return;
      setState(() => _session = next);
      _feedSession(next);
      RelayNotice.show(
        context,
        '${outgoing.kind.displayName} çıkışa, yedek modül girişe alındı. Değişim bir sonraki sinyalde uygulanacak.',
        tone: RelayNoticeTone.success,
      );
    } on RelayApiException catch (error) {
      if (mounted) {
        RelayNotice.show(context, error.message, tone: RelayNoticeTone.error);
      }
    } catch (error) {
      if (mounted) {
        RelayNotice.show(
          context,
          'Modül değişimi sıraya alınamadı: $error',
          tone: RelayNoticeTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _swapping = false);
    }
  }

  bool get _interventionUsable =>
      _session.intervention.active &&
      !_session.intervention.pending &&
      _session.intervention.swapsRemaining > 0 &&
      !_swapping &&
      !_session.complete;

  static String _resultLabel(String? winner) => switch (winner) {
    'left' => 'ZAFER',
    'right' => 'YENİLGİ',
    _ => 'BERABERE',
  };

  Map<int, ModulePlacement> _placements(BoardDraft board) => {
    for (final module in board.modules) module.cellIndex: module,
  };

  @override
  Widget build(BuildContext context) {
    final soundEnabled = ref.watch(appSettingsProvider).replaySoundEnabled;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey('live-battle-back-button'),
          tooltip: 'Kariyere dön',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        centerTitle: true,
        title: const AppHeaderTitle(pageTitle: 'CANLI KARİYER SAVAŞI'),
        actions: const [AppHeaderActions(), SizedBox(width: 8)],
      ),
      body: AmbientMusic(
        asset: 'sounds/battle_ambient.wav',
        enabled: soundEnabled,
        volume: 0.20,
        child: Container(
          key: const ValueKey('career-live-battle-screen'),
          decoration: RelayDecorations.modeShell(RelayColors.coral),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            children: [
              _LiveBattleHeader(session: _session),
              const SizedBox(height: 10),
              Expanded(
                child: _LiveBattleStage(
                  session: _session,
                  game: _game,
                  visuals: widget.visuals,
                  attackOverlayEvents: _attackOverlayEvents,
                  interventionUsable: _interventionUsable,
                  onModuleDropped: _queueSwap,
                  resultReplay: _resultReplay,
                  modules: widget.modules,
                ),
              ),
              const SizedBox(height: 10),
              _InterventionShelf(
                session: _session,
                specs: _specs,
                visuals: widget.visuals,
                enabled: _interventionUsable,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveBattleHeader extends StatelessWidget {
  const _LiveBattleHeader({required this.session});

  final CareerBattleSessionSnapshot session;

  @override
  Widget build(BuildContext context) {
    final event = session.events.isEmpty ? null : session.events.last;
    final status = session.complete
        ? 'SAVAŞ TAMAMLANDI'
        : session.intervention.pending
        ? 'DEĞİŞİM SIRAYA ALINDI • SAVAŞ DEVAM EDİYOR'
        : session.intervention.active
        ? 'MÜDAHALE SİNYALİ AÇIK • SAVAŞ DEVAM EDİYOR'
        : 'SİNYAL AKIŞI • CANLI';
    return Container(
      key: const ValueKey('live-battle-status'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: RelayDecorations.panel(
        accent: session.intervention.active
            ? RelayColors.amber
            : RelayColors.cyan,
        soft: true,
      ),
      child: Row(
        children: [
          Icon(
            session.intervention.active ? Icons.swap_horiz : Icons.sensors,
            color: session.intervention.active
                ? RelayColors.amber
                : RelayColors.mint,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event == null
                      ? '${session.opponent.displayName} ile bağlantı kuruldu.'
                      : _eventLabel(event),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RelayColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _CoreHealth(label: 'SEN', state: session.frame.left),
          const SizedBox(width: 8),
          _CoreHealth(label: 'RAKİP', state: session.frame.right),
        ],
      ),
    );
  }

  static String _eventLabel(BattleEvent event) => switch (event.type) {
    'attack' => '${event.actorId} saldırı sinyali gönderdi.',
    'shield' || 'shield_absorb' => 'Kalkan darbe yükünü karşıladı.',
    'repair' => 'Onarım hattı devreyi güçlendirdi.',
    'module_swap' => 'Canlı modül değişimi devreye uygulandı.',
    'destroyed' => '${event.targetId ?? 'Bir modül'} devre dışı kaldı.',
    _ => 'Devrede ${event.type.replaceAll('_', ' ')} sinyali işlendi.',
  };
}

class _CoreHealth extends StatelessWidget {
  const _CoreHealth({required this.label, required this.state});

  final String label;
  final BoardReplayState state;

  @override
  Widget build(BuildContext context) {
    final hp = state.coreHp.clamp(0, 100).round();
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: RelayColors.background.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RelayColors.cyan.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label  $hp',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            minHeight: 4,
            value: hp / 100,
            color: hp > 30 ? RelayColors.mint : RelayColors.coral,
          ),
        ],
      ),
    );
  }
}

class _LiveBattleStage extends StatefulWidget {
  const _LiveBattleStage({
    required this.session,
    required this.game,
    required this.visuals,
    required this.attackOverlayEvents,
    required this.interventionUsable,
    required this.onModuleDropped,
    required this.resultReplay,
    required this.modules,
  });

  final CareerBattleSessionSnapshot session;
  final RelayReplayGame game;
  final EquippedVisuals visuals;
  final ValueListenable<List<BattleEvent>> attackOverlayEvents;
  final bool interventionUsable;
  final ModuleDropCallback onModuleDropped;
  final ReplayResponse? resultReplay;
  final List<ModuleSpec> modules;

  @override
  State<_LiveBattleStage> createState() => _LiveBattleStageState();
}

class _LiveBattleStageState extends State<_LiveBattleStage> {
  final GlobalKey _dropTargetKey = GlobalKey();

  Map<int, ModulePlacement> _placements(BoardDraft board) => {
    for (final module in board.modules) module.cellIndex: module,
  };

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final placements = _placements(session.playerBoard);
    final finalTick = session.complete ? session.tick : null;
    return Card(
      key: const ValueKey('career-live-battle-stage'),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: BattleArenaAtmosphere(
        events: widget.attackOverlayEvents,
        child: BattleCameraRig(
          events: widget.attackOverlayEvents,
          playerBoard: session.playerBoard,
          opponentBoard: session.opponentBoard,
          finalTick: finalTick,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final leftBoard = ReplayStageGeometry.leftBoard(size);
              final cellSize =
                  leftBoard.width / CircuitPresentationSpec.gridSize;
              return Stack(
                fit: StackFit.expand,
                children: [
                  GameWidget<RelayReplayGame>(
                    key: ValueKey(widget.game),
                    game: widget.game,
                  ),
                  ReplayAttackOverlay(
                    events: widget.attackOverlayEvents,
                    playerBoard: session.playerBoard,
                    opponentBoard: session.opponentBoard,
                    finalTick: finalTick,
                    leftVisuals: widget.visuals,
                  ),
                  if (widget.interventionUsable)
                    Positioned.fromRect(
                      rect: leftBoard,
                      child: DragTarget<ModuleDragData>(
                        key: _dropTargetKey,
                        onWillAcceptWithDetails: (details) {
                          final cell = _cellForDrop(
                            context,
                            details.offset,
                            leftBoard,
                            cellSize,
                          );
                          return details.data.moduleId != null &&
                              placements.containsKey(cell);
                        },
                        onAcceptWithDetails: (details) {
                          final cell = _cellForDrop(
                            context,
                            details.offset,
                            leftBoard,
                            cellSize,
                          );
                          widget.onModuleDropped(cell, details.data);
                        },
                        builder: (context, candidates, rejects) {
                          final hovering = candidates.isNotEmpty;
                          final rejected = !hovering && rejects.isNotEmpty;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                CircuitPresentationSpec.boardCornerRadius,
                              ),
                              border: Border.all(
                                color: hovering
                                    ? RelayColors.amber.withValues(alpha: 0.95)
                                    : rejected
                                    ? RelayColors.coral.withValues(alpha: 0.55)
                                    : RelayColors.amber.withValues(alpha: 0.0),
                                width: 2.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (session.complete &&
                      session.match != null &&
                      widget.resultReplay != null)
                    _analysisOverlay(
                      context,
                      session.match!,
                      widget.resultReplay!,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  int _cellForDrop(
    BuildContext context,
    Offset global,
    Rect board,
    double cellSize,
  ) {
    final object = _dropTargetKey.currentContext?.findRenderObject();
    final renderBox = object is RenderBox ? object : null;
    final local = renderBox == null
        ? board.topLeft
        : renderBox.globalToLocal(global);
    final grid = CircuitPresentationSpec.gridSize;
    final shear = ReplayStageGeometry.perspectiveShear;
    final centerY = board.height / 2;
    final unskewedX = local.dx - shear * (local.dy - centerY);
    final row = (local.dy / cellSize).floor().clamp(0, grid - 1);
    final column = (unskewedX / cellSize).floor().clamp(0, grid - 1);
    return row * grid + column;
  }

  Widget _analysisOverlay(
    BuildContext context,
    MatchResponse match,
    ReplayResponse replay,
  ) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final panelWidth = compact
              ? constraints.maxWidth * 0.72
              : (constraints.maxWidth * 0.20).clamp(210.0, 270.0);
          return Center(
            child: SizedBox(
              width: panelWidth,
              height: constraints.maxHeight * 0.82,
              child: BattleCenterAnalysisPanel(
                match: match,
                replay: replay,
                modules: widget.modules,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InterventionShelf extends StatelessWidget {
  const _InterventionShelf({
    required this.session,
    required this.specs,
    required this.visuals,
    required this.enabled,
  });

  final CareerBattleSessionSnapshot session;
  final Map<ModuleKind, ModuleSpec> specs;
  final EquippedVisuals visuals;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final state = session.intervention;
    final label = session.complete
        ? 'SAVAŞ TAMAMLANDI'
        : state.pending
        ? 'DEĞİŞİM SIRAYA ALINDI • RAF KİLİTLENDİ'
        : enabled
        ? 'MÜDAHALE RAFI AKTİF • YEDEĞİ DEVREDEKİ MODÜLÜN ÜZERİNE SÜRÜKLE'
        : state.swapsRemaining == 0
        ? 'MÜDAHALE HAKLARI KULLANILDI'
        : 'MÜDAHALE RAFI • SİNYAL BEKLENİYOR';
    final accent = enabled ? RelayColors.amber : RelayColors.cyan;
    return AnimatedContainer(
      key: const ValueKey('career-live-intervention-shelf'),
      duration: const Duration(milliseconds: 180),
      height: 116,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: RelayDecorations.panel(accent: accent),
      child: Row(
        children: [
          SizedBox(
            width: 265,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      enabled ? Icons.swap_horiz : Icons.inventory_2_outlined,
                      color: accent,
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${state.swapsRemaining}/2 değişim hakkı • savaş duraklatılmaz',
                  style: const TextStyle(
                    color: RelayColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 24),
          Expanded(
            child: session.reserves.isEmpty
                ? const Center(
                    child: Text(
                      'Rafta kullanılabilir yedek modül yok.',
                      style: TextStyle(color: RelayColors.muted),
                    ),
                  )
                : ListView.separated(
                    key: const ValueKey('career-live-reserve-list'),
                    scrollDirection: Axis.horizontal,
                    itemCount: session.reserves.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final reserve = session.reserves[index];
                      return _ReserveTile(
                        reserve: reserve,
                        spec: specs[reserve.kind],
                        color: visuals.modules.moduleColorFor(reserve.kind),
                        enabled: enabled,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReserveTile extends StatelessWidget {
  const _ReserveTile({
    required this.reserve,
    required this.spec,
    required this.color,
    required this.enabled,
  });

  final CareerReserveModule reserve;
  final ModuleSpec? spec;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      key: ValueKey('live-reserve-${reserve.id}'),
      width: 158,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: enabled ? 0.28 : 0.12),
            RelayColors.background.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? color : RelayColors.muted.withValues(alpha: 0.24),
          width: enabled ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          ModuleHardware(kind: reserve.kind, color: color, size: 48),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec?.displayName ?? reserve.kind.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'SV. ${reserve.level}${enabled ? ' • SÜRÜKLE' : ''}',
                  style: TextStyle(
                    color: enabled ? color : RelayColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (!enabled) return Opacity(opacity: 0.62, child: tile);
    return Draggable<ModuleDragData>(
      data: ModuleDragData.reserve(kind: reserve.kind, moduleId: reserve.id),
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 158,
          height: 82,
          child: Transform.translate(
            offset: const Offset(-79, -41),
            child: tile,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.28, child: tile),
      child: MouseRegion(cursor: SystemMouseCursors.grab, child: tile),
    );
  }
}
