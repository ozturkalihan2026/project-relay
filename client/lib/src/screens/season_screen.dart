import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import '../widgets/player_status_bar.dart';
import '../widgets/relay_notice.dart';

class SeasonScreen extends ConsumerStatefulWidget {
  const SeasonScreen({super.key});

  @override
  ConsumerState<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends ConsumerState<SeasonScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  String _feedbackCategory = 'denge';
  bool _busy = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final season = ref.watch(seasonProvider);
    final safety = ref.watch(alphaSafetyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SEZON VE KAPALI ALFA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'PROJECT RELAY • v0.8.0',
              style: TextStyle(color: RelayColors.muted, fontSize: 10),
            ),
          ],
        ),
        actions: const [
          Center(child: PlayerStatusBar(compact: true)),
          SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(seasonProvider);
            ref.invalidate(alphaSafetyProvider);
            await Future.wait([
              ref.read(seasonProvider.future),
              ref.read(alphaSafetyProvider.future),
            ]);
          },
          child: ListView(
            key: const ValueKey('season-scroll-view'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            children: [
              season.when(
                data: _seasonContent,
                loading: () => const _LoadingCard(
                  title: 'Sezon verisi yükleniyor',
                ),
                error: (error, _) => _ErrorCard(
                  title: 'Sezon verisi alınamadı',
                  message: error.toString(),
                  onRetry: () => ref.invalidate(seasonProvider),
                ),
              ),
              const SizedBox(height: 14),
              safety.when(
                data: _alphaContent,
                loading: () => const _LoadingCard(
                  title: 'Alfa güvenlik durumu yükleniyor',
                ),
                error: (error, _) => _ErrorCard(
                  title: 'Alfa güvenlik durumu alınamadı',
                  message: error.toString(),
                  onRetry: () => ref.invalidate(alphaSafetyProvider),
                ),
              ),
              const SizedBox(height: 14),
              _feedbackCard(),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                key: const ValueKey('season-menu-back'),
                onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
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
                    child: Icon(
                      Icons.auto_awesome,
                      color: RelayColors.cyan,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.season.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$daysLeft gün kaldı • Gerçek oyuncu savaşları sezon puanı verir',
                        style: const TextStyle(
                          color: RelayColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${snapshot.entry.points}',
                      style: const TextStyle(
                        color: RelayColors.cyan,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'SEZON PUANI',
                      style: TextStyle(
                        color: RelayColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _sectionTitle(Icons.flag_outlined, 'SEZON KADEMELERİ'),
        const SizedBox(height: 8),
        for (final tier in snapshot.tiers) ...[
          _SeasonTierCard(
            tier: tier,
            points: snapshot.entry.points,
            busy: _busy,
            onClaim: () => _claimTier(tier),
          ),
          const SizedBox(height: 8),
        ],
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
                          backgroundColor: item.isCurrentPlayer
                              ? RelayColors.cyan.withValues(alpha: 0.18)
                              : const Color(0xFF183440),
                          child: Text(
                            '${item.position}',
                            style: TextStyle(
                              color: item.isCurrentPlayer
                                  ? RelayColors.cyan
                                  : RelayColors.muted,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        title: Text(
                          item.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: item.isCurrentPlayer
                                ? RelayColors.cyan
                                : Colors.white,
                          ),
                        ),
                        subtitle: Text('${item.wins} galibiyet • ${item.matches} maç'),
                        trailing: Text(
                          '${item.points} SP',
                          style: const TextStyle(
                            color: RelayColors.amber,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _alphaContent(AlphaSafetySnapshotModel safety) {
    final blocked = safety.blockedUntil != null &&
        safety.blockedUntil!.isAfter(DateTime.now().toUtc());
    return Card(
      key: const ValueKey('alpha-safety-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.shield_outlined, 'KAPALI ALFA KORUMALARI'),
            const SizedBox(height: 12),
            _SafetyRow(
              icon: Icons.gavel_outlined,
              title: 'Sunucu yetkili sonuç',
              subtitle: 'Kazananı ve ödülü yalnız sunucu belirler.',
              active: safety.serverAuthoritativeResults,
            ),
            _SafetyRow(
              icon: Icons.verified_outlined,
              title: 'Tek seferlik ödül',
              subtitle: 'Aynı maç veya sezon ödülü ikinci kez verilemez.',
              active: safety.idempotentRewards,
            ),
            _SafetyRow(
              icon: Icons.schema_outlined,
              title: 'Devre doğrulaması',
              subtitle: 'Kit, modül sayısı, bağlantı ve enerji kuralları sunucuda denetlenir.',
              active: safety.boardValidation,
            ),
            const Divider(height: 24),
            Text(
              'Savaş isteği: ${safety.matchRequests}/${safety.matchLimit} '
              '(${safety.matchWindowSeconds} sn pencere)',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              'Geri bildirim: ${safety.feedbackRequests}/${safety.feedbackLimit} '
              '(${safety.feedbackWindowSeconds ~/ 60} dk pencere)',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (blocked) ...[
              const SizedBox(height: 10),
              const Text(
                'Çok hızlı istek nedeniyle savaş isteği geçici olarak sınırlandı.',
                style: TextStyle(
                  color: RelayColors.coral,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _feedbackCard() {
    return Card(
      key: const ValueKey('alpha-feedback-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(Icons.forum_outlined, 'ALFA GERİ BİLDİRİMİ'),
            const SizedBox(height: 8),
            const Text(
              'Denge, hata ve arayüz gözlemlerini doğrudan sunucuya kaydet. Kişisel bilgi yazma.',
              style: TextStyle(color: RelayColors.muted),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('alpha-feedback-category'),
              initialValue: _feedbackCategory,
              items: const [
                DropdownMenuItem(value: 'denge', child: Text('Denge')),
                DropdownMenuItem(value: 'hata', child: Text('Hata')),
                DropdownMenuItem(value: 'arayuz', child: Text('Arayüz')),
                DropdownMenuItem(value: 'diger', child: Text('Diğer')),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _feedbackCategory = value);
                      }
                    },
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('alpha-feedback-message'),
              controller: _feedbackController,
              minLines: 3,
              maxLines: 6,
              maxLength: 1200,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Geri bildirim',
                hintText: 'Ne oldu, hangi ekranda oldu ve beklediğin davranış neydi?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const ValueKey('alpha-feedback-submit'),
              onPressed: _busy ? null : _submitFeedback,
              icon: const Icon(Icons.send_outlined),
              label: const Text('GERİ BİLDİRİMİ GÖNDER'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: RelayColors.cyan, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }

  Future<void> _claimTier(SeasonTierModel tier) async {
    if (_busy || !tier.unlocked || tier.claimed) return;
    setState(() => _busy = true);
    try {
      final reward = await ref.read(relayApiProvider).claimSeasonTier(tier.tier);
      if (!mounted) return;
      ref.invalidate(seasonProvider);
      ref.invalidate(progressionProvider);
      ref.invalidate(collectionProvider);
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
        RelayNotice.show(
          context,
          '${tier.title} ödülü alındı: +${reward.xp} XP • +${reward.credits} Devre Kredisi',
          tone: RelayNoticeTone.success,
        );
      }
    } on RelayApiException catch (error) {
      if (!mounted) return;
      RelayNotice.show(context, error.message, tone: RelayNoticeTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitFeedback() async {
    final message = _feedbackController.text.trim();
    if (message.length < 3) {
      RelayNotice.show(
        context,
        'Geri bildirim en az üç karakter olmalıdır.',
        tone: RelayNoticeTone.warning,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final receipt = await ref.read(relayApiProvider).submitAlphaFeedback(
            category: _feedbackCategory,
            message: message,
          );
      if (!mounted) return;
      _feedbackController.clear();
      ref.invalidate(alphaSafetyProvider);
      RelayNotice.show(
        context,
        'Geri bildirim kaydedildi. Kayıt: ${receipt.feedbackId.substring(0, 8)}',
        tone: RelayNoticeTone.success,
      );
    } on RelayApiException catch (error) {
      if (!mounted) return;
      RelayNotice.show(context, error.message, tone: RelayNoticeTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _SeasonTierCard extends StatelessWidget {
  const _SeasonTierCard({
    required this.tier,
    required this.points,
    required this.busy,
    required this.onClaim,
  });

  final SeasonTierModel tier;
  final int points;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final progress = tier.requiredPoints == 0
        ? 1.0
        : (points / tier.requiredPoints).clamp(0.0, 1.0).toDouble();
    return Card(
      key: ValueKey('season-tier-${tier.tier}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: tier.unlocked
                      ? RelayColors.amber.withValues(alpha: 0.18)
                      : const Color(0xFF17313B),
                  child: Text(
                    '${tier.tier}',
                    style: TextStyle(
                      color: tier.unlocked ? RelayColors.amber : RelayColors.muted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${tier.requiredPoints} sezon puanı • +${tier.rewardXp} XP • +${tier.rewardCredits} Devre Kredisi',
                        style: const TextStyle(
                          color: RelayColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 122,
                  child: FilledButton(
                    onPressed: busy || !tier.unlocked || tier.claimed
                        ? null
                        : onClaim,
                    child: Text(tier.claimed ? 'ALINDI' : 'ÖDÜLÜ AL'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 5),
            Text(
              '${points.clamp(0, tier.requiredPoints)} / ${tier.requiredPoints}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: RelayColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: active ? RelayColors.mint : RelayColors.coral),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(subtitle, style: const TextStyle(color: RelayColors.muted)),
              ],
            ),
          ),
          Icon(
            active ? Icons.check_circle : Icons.cancel,
            color: active ? RelayColors.mint : RelayColors.coral,
          ),
        ],
      ),
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
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
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
            Text(
              title,
              style: const TextStyle(
                color: RelayColors.coral,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: RelayColors.muted)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('YENİDEN DENE'),
            ),
          ],
        ),
      ),
    );
  }
}
