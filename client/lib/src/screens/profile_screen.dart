import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/relay_notice.dart';
import 'replay_screen.dart';
import 'season_screen.dart';
import 'social_screen.dart';

enum ProfileSection {
  general,
  friends,
  ratingSeason,
  matchHistory,
  dailyMissions,
  achievements,
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    this.initialSection = ProfileSection.general,
    super.key,
  });

  final ProfileSection initialSection;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late ProfileSection _section;
  String? _claimingId;
  String? _loadingMatchId;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
  }

  @override
  Widget build(BuildContext context) {
    final progression = ref.watch(progressionProvider);
    final claimableDaily = progression.asData?.value.dailyMissions.any(
          (mission) => mission.completed && !mission.claimed,
        ) ??
        false;
    final claimableAchievements = progression.asData?.value.achievements.any(
          (achievement) => achievement.unlocked && !achievement.claimed,
        ) ??
        false;
    final social = ref.watch(socialProvider);
    final incomingFriendRequests =
        social.asData?.value.incomingRequests.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROFİL',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            Text(
              'PROJECT RELAY • v0.8.4',
              style: TextStyle(color: RelayColors.muted, fontSize: 10),
            ),
          ],
        ),
        actions: const [
          AppHeaderActions(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            key: const ValueKey('profile-scroll-view'),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              _sectionSelector(
                claimableDaily: claimableDaily,
                claimableAchievements: claimableAchievements,
                incomingFriendRequests: incomingFriendRequests,
              ),
              const SizedBox(height: 14),
              switch (_section) {
                ProfileSection.general => const SocialScreen(
                    embeddedProfileOnly: true,
                  ),
                ProfileSection.friends => const SocialScreen(
                    embeddedFriendsOnly: true,
                  ),
                ProfileSection.ratingSeason => _ratingAndSeasonSection(),
                ProfileSection.matchHistory => _matchHistorySection(),
                ProfileSection.dailyMissions => _dailyMissionsSection(),
                ProfileSection.achievements => _achievementsSection(),
              },
              const SizedBox(height: 18),
              OutlinedButton.icon(
                key: const ValueKey('profile-menu-back'),
                onPressed: _claimingId == null && _loadingMatchId == null
                    ? () => Navigator.of(context).maybePop()
                    : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('ANA MENÜYE DÖN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionSelector({
    required bool claimableDaily,
    required bool claimableAchievements,
    required int incomingFriendRequests,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<ProfileSection>(
        key: const ValueKey('profile-section-selector'),
        showSelectedIcon: false,
        segments: [
          const ButtonSegment(
            value: ProfileSection.general,
            icon: Icon(Icons.account_circle_outlined),
            label: Text('GENEL', key: ValueKey('profile-section-general')),
          ),
          ButtonSegment(
            value: ProfileSection.friends,
            icon: _SectionIcon(
              icon: Icons.people_alt_outlined,
              notify: incomingFriendRequests > 0,
            ),
            label: Text(
              incomingFriendRequests > 0
                  ? 'ARKADAŞLAR ($incomingFriendRequests)'
                  : 'ARKADAŞLAR',
              key: const ValueKey('profile-section-friends'),
            ),
          ),
          const ButtonSegment(
            value: ProfileSection.ratingSeason,
            icon: Icon(Icons.military_tech_outlined),
            label: Text(
              'DERECE VE SEZON',
              key: ValueKey('profile-section-rating-season'),
            ),
          ),
          const ButtonSegment(
            value: ProfileSection.matchHistory,
            icon: Icon(Icons.history),
            label: Text(
              'MAÇ GEÇMİŞİ',
              key: ValueKey('profile-section-match-history'),
            ),
          ),
          ButtonSegment(
            value: ProfileSection.dailyMissions,
            icon: _SectionIcon(
              icon: Icons.today_outlined,
              notify: claimableDaily,
            ),
            label: const Text(
              'GÜNLÜK GÖREVLER',
              key: ValueKey('profile-section-daily-missions'),
            ),
          ),
          ButtonSegment(
            value: ProfileSection.achievements,
            icon: _SectionIcon(
              icon: Icons.workspace_premium_outlined,
              notify: claimableAchievements,
            ),
            label: const Text(
              'BAŞARIMLAR',
              key: ValueKey('profile-section-achievements'),
            ),
          ),
        ],
        selected: {_section},
        onSelectionChanged: (selection) {
          setState(() => _section = selection.first);
        },
      ),
    );
  }

  Widget _ratingAndSeasonSection() {
    final statistics = ref.watch(statisticsProvider);
    final season = ref.watch(seasonProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        statistics.when(
          data: (snapshot) => Column(
            children: [
              Card(
                key: const ValueKey('profile-rating-card'),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _CardTitle(
                        icon: Icons.military_tech_outlined,
                        title: 'DERECE',
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _MetricBox(
                            value: '${snapshot.profile.rating}',
                            label: 'DERECE',
                          ),
                          _MetricBox(
                            value: '${snapshot.profile.peakRating}',
                            label: 'ZİRVE',
                          ),
                          _MetricBox(
                            value: '${snapshot.profile.ratedMatches}',
                            label: 'MAÇ',
                          ),
                          _MetricBox(
                            value:
                                '${(snapshot.profile.winRate * 100).round()}%',
                            label: 'KAZANMA',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                key: const ValueKey('profile-weekly-league-card'),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _CardTitle(
                        icon: Icons.calendar_view_week,
                        title: 'HAFTALIK LİG',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _MetricBox(
                            value: '${snapshot.league.points}',
                            label: 'PUAN',
                          ),
                          _MetricBox(
                            value: snapshot.league.position == 0
                                ? '—'
                                : '#${snapshot.league.position}',
                            label: 'SIRA',
                          ),
                          _MetricBox(
                            value: '${snapshot.league.participantCount}',
                            label: 'OYUNCU',
                          ),
                        ],
                      ),
                      if (snapshot.leaderboard.isNotEmpty) ...[
                        const Divider(height: 26),
                        for (final standing
                            in snapshot.leaderboard.take(5))
                          ListTile(
                            dense: true,
                            leading: Text(
                              '#${standing.position}',
                              style: const TextStyle(
                                color: RelayColors.amber,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            title: Text(standing.displayName),
                            trailing: Text(
                              '${standing.points} puan',
                              style: const TextStyle(
                                color: RelayColors.cyan,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          loading: () => const _LoadingCard('Derece bilgileri yükleniyor.'),
          error: (error, _) => _ErrorCard(
            message: error.toString(),
            onRetry: () => ref.invalidate(statisticsProvider),
          ),
        ),
        const SizedBox(height: 12),
        season.when(
          data: (snapshot) {
            final availableRewards = snapshot.tiers
                .where((tier) => tier.unlocked && !tier.claimed)
                .length;
            return Card(
              key: const ValueKey('profile-season-card'),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _CardTitle(
                      icon: Icons.auto_awesome,
                      title: 'SEZON',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      snapshot.season.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetricBox(
                          value: '${snapshot.entry.points}',
                          label: 'SEZON PUANI',
                        ),
                        _MetricBox(
                          value: snapshot.entry.position == 0
                              ? '—'
                              : '#${snapshot.entry.position}',
                          label: 'SIRA',
                        ),
                        _MetricBox(
                          value: '$availableRewards',
                          label: 'ALINABİLİR ÖDÜL',
                          accent: availableRewards > 0
                              ? RelayColors.amber
                              : RelayColors.cyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton.tonalIcon(
                      key: const ValueKey('profile-open-season'),
                      onPressed: _openSeason,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('SEZON YOLU VE ALFA GERİ BİLDİRİMİ'),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const _LoadingCard('Sezon bilgileri yükleniyor.'),
          error: (error, _) => _ErrorCard(
            message: error.toString(),
            onRetry: () => ref.invalidate(seasonProvider),
          ),
        ),
      ],
    );
  }

  Widget _matchHistorySection() {
    final statistics = ref.watch(statisticsProvider);
    return statistics.when(
      data: (snapshot) => Card(
        key: const ValueKey('profile-match-history-card'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CardTitle(icon: Icons.history, title: 'MAÇ GEÇMİŞİ'),
              const SizedBox(height: 10),
              if (snapshot.recentMatches.isEmpty)
                const _EmptyState(
                  icon: Icons.sports_esports_outlined,
                  message:
                      'Maç geçmişi ilk çevrimiçi savaşından sonra burada görünür.',
                )
              else
                for (final match in snapshot.recentMatches)
                  Card(
                    color: RelayColors.surface.withValues(alpha: 0.66),
                    child: ListTile(
                      leading: Icon(
                        _outcomeIcon(match.outcome),
                        color: _outcomeColor(match.outcome),
                      ),
                      title: Text(
                        match.opponentName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${_outcomeLabel(match.outcome)} • '
                        '${_formatDate(match.createdAt)}\n${match.reason}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Tekrarı aç',
                        onPressed: _loadingMatchId == null
                            ? () => _openReplay(match.matchId)
                            : null,
                        icon: _loadingMatchId == match.matchId
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.play_circle_outline),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
      loading: () => const _LoadingCard('Maç geçmişi yükleniyor.'),
      error: (error, _) => _ErrorCard(
        message: error.toString(),
        onRetry: () => ref.invalidate(statisticsProvider),
      ),
    );
  }

  Widget _dailyMissionsSection() {
    final progression = ref.watch(progressionProvider);
    return progression.when(
      data: (snapshot) => _GoalSection(
        key: const ValueKey('profile-daily-missions-card'),
        icon: Icons.today_outlined,
        title: 'GÜNLÜK GÖREVLER',
        emptyMessage: 'Bugün için görev bulunmuyor.',
        children: [
          for (final mission in snapshot.dailyMissions)
            _RewardGoalCard(
              key: ValueKey('profile-daily-${mission.id}'),
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
      loading: () => const _LoadingCard('Günlük görevler yükleniyor.'),
      error: (error, _) => _ErrorCard(
        message: error.toString(),
        onRetry: () => ref.invalidate(progressionProvider),
      ),
    );
  }

  Widget _achievementsSection() {
    final progression = ref.watch(progressionProvider);
    return progression.when(
      data: (snapshot) => _GoalSection(
        key: const ValueKey('profile-achievements-card'),
        icon: Icons.workspace_premium_outlined,
        title: 'BAŞARIMLAR',
        emptyMessage: 'Henüz başarım bulunmuyor.',
        children: [
          for (final achievement in snapshot.achievements)
            _RewardGoalCard(
              key: ValueKey('profile-achievement-${achievement.id}'),
              title: achievement.title,
              description: achievement.description,
              progress: achievement.progress,
              target: achievement.target,
              progressRatio: achievement.progressRatio,
              rewardXp: achievement.rewardXp,
              rewardCredits: achievement.rewardCredits,
              available: achievement.unlocked && !achievement.claimed,
              claimed: achievement.claimed,
              loading: _claimingId == 'achievement:${achievement.id}',
              onClaim: () => _claimAchievement(achievement.id),
            ),
        ],
      ),
      loading: () => const _LoadingCard('Başarımlar yükleniyor.'),
      error: (error, _) => _ErrorCard(
        message: error.toString(),
        onRetry: () => ref.invalidate(progressionProvider),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(guestSessionProvider);
    ref.invalidate(progressionProvider);
    ref.invalidate(statisticsProvider);
    ref.invalidate(seasonProvider);
    ref.invalidate(socialProvider);
    ref.invalidate(collectionProvider);
    await Future.wait([
      ref.read(guestSessionProvider.future),
      ref.read(progressionProvider.future),
      ref.read(statisticsProvider.future),
      ref.read(seasonProvider.future),
      ref.read(socialProvider.future),
      ref.read(collectionProvider.future),
    ]);
  }

  Future<void> _claimDaily(String missionId) async {
    await _claimReward(
      id: 'daily:$missionId',
      action: () => ref.read(relayApiProvider).claimDailyMission(missionId),
    );
  }

  Future<void> _claimAchievement(String achievementId) async {
    await _claimReward(
      id: 'achievement:$achievementId',
      action: () =>
          ref.read(relayApiProvider).claimAchievement(achievementId),
    );
  }

  Future<void> _claimReward({
    required String id,
    required Future<ProgressionReward> Function() action,
  }) async {
    if (_claimingId != null) return;
    setState(() => _claimingId = id);
    try {
      final reward = await action();
      ref.invalidate(progressionProvider);
      ref.invalidate(collectionProvider);
      if (!mounted) return;
      RelayNotice.show(
        context,
        '+${reward.xp} XP • +${reward.credits} Devre Kredisi alındı.',
        tone: RelayNoticeTone.success,
      );
    } on RelayApiException catch (error) {
      if (mounted) {
        RelayNotice.show(
          context,
          error.message,
          tone: RelayNoticeTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _claimingId = null);
    }
  }

  Future<void> _openReplay(String matchId) async {
    if (_loadingMatchId != null) return;
    setState(() => _loadingMatchId = matchId);
    try {
      final api = ref.read(relayApiProvider);
      final results = await Future.wait<Object>([
        api.fetchMatch(matchId),
        api.fetchReplay(matchId),
        ref.read(catalogsProvider.future),
      ]);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ReplayScreen(
            match: results[0] as MatchResponse,
            replay: results[1] as ReplayResponse,
            modules: (results[2] as CatalogBundle).modules,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        RelayNotice.show(
          context,
          'Tekrar açılamadı: $error',
          tone: RelayNoticeTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMatchId = null);
    }
  }

  void _openSeason() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const SeasonScreen()),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year}';
  }

  String _outcomeLabel(String outcome) => switch (outcome) {
        'win' => 'ZAFER',
        'loss' => 'MAĞLUBİYET',
        _ => 'BERABERLİK',
      };

  IconData _outcomeIcon(String outcome) => switch (outcome) {
        'win' => Icons.emoji_events_outlined,
        'loss' => Icons.close,
        _ => Icons.balance_outlined,
      };

  Color _outcomeColor(String outcome) => switch (outcome) {
        'win' => RelayColors.mint,
        'loss' => RelayColors.coral,
        _ => RelayColors.amber,
      };
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon, required this.notify});

  final IconData icon;
  final bool notify;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (notify)
          const Positioned(
            right: -3,
            top: -3,
            child: _NotificationDot(),
          ),
      ],
    );
  }
}

class _NotificationDot extends StatelessWidget {
  const _NotificationDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: RelayColors.coral,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: RelayColors.surface, width: 1.5),
        ),
      ),
      child: const SizedBox(width: 9, height: 9),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: RelayColors.cyan),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.value,
    required this.label,
    this.accent = RelayColors.cyan,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: RelayColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalSection extends StatelessWidget {
  const _GoalSection({
    required this.icon,
    required this.title,
    required this.emptyMessage,
    required this.children,
    super.key,
  });

  final IconData icon;
  final String title;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardTitle(icon: icon, title: title),
            const SizedBox(height: 12),
            if (children.isEmpty)
              _EmptyState(icon: icon, message: emptyMessage)
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

class _RewardGoalCard extends StatelessWidget {
  const _RewardGoalCard({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RelayColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: available
              ? RelayColors.amber.withValues(alpha: 0.65)
              : const Color(0xFF2B5969),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (claimed)
                const Chip(label: Text('ALINDI'))
              else if (available)
                FilledButton.tonal(
                  onPressed: loading ? null : onClaim,
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ÖDÜLÜ AL'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: RelayColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progressRatio,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$progress/$target',
                style: const TextStyle(
                  color: RelayColors.cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '+$rewardXp XP • +$rewardCredits Kredi',
                style: const TextStyle(
                  color: RelayColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.error_outline, color: RelayColors.coral),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('TEKRAR DENE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Icon(icon, color: RelayColors.muted, size: 34),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: RelayColors.muted),
          ),
        ],
      ),
    );
  }
}
