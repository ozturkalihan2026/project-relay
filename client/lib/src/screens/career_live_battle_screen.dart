import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../state/app_settings.dart';
import '../theme/cosmetic_visuals.dart';
import '../theme/relay_theme.dart';
import '../widgets/ambient_music.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/circuit_board.dart';
import '../widgets/module_visuals.dart';
import '../widgets/relay_notice.dart';
import 'career_battle_screen.dart';

/// Runs a server-authoritative career battle without pausing for intervention.
///
/// The reserve shelf remains visible throughout combat, becomes draggable while
/// a rolling intervention window is open, and locks as soon as one swap is
/// queued. The server applies that swap on the next simulation tick.
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

class _CareerLiveBattleScreenState
    extends ConsumerState<CareerLiveBattleScreen> {
  static const _tickInterval = Duration(milliseconds: 540);

  late CareerBattleSessionSnapshot _session;
  late final Map<ModuleKind, ModuleSpec> _specs;
  late final Timer _battleTimer;
  bool _advancing = false;
  bool _swapping = false;
  bool _openingReplay = false;
  String? _lastAdvanceError;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _specs = {for (final module in widget.modules) module.kind: module};
    _battleTimer = Timer.periodic(
      _tickInterval,
      (_) => unawaited(_advanceBattle()),
    );
    if (_session.complete) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_openCompletedReplay()),
      );
    }
  }

  @override
  void dispose() {
    _battleTimer.cancel();
    super.dispose();
  }

  Future<void> _advanceBattle() async {
    if (_advancing || _openingReplay || _session.complete) {
      if (_session.complete) await _openCompletedReplay();
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
      if (next.complete) await _openCompletedReplay();
    } on RelayApiException catch (error) {
      _showAdvanceError(error.message);
    } catch (error) {
      _showAdvanceError('Canlı savaş bağlantısı yenileniyor: $error');
    } finally {
      _advancing = false;
    }
  }

  void _showAdvanceError(String message) {
    if (!mounted || _lastAdvanceError == message) return;
    _lastAdvanceError = message;
    RelayNotice.show(context, message, tone: RelayNoticeTone.warning);
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

  Future<void> _openCompletedReplay() async {
    final match = _session.match;
    if (!mounted || _openingReplay || match == null) return;
    _openingReplay = true;
    try {
      final replay = await ref.read(relayApiProvider).fetchReplay(match.id);
      if (replay.checksum != match.replayChecksum) {
        throw const RelayApiException(
          'Kariyer tekrar özeti maç sonucuyla uyuşmuyor.',
        );
      }
      if (!mounted) return;
      _battleTimer.cancel();
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (context) => CareerBattleScreen(
            outcome: CareerBattleResponse(match: match, run: _session.run),
            replay: replay,
            modules: widget.modules,
            stageNumber: widget.stageNumber,
          ),
        ),
      );
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
      _openingReplay = false;
    }
  }

  bool get _interventionUsable =>
      _session.intervention.active &&
      !_session.intervention.pending &&
      _session.intervention.swapsRemaining > 0 &&
      !_swapping &&
      !_session.complete;

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
                child: _LiveBoards(
                  session: _session,
                  specs: _specs,
                  visuals: widget.visuals,
                  interventionUsable: _interventionUsable,
                  onModuleDropped: _queueSwap,
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

class _LiveBoards extends StatelessWidget {
  const _LiveBoards({
    required this.session,
    required this.specs,
    required this.visuals,
    required this.interventionUsable,
    required this.onModuleDropped,
  });

  final CareerBattleSessionSnapshot session;
  final Map<ModuleKind, ModuleSpec> specs;
  final EquippedVisuals visuals;
  final bool interventionUsable;
  final ModuleDropCallback onModuleDropped;

  Map<int, ModulePlacement> _placements(BoardDraft board) => {
    for (final module in board.modules) module.cellIndex: module,
  };

  Set<String> _powered(BoardReplayState board) => board.modules
      .where((module) => module.powered)
      .map((module) => module.id)
      .toSet();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = math.max(
          180.0,
          math.min(constraints.maxHeight - 46, (constraints.maxWidth - 24) / 2),
        );
        return Row(
          children: [
            Expanded(
              child: _LiveBoardPane(
                title: 'SENİN DEVREN',
                accent: RelayColors.cyan,
                boardSize: boardSize,
                board: CircuitBoard(
                  key: const ValueKey('live-player-board'),
                  placements: _placements(session.playerBoard),
                  specs: specs,
                  poweredIds: _powered(session.frame.left),
                  validationVisible: true,
                  selectedCell: null,
                  onCellTap: (_) {},
                  onModuleDropped: onModuleDropped,
                  onRotateModule: (_) {},
                  canAcceptModuleDrop: (cellIndex, data) =>
                      interventionUsable &&
                      data.moduleId != null &&
                      _placements(session.playerBoard).containsKey(cellIndex),
                  moduleDraggingEnabled: false,
                  visuals: visuals,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LiveBoardPane(
                title: session.opponent.displayName,
                accent: session.opponent.isBoss
                    ? RelayColors.coral
                    : RelayColors.amber,
                boardSize: boardSize,
                board: CircuitBoard(
                  key: const ValueKey('live-opponent-board'),
                  placements: _placements(session.opponentBoard),
                  specs: specs,
                  poweredIds: _powered(session.frame.right),
                  validationVisible: true,
                  selectedCell: null,
                  onCellTap: (_) {},
                  onModuleDropped: (_, _) {},
                  onRotateModule: (_) {},
                  canAcceptModuleDrop: (_, _) => false,
                  moduleDraggingEnabled: false,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LiveBoardPane extends StatelessWidget {
  const _LiveBoardPane({
    required this.title,
    required this.accent,
    required this.boardSize,
    required this.board,
  });

  final String title;
  final Color accent;
  final double boardSize;
  final Widget board;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: RelayDecorations.panel(accent: accent, soft: true),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Center(
              child: SizedBox.square(dimension: boardSize, child: board),
            ),
          ),
        ],
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
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 158, height: 82, child: tile),
      ),
      childWhenDragging: Opacity(opacity: 0.28, child: tile),
      child: MouseRegion(cursor: SystemMouseCursors.grab, child: tile),
    );
  }
}
