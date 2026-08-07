import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';
import '../widgets/animated_circuit_background.dart';
import '../widgets/arcade_motion.dart';
import '../widgets/player_status_bar.dart';
import '../widgets/relay_emblem.dart';
import 'collection_screen.dart';
import 'how_to_play_screen.dart';
import 'play_mode_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'season_screen.dart';
import 'social_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedCircuitBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: PlayerStatusBar(
                          onTap: () => _open(context, const ProfileScreen()),
                          showClaimBadge: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircuitCreditButton(
                      onTap: () => _open(
                        context,
                        const CollectionScreen(mode: CollectionScreenMode.store),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      key: const ValueKey('main-menu-settings'),
                      tooltip: 'Ayarlar',
                      onPressed: () => _open(context, const SettingsScreen()),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      key: const ValueKey('main-menu-how-to-play'),
                      tooltip: 'Nasıl oynanır?',
                      onPressed: () => _open(context, const HowToPlayScreen()),
                      icon: const Icon(Icons.help_outline),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 880),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _RelayMark(),
                          const SizedBox(height: 24),
                          _PrimaryPlayCard(
                            onPressed: () => _open(
                              context,
                              const PlayModeScreen(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 680 ? 2 : 1;
                              const spacing = 12.0;
                              final itemWidth = columns == 1
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - spacing) / 2;
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: _HubCard(
                                      key: const ValueKey('main-menu-clan'),
                                      icon: Icons.hub_outlined,
                                      accent: RelayColors.amber,
                                      title: 'KLAN',
                                      subtitle:
                                          'Klan özeti, üyeler, etkinlik ve ayarlar',
                                      onPressed: () => _open(
                                        context,
                                        const SocialScreen(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _HubCard(
                                      key: const ValueKey(
                                        'main-menu-statistics',
                                      ),
                                      icon: Icons.query_stats_outlined,
                                      accent: RelayColors.cyan,
                                      title: 'İSTATİSTİKLER',
                                      subtitle:
                                          'Sezon ve haftalık lig verilerini alt sekmelerle görüntüle',
                                      onPressed: () => _open(
                                        context,
                                        const SeasonScreen(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _HubCard(
                                      key: const ValueKey('main-menu-store'),
                                      icon: Icons.storefront_outlined,
                                      accent: RelayColors.mint,
                                      title: 'MAĞAZA',
                                      subtitle:
                                          'Modül, devre kartı ve profil kozmetiklerini tek sayfada incele',
                                      onPressed: () => _open(
                                        context,
                                        const CollectionScreen(
                                          mode: CollectionScreenMode.store,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _HubCard(
                                      key: const ValueKey('main-menu-profile'),
                                      icon: Icons.account_circle_outlined,
                                      accent: RelayColors.coral,
                                      title: 'PROFİL',
                                      subtitle:
                                          'Genel, arkadaşlar, kozmetik, ödüller, maçlar, görevler ve başarımlar',
                                      onPressed: () => _open(
                                        context,
                                        const ProfileScreen(),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'ANA MERKEZ VE MENÜ DÜZENİ • v0.8.17',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: RelayColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => screen),
    );
  }
}

class _RelayMark extends StatelessWidget {
  const _RelayMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: RelayDecorations.accentHalo(RelayColors.magenta),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: RelayEmblem(
              size: 52,
              accent: RelayColors.cyan,
              secondary: RelayColors.violet,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROJECT RELAY',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
              ),
              const SizedBox(height: 3),
              const Text(
                'DEVRENİ KUR • KARŞI STRATEJİYİ BUL',
                style: TextStyle(
                  color: RelayColors.cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryPlayCard extends StatelessWidget {
  const _PrimaryPlayCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ArcadeHoverLift(
      scale: 1.009,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('main-menu-play'),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: RelayDecorations.heroPanel(),
            child: const Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x2238E8FF),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(
                    Icons.sports_esports,
                    color: RelayColors.cyan,
                    size: 34,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OYNA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Çevrimiçi Savaş, Kariyer ve Antrenman',
                      style: TextStyle(color: RelayColors.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: RelayColors.cyan, size: 30),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ArcadeHoverLift(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: RelayDecorations.panel(accent: accent, soft: true),
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(icon, color: accent, size: 28),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: RelayColors.muted,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Icon(Icons.chevron_right, color: accent),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
