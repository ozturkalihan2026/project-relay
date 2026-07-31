import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import '../widgets/circuit_board.dart';
import '../widgets/player_status_bar.dart';
import '../widgets/relay_notice.dart';
import 'career_battle_screen.dart';
import 'editor_screen.dart';

class CareerScreen extends ConsumerStatefulWidget {
  const CareerScreen({super.key});

  @override
  ConsumerState<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends ConsumerState<CareerScreen> {
  String? _claimingId;
  String? _runAction;

  bool get _runBusy => _runAction != null;

  @override
  Widget build(BuildContext context) {
    final progression = ref.watch(progressionProvider);
    final run = ref.watch(careerRunProvider);
    final catalogs = ref.watch(catalogsProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'KARİYER',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        actions: const [
          Center(child: PlayerStatusBar(compact: true)),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: progression.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CareerError(
            message: error.toString(),
            onRetry: _refreshAll,
          ),
          data: (snapshot) => run.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _CareerError(
              message: error.toString(),
              onRetry: _refreshAll,
            ),
            data: (careerRun) => catalogs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _CareerError(
                message: error.toString(),
                onRetry: _refreshAll,
              ),
              data: (catalog) => RefreshIndicator(
                onRefresh: _refreshAll,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _ProgressCard(profile: snapshot.profile),
                    const SizedBox(height: 12),
                    _CareerRunCard(
                      run: careerRun,
                      modules: catalog.modules,
                      availableCredits: snapshot.profile.credits,
                      busyAction: _runAction,
                      onStart: _startRun,
                      onEditBoard: _openCareerEditor,
                      onBattle: () => _battle(catalog.modules),
                      onChooseBooster: _chooseBooster,
                      onSkipBooster: () => _chooseBooster('none'),
                      onAbandon: _confirmAbandon,
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'GÜNLÜK GÖREVLER',
                      icon: Icons.today_outlined,
                      trailing: snapshot.dayKey,
                      child: Column(
                        children: [
                          for (final mission in snapshot.dailyMissions)
                            _GoalRow(
                              key: ValueKey('daily-mission-${mission.id}'),
                              title: mission.title,
                              description: mission.description,
                              progress: mission.progress,
                              target: mission.target,
                              progressRatio: mission.progressRatio,
                              rewardXp: mission.rewardXp,
                              rewardCredits: mission.rewardCredits,
                              available: mission.completed && !mission.claimed,
                              claimed: mission.claimed,
                              loading: _claimingId == 'daily:${mission.id}',
                              onClaim: () => _claimDaily(mission.id),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'GÜÇLENDİRİCİ USTALIĞI',
                      icon: Icons.bolt_outlined,
                      child: Column(
                        children: [
                          for (final booster in snapshot.boosters)
                            _BoosterRow(booster: booster),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'BAŞARIMLAR',
                      icon: Icons.workspace_premium_outlined,
                      child: Column(
                        children: [
                          for (final achievement in snapshot.achievements)
                            _GoalRow(
                              key: ValueKey('achievement-${achievement.id}'),
                              title: achievement.title,
                              description: achievement.description,
                              progress: achievement.progress,
                              target: achievement.target,
                              progressRatio: achievement.progressRatio,
                              rewardXp: achievement.rewardXp,
                              rewardCredits: achievement.rewardCredits,
                              available:
                                  achievement.unlocked && !achievement.claimed,
                              claimed: achievement.claimed,
                              loading:
                                  _claimingId == 'achievement:${achievement.id}',
                              onClaim: () => _claimAchievement(achievement.id),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const ValueKey('career-back-button'),
                      onPressed: _runBusy
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('ANA MENÜYE DÖN'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshAll() async {
    ref.invalidate(progressionProvider);
    ref.invalidate(careerRunProvider);
    ref.invalidate(catalogsProvider);
    await Future.wait([
      ref.read(progressionProvider.future),
      ref.read(careerRunProvider.future),
      ref.read(catalogsProvider.future),
    ]);
  }

  Future<void> _startRun() async {
    await _executeRunAction('start', () async {
      await ref.read(relayApiProvider).startCareerRun();
    });
  }

  Future<void> _chooseBooster(String boosterId) async {
    await _executeRunAction('booster:$boosterId', () async {
      await ref.read(relayApiProvider).chooseCareerBooster(boosterId);
    });
  }

  Future<void> _confirmAbandon() async {
    if (_runBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Koşuyu bırak?'),
        content: const Text(
          'Mevcut aşama ve bütün geçici güçlendiriciler sıfırlanacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('KOŞUYU BIRAK'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _executeRunAction('abandon', () async {
      await ref.read(relayApiProvider).abandonCareerRun();
    });
  }

  Future<void> _openCareerEditor() async {
    if (_runBusy) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const EditorScreen(mode: EditorMode.career),
      ),
    );
    ref.invalidate(careerRunProvider);
    await ref.read(careerRunProvider.future);
  }

  Future<void> _battle(List<ModuleSpec> modules) async {
    if (_runBusy) return;
    final runBeforeBattle = ref.read(careerRunProvider).requireValue;
    final stageNumber = runBeforeBattle.opponent?.stageNumber ??
        (runBeforeBattle.stageIndex + 1);
    setState(() => _runAction = 'battle');
    try {
      final api = ref.read(relayApiProvider);
      final outcome = await api.battleCareerRun();
      final replay = await api.fetchReplay(outcome.match.id);
      if (replay.checksum != outcome.match.replayChecksum) {
        throw const RelayApiException(
          'Kariyer replay özeti maç sonucuyla uyuşmuyor.',
        );
      }
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => CareerBattleScreen(
              outcome: outcome,
              replay: replay,
              modules: modules,
              stageNumber: stageNumber,
            ),
          ),
        );
      }
      ref.invalidate(careerRunProvider);
      ref.invalidate(progressionProvider);
      await Future.wait([
        ref.read(careerRunProvider.future),
        ref.read(progressionProvider.future),
      ]);
    } catch (error) {
      _showError('Kariyer savaşı başlatılamadı: $error');
    } finally {
      if (mounted) setState(() => _runAction = null);
    }
  }

  Future<void> _executeRunAction(
    String action,
    Future<void> Function() callback,
  ) async {
    if (_runBusy) return;
    setState(() => _runAction = action);
    try {
      await callback();
      ref.invalidate(careerRunProvider);
      ref.invalidate(progressionProvider);
      await Future.wait([
        ref.read(careerRunProvider.future),
        ref.read(progressionProvider.future),
      ]);
    } on RelayApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _runAction = null);
    }
  }

  Future<void> _claimDaily(String missionId) async {
    await _claim(
      id: 'daily:$missionId',
      action: () => ref.read(relayApiProvider).claimDailyMission(missionId),
    );
  }

  Future<void> _claimAchievement(String achievementId) async {
    await _claim(
      id: 'achievement:$achievementId',
      action: () =>
          ref.read(relayApiProvider).claimAchievement(achievementId),
    );
  }

  Future<void> _claim({
    required String id,
    required Future<ProgressionReward> Function() action,
  }) async {
    if (_claimingId != null) return;
    setState(() => _claimingId = id);
    try {
      final reward = await action();
      ref.invalidate(progressionProvider);
      await ref.read(progressionProvider.future);
      if (mounted) {
        final levelText = reward.levelUp ? ' • SEVİYE ${reward.levelAfter}!' : '';
        RelayNotice.show(
          context,
          '+${reward.xp} XP • +${reward.credits} Devre Kredisi$levelText',
          tone: RelayNoticeTone.success,
        );
      }
    } catch (error) {
      _showError('Ödül alınamadı: $error');
    } finally {
      if (mounted) setState(() => _claimingId = null);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    RelayNotice.show(context, message, tone: RelayNoticeTone.error);
  }
}

class _CareerRunCard extends StatelessWidget {
  const _CareerRunCard({
    required this.run,
    required this.modules,
    required this.availableCredits,
    required this.busyAction,
    required this.onStart,
    required this.onEditBoard,
    required this.onBattle,
    required this.onChooseBooster,
    required this.onSkipBooster,
    required this.onAbandon,
  });

  final CareerRunSnapshot run;
  final List<ModuleSpec> modules;
  final int availableCredits;
  final String? busyAction;
  final VoidCallback onStart;
  final VoidCallback onEditBoard;
  final VoidCallback onBattle;
  final ValueChanged<String> onChooseBooster;
  final VoidCallback onSkipBooster;
  final VoidCallback onAbandon;

  bool get busy => busyAction != null;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('career-run-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: run.status == 'active'
            ? _active(context)
            : run.status == 'awaiting_booster'
                ? _boosterChoice()
                : run.isTerminal
                    ? _terminal()
                    : _idle(),
      ),
    );
  }

  Widget _idle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _RunTitle(
          icon: Icons.account_tree_outlined,
          color: RelayColors.amber,
          title: 'BEŞ SAVAŞLIK KARİYER KOŞUSU',
          subtitle:
              'Rakip devreyi savaştan önce tam gör ve devreni karşı stratejiye '
              'göre düzenle. Dördüncü zaferden sonra boss öncesi tek bir '
              'güçlendirici satın alabilir veya güçlendiricisiz ilerleyebilirsin.',
        ),
        const SizedBox(height: 14),
        if (run.boardRequired)
          const Text(
            'Koşuya başlamadan önce geçerli devrenizi kaydetmeniz gerekiyor.',
            style: TextStyle(color: RelayColors.muted),
          ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const ValueKey('career-run-start'),
          onPressed: busy ? null : (run.boardRequired ? onEditBoard : onStart),
          icon: busyAction == 'start'
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(run.boardRequired ? Icons.memory : Icons.route),
          label: Text(
            run.boardRequired ? 'DEVREYİ HAZIRLA' : 'KOŞUYU BAŞLAT',
          ),
        ),
      ],
    );
  }

  Widget _active(BuildContext context) {
    final opponent = run.opponent;
    if (opponent == null) return _idle();
    final specs = {for (final item in modules) item.kind: item};
    final placements = {
      for (final item in opponent.board.modules) item.cellIndex: item,
    };
    final powered = opponent.board.modules.map((item) => item.id).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RunTitle(
          icon: opponent.isBoss ? Icons.warning_amber : Icons.radar,
          color: opponent.isBoss ? RelayColors.coral : RelayColors.cyan,
          title: opponent.isBoss
              ? 'BÖLÜM SONU • ${opponent.title}'
              : 'SAVAŞ ${opponent.stageNumber}/${opponent.totalStages} • ${opponent.title}',
          subtitle: opponent.briefing,
        ),
        const SizedBox(height: 12),
        _RunProgress(run: run),
        if (run.selectedBoosters.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SelectedBoosters(items: run.selectedBoosters),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x1119D3AE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x5538E8FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility, color: RelayColors.cyan),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${opponent.displayName} • TAM DEVRE ÖN İZLEMESİ',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                opponent.description,
                style: const TextStyle(
                  color: RelayColors.muted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: IgnorePointer(
                    child: CircuitBoard(
                      placements: placements,
                      specs: specs,
                      poweredIds: powered,
                      validationVisible: false,
                      selectedCell: null,
                      onCellTap: (_) {},
                      onModuleDropped: (_, _) {},
                      onRotateModule: (_) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final module in opponent.board.modules)
                    Chip(
                      label: Text(
                        specs[module.kind]?.displayName ??
                            module.kind.displayName,
                      ),
                      avatar: const Icon(Icons.memory, size: 16),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('career-edit-board'),
                onPressed: busy ? null : onEditBoard,
                icon: const Icon(Icons.tune),
                label: const Text('DEVREMİ DÜZENLE'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('career-battle-button'),
                onPressed: busy || !run.canBattle ? null : onBattle,
                icon: busyAction == 'battle'
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flash_on),
                label: Text(
                  opponent.isBoss
                      ? 'BOSS SAVAŞINA İLERLE'
                      : opponent.stageNumber == 1
                          ? 'İLK SAVAŞA BAŞLA'
                          : 'SONRAKİ SAVAŞA İLERLE',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        TextButton.icon(
          onPressed: busy ? null : onAbandon,
          icon: const Icon(Icons.close),
          label: const Text('KOŞUYU BIRAK'),
        ),
      ],
    );
  }

  Widget _boosterChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _RunTitle(
          icon: Icons.bolt,
          color: RelayColors.amber,
          title: 'BOSS ÖNCESİ GÜÇLENDİRİCİ MAĞAZASI',
          subtitle: 'Yalnız bu koşunun boss savaşında çalışacak tek bir '
              'güçlendirici satın alabilir veya satın almadan ilerleyebilirsin.',
        ),
        const SizedBox(height: 12),
        _RunProgress(run: run),
        const SizedBox(height: 10),
        Text(
          'Mevcut bakiye: $availableCredits Devre Kredisi',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: RelayColors.amber,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (run.selectedBoosters.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SelectedBoosters(items: run.selectedBoosters),
        ],
        const SizedBox(height: 12),
        for (final booster in run.offeredBoosters)
          Container(
            key: ValueKey('career-offer-${booster.id}'),
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1538E8FF),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0x5538E8FF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: RelayColors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${booster.displayName} • K${booster.tier}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        booster.effectLabel,
                        style: const TextStyle(
                          color: RelayColors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        booster.description,
                        style: const TextStyle(
                          color: RelayColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: busy || availableCredits < booster.creditCost
                      ? null
                      : () => onChooseBooster(booster.id),
                  child: busyAction == 'booster:${booster.id}'
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('${booster.creditCost} DK'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          key: const ValueKey('career-booster-skip'),
          onPressed: busy ? null : onSkipBooster,
          icon: busyAction == 'booster:none'
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward),
          label: const Text('GÜÇLENDİRİCİ ALMADAN BOSS’A İLERLE'),
        ),
      ],
    );
  }

  Widget _terminal() {
    final completed = run.status == 'completed';
    final failed = run.status == 'failed';
    final reward = run.reward;
    final title = completed
        ? 'KARİYER KOŞUSU TAMAMLANDI'
        : failed
            ? 'KARİYER KOŞUSU SONA ERDİ'
            : 'KARİYER KOŞUSU BIRAKILDI';
    final subtitle = completed
        ? 'Bölüm sonu devresi yenildi. Bütün geçici etkiler sıfırlandı.'
        : 'Geçici etkiler sıfırlandı. Yeni koşu temiz bir devreyle başlar.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RunTitle(
          icon: completed ? Icons.emoji_events : Icons.route_outlined,
          color: completed ? RelayColors.mint : RelayColors.coral,
          title: title,
          subtitle: subtitle,
        ),
        const SizedBox(height: 14),
        Text(
          '${run.wins}/${run.totalStages} ZAFER',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: RelayColors.cyan,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (reward != null) ...[
          const SizedBox(height: 8),
          Text(
            '+${reward.xp} XP • +${reward.credits} Devre Kredisi',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RelayColors.amber,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const ValueKey('career-new-run'),
          onPressed: busy ? null : onStart,
          icon: busyAction == 'start'
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: const Text('YENİ KOŞU BAŞLAT'),
        ),
      ],
    );
  }
}

class _RunTitle extends StatelessWidget {
  const _RunTitle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: RelayColors.muted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RunProgress extends StatelessWidget {
  const _RunProgress({required this.run});

  final CareerRunSnapshot run;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'KOŞU İLERLEMESİ • ${run.wins}/${run.totalStages} ZAFER',
                style: const TextStyle(
                  color: RelayColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: run.wins / run.totalStages,
          minHeight: 7,
          borderRadius: BorderRadius.circular(20),
        ),
      ],
    );
  }
}

class _SelectedBoosters extends StatelessWidget {
  const _SelectedBoosters({required this.items});

  final List<CareerBoosterChoice> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final booster in items)
          Chip(
            avatar: const Icon(Icons.bolt, size: 16),
            label: Text('${booster.displayName} K${booster.tier}'),
          ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.profile});

  final PlayerProgression profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('career-progress-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route_outlined, color: RelayColors.cyan, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OYUNCU SEVİYESİ',
                        style: TextStyle(
                          color: RelayColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'SEVİYE ${profile.level}',
                        style: const TextStyle(
                          color: RelayColors.cyan,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                _Metric(value: '${profile.credits}', label: 'DEVRE KREDİSİ'),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              key: const ValueKey('career-level-progress'),
              value: profile.levelProgress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 7),
            Text(
              '${profile.xpIntoLevel} / ${profile.xpForNextLevel} XP • '
              'Toplam ${profile.totalXp} XP',
              style: const TextStyle(
                color: RelayColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: RelayColors.cyan),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: const TextStyle(
                      color: RelayColors.muted,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.progressRatio,
    required this.rewardXp,
    required this.rewardCredits,
    required this.available,
    required this.claimed,
    required this.loading,
    required this.onClaim,
    super.key,
  });

  final String title;
  final String description;
  final int progress;
  final int target;
  final double progressRatio;
  final int rewardXp;
  final int rewardCredits;
  final bool available;
  final bool claimed;
  final bool loading;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '$progress / $target',
                style: const TextStyle(
                  color: RelayColors.cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            description,
            style: const TextStyle(color: RelayColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progressRatio, minHeight: 5),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '+$rewardXp XP • +$rewardCredits Devre Kredisi',
                  style: const TextStyle(
                    color: RelayColors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (claimed)
                const Text(
                  'ALINDI',
                  style: TextStyle(
                    color: RelayColors.mint,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                )
              else
                FilledButton(
                  onPressed: available && !loading ? onClaim : null,
                  child: loading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ÖDÜLÜ AL'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoosterRow extends StatelessWidget {
  const _BoosterRow({required this.booster});

  final BoosterMastery booster;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('booster-${booster.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1538E8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x5538E8FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: RelayColors.cyan),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booster.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  booster.effectLabel,
                  style: const TextStyle(
                    color: RelayColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  booster.description,
                  style: const TextStyle(
                    color: RelayColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'K${booster.tier}',
            style: const TextStyle(
              color: RelayColors.cyan,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: RelayColors.amber,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: RelayColors.muted,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CareerError extends StatelessWidget {
  const _CareerError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: RelayColors.coral, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => onRetry(),
              child: const Text('YENİDEN DENE'),
            ),
          ],
        ),
      ),
    );
  }
}
