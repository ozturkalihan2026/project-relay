import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/navigation_actions.dart';
import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import '../widgets/app_header_actions.dart';

enum _StatisticsSection { season, weeklyLeague }

class SeasonScreen extends ConsumerStatefulWidget {
  const SeasonScreen({super.key});

  @override
  ConsumerState<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends ConsumerState<SeasonScreen> {
  _StatisticsSection _section = _StatisticsSection.season;

  @override
  Widget build(BuildContext context) {
    final season = ref.watch(seasonProvider);
    final statistics = ref.watch(statisticsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İSTATİSTİKLER',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'PROJECT RELAY • v0.8.13',
              style: TextStyle(color: RelayColors.muted, fontSize: 10),
            ),
          ],
        ),
        actions: const [AppHeaderActions(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(seasonProvider);
            ref.invalidate(statisticsProvider);
            await Future.wait([
              ref.read(seasonProvider.future),
              ref.read(statisticsProvider.future),
            ]);
          },
          child: ListView(
            key: const ValueKey('season-scroll-view'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_StatisticsSection>(
                  key: const ValueKey('statistics-section-selector'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _StatisticsSection.season,
                      icon: Icon(Icons.auto_awesome),
                      label: Text('SEZON', key: ValueKey('statistics-section-season')),
                    ),
                    ButtonSegment(
                      value: _StatisticsSection.weeklyLeague,
                      icon: Icon(Icons.calendar_view_week),
                      label: Text('HAFTALIK LİG', key: ValueKey('statistics-section-weekly-league')),
                    ),
                  ],
                  selected: {_section},
                  onSelectionChanged: (selection) => setState(() => _section = selection.first),
                ),
              ),
              const SizedBox(height: 14),
              if (_section == _StatisticsSection.season)
                season.when(
                  data: _seasonContent,
                  loading: () => const _LoadingCard(title: 'Sezon verisi yükleniyor'),
                  error: (error, _) => _ErrorCard(
                    title: 'Sezon verisi alınamadı',
                    message: error.toString(),
                    onRetry: () => ref.invalidate(seasonProvider),
                  ),
                )
              else
                statistics.when(
                  data: _weeklyLeagueContent,
                  loading: () => const _LoadingCard(title: 'Haftalık lig yükleniyor'),
                  error: (error, _) => _ErrorCard(
                    title: 'Haftalık lig verisi alınamadı',
                    message: error.toString(),
                    onRetry: () => ref.invalidate(statisticsProvider),
                  ),
                ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                key: const ValueKey('season-menu-back'),
                onPressed: () => returnToMainMenu(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('ANA MENÜYE DÖN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seasonContent(SeasonSnapshotModel snapshot) {
    final now = DateTime.now().toUtc();
    final remaining = snapshot.season.endsAt.toUtc().difference(now);
    final daysLeft = remaining.isNegative ? 0 : remaining.inDays + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          key: const ValueKey('season-summary-card'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x2238E8FF),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(Icons.auto_awesome, color: RelayColors.cyan, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(snapshot.season.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.7)),
                      const SizedBox(height: 5),
                      Text(
                        '$daysLeft gün kaldı • Gerçek oyuncu savaşları sezon puanı verir',
                        style: const TextStyle(color: RelayColors.muted, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${snapshot.entry.points}', style: const TextStyle(color: RelayColors.cyan, fontSize: 30, fontWeight: FontWeight.w900)),
                    const Text('SEZON PUANI', style: TextStyle(color: RelayColors.muted, fontSize: 9, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _sectionTitle(Icons.leaderboard_outlined, 'SEZON SIRALAMASI'),
        const SizedBox(height: 8),
        Card(
          key: const ValueKey('season-leaderboard-card'),
          child: snapshot.leaderboard.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Henüz sezon sıralamasına giren oyuncu yok. İlk gerçek oyuncu savaşını tamamladığında burada görüneceksin.',
                    style: TextStyle(color: RelayColors.muted),
                  ),
                )
              : Column(
                  children: [
                    for (final item in snapshot.leaderboard)
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: item.isCurrentPlayer ? RelayColors.cyan.withValues(alpha: 0.18) : const Color(0xFF183440),
                          child: Text(
                            '${item.position}',
                            style: TextStyle(
                              color: item.isCurrentPlayer ? RelayColors.cyan : RelayColors.muted,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        title: Text(item.displayName, style: TextStyle(fontWeight: FontWeight.w900, color: item.isCurrentPlayer ? RelayColors.cyan : Colors.white)),
                        subtitle: Text('${item.wins} galibiyet • ${item.matches} maç'),
                        trailing: Text('${item.points} SP', style: const TextStyle(color: RelayColors.amber, fontWeight: FontWeight.w900)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _weeklyLeagueContent(CareerSnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          key: const ValueKey('season-summary-card'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _MiniTitle(icon: Icons.calendar_view_week, title: 'HAFTALIK LİG'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricBox(value: '${snapshot.league.points}', label: 'PUAN'),
                    _MetricBox(value: snapshot.league.position == 0 ? '—' : '#${snapshot.league.position}', label: 'SIRA'),
                    _MetricBox(value: '${snapshot.league.participantCount}', label: 'OYUNCU'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _sectionTitle(Icons.emoji_events_outlined, 'LİG LİDER TABLOSU'),
        const SizedBox(height: 8),
        Card(
          key: const ValueKey('season-leaderboard-card'),
          child: snapshot.leaderboard.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Bu hafta için lider tablosu henüz oluşmadı.', style: TextStyle(color: RelayColors.muted)),
                )
              : Column(
                  children: [
                    for (final standing in snapshot.leaderboard)
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: standing.isCurrentPlayer ? RelayColors.cyan.withValues(alpha: 0.18) : const Color(0xFF183440),
                          child: Text('${standing.position}', style: TextStyle(color: standing.isCurrentPlayer ? RelayColors.cyan : RelayColors.muted, fontWeight: FontWeight.w900)),
                        ),
                        title: Text(standing.displayName, style: TextStyle(fontWeight: FontWeight.w900, color: standing.isCurrentPlayer ? RelayColors.cyan : Colors.white)),
                        subtitle: Text(
                          '${standing.wins} galibiyet • '
                          '${standing.wins + standing.draws + standing.losses} maç',
                        ),
                        trailing: Text('${standing.points} puan', style: const TextStyle(color: RelayColors.amber, fontWeight: FontWeight.w900)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: RelayColors.cyan, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.7)),
      ],
    );
  }
}

class _MiniTitle extends StatelessWidget {
  const _MiniTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, color: RelayColors.cyan), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900))]);
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: RelayColors.cyan.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: RelayColors.cyan.withValues(alpha: 0.35),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          value,
          style: const TextStyle(
            color: RelayColors.cyan,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(label, style: const TextStyle(color: RelayColors.muted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
      ]),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(children: [const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 12), Text(title)]),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.title, required this.message, required this.onRetry});

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: const TextStyle(color: RelayColors.coral, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: RelayColors.muted)),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('YENİDEN DENE')),
        ]),
      ),
    );
  }
}
