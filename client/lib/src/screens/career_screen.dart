import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import 'replay_screen.dart';

class CareerScreen extends ConsumerStatefulWidget {
  const CareerScreen({super.key});

  @override
  ConsumerState<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends ConsumerState<CareerScreen> {
  String? _loadingMatchId;

  @override
  Widget build(BuildContext context) {
    final career = ref.watch(careerProvider);
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
      ),
      body: SafeArea(
        child: career.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CareerError(
            message: error.toString(),
            onRetry: () => ref.invalidate(careerProvider),
          ),
          data: (snapshot) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(careerProvider);
              await ref.read(careerProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _RatingCard(snapshot: snapshot),
                const SizedBox(height: 12),
                _LeagueCard(snapshot: snapshot),
                const SizedBox(height: 12),
                _MatchmakingCard(metrics: snapshot.matchmaking),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'HAFTALIK SIRALAMA',
                  icon: Icons.emoji_events_outlined,
                  child: snapshot.leaderboard.isEmpty
                      ? const _EmptyText('Bu hafta henüz sıralama oluşmadı.')
                      : Column(
                          children: [
                            for (final standing in snapshot.leaderboard)
                              _StandingRow(standing: standing),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'SON MAÇLAR',
                  icon: Icons.history,
                  child: snapshot.recentMatches.isEmpty
                      ? const _EmptyText(
                          'Maç geçmişi ilk çevrimiçi savaştan sonra burada '
                          'görünecek.',
                        )
                      : Column(
                          children: [
                            for (final match in snapshot.recentMatches)
                              _HistoryRow(
                                match: match,
                                loading: _loadingMatchId == match.matchId,
                                onReplay: () => _openReplay(match.matchId),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const ValueKey('career-back-button'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('ANA MENÜYE DÖN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openReplay(String matchId) async {
    if (_loadingMatchId != null) {
      return;
    }
    setState(() => _loadingMatchId = matchId);
    try {
      final api = ref.read(relayApiProvider);
      final results = await Future.wait<Object>([
        api.fetchMatch(matchId),
        api.fetchReplay(matchId),
        ref.read(catalogsProvider.future),
      ]);
      if (!mounted) {
        return;
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tekrar açılamadı: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingMatchId = null);
      }
    }
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.snapshot});

  final CareerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final profile = snapshot.profile;
    return Card(
      key: const ValueKey('career-rating-card'),
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
                child: Icon(
                  Icons.military_tech_outlined,
                  color: RelayColors.cyan,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DERECE PUANI',
                    style: TextStyle(
                      color: RelayColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    '${profile.rating}',
                    style: const TextStyle(
                      color: RelayColors.cyan,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Zirve ${profile.peakRating}  •  '
                    '${profile.wins}G ${profile.draws}B ${profile.losses}M',
                    style: const TextStyle(
                      color: RelayColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _Metric(
              value: '${profile.ratedMatches}',
              label: 'MAÇ',
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueCard extends StatelessWidget {
  const _LeagueCard({required this.snapshot});

  final CareerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final league = snapshot.league;
    final position = league.position == 0 ? '—' : '#${league.position}';
    return Card(
      key: const ValueKey('career-weekly-league-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_view_week, color: RelayColors.amber),
                SizedBox(width: 9),
                Text(
                  'HAFTALIK LİG',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Metric(value: '${league.points}', label: 'PUAN'),
                _Metric(value: position, label: 'SIRA'),
                _Metric(
                  value: '${league.participantCount}',
                  label: 'OYUNCU',
                ),
                _Metric(
                  value: '${league.wins}G ${league.draws}B',
                  label: 'HAFTA',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${league.weekKey} • ${_dateLabel(league.endsAt)} tarihinde yenilenir',
              style: const TextStyle(
                color: RelayColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchmakingCard extends StatelessWidget {
  const _MatchmakingCard({required this.metrics});

  final MatchmakingMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final percent = (metrics.humanOpponentRate * 100).round();
    return _SectionCard(
      title: 'RAKİP BULUNURLUĞU',
      icon: Icons.hub_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: metrics.searches == 0 ? 0 : metrics.humanOpponentRate,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 10),
          Text(
            metrics.searches == 0
                ? 'Bu hafta henüz eşleştirme aranmadı.'
                : 'Gerçek oyuncu oranı %$percent • '
                    '${metrics.humanOpponents} oyuncu, '
                    '${metrics.botFallbacks} güvenli bot dönüşü',
            style: const TextStyle(color: RelayColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: RelayColors.cyan, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.standing});

  final LeagueStanding standing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: standing.isCurrentPlayer
            ? const Color(0x2238E8FF)
            : RelayColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: standing.isCurrentPlayer
              ? RelayColors.cyan
              : const Color(0xFF28515F),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#${standing.position}',
              style: const TextStyle(
                color: RelayColors.amber,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              standing.displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: standing.isCurrentPlayer
                    ? FontWeight.w900
                    : FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${standing.points} P  •  ${standing.rating}',
            style: const TextStyle(
              color: RelayColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.match,
    required this.loading,
    required this.onReplay,
  });

  final MatchHistoryItem match;
  final bool loading;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (match.outcome) {
      'win' => ('GALİBİYET', RelayColors.mint),
      'loss' => ('MAĞLUBİYET', RelayColors.coral),
      _ => ('BERABERLİK', RelayColors.amber),
    };
    final delta = match.rated
        ? '${match.ratingDelta >= 0 ? '+' : ''}${match.ratingDelta}'
        : 'DERECESİZ';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: RelayColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.opponentName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '$label • $delta • ${_dateLabel(match.createdAt)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('career-replay-${match.matchId}'),
            onPressed: loading ? null : onReplay,
            tooltip: 'Savaş tekrarını aç',
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_circle_outline),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RelayColors.surfaceHigh,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: RelayColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerError extends StatelessWidget {
  const _CareerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: RelayColors.coral, size: 42),
            const SizedBox(height: 12),
            const Text(
              'KARİYER VERİSİ ALINAMADI',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: RelayColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('YENİDEN DENE'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('career-back-button'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ANA MENÜYE DÖN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: RelayColors.muted, height: 1.4),
    );
  }
}

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
