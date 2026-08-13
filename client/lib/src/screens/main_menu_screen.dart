import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/relay_features.dart';
import '../l10n/relay_strings.dart';
import '../state/app_settings.dart';
import '../state/product_telemetry.dart';
import '../theme/relay_theme.dart';
import '../widgets/animated_circuit_background.dart';
import '../widgets/ambient_music.dart';
import '../widgets/arcade_motion.dart';
import '../widgets/player_status_bar.dart';
import '../widgets/relay_emblem.dart';
import 'career_screen.dart';
import 'collection_screen.dart';
import 'editor_screen.dart';
import 'how_to_play_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'season_screen.dart';
import 'social_screen.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = RelayStrings.of(context);
    return AmbientMusic(
      asset: 'sounds/menu_ambient.wav',
      enabled: ref.watch(appSettingsProvider).replaySoundEnabled,
      child: Scaffold(
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
                            compact: true,
                            onTap: () => _open(context, const ProfileScreen()),
                            showClaimBadge: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (RelayFeatures.store) ...[
                        CircuitCreditButton(
                          onTap: () => _open(
                            context,
                            const CollectionScreen(
                              mode: CollectionScreenMode.store,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
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
                        onPressed: () =>
                            _open(context, const HowToPlayScreen()),
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
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 700;
                                final online = _PrimaryModeCard(
                                  key: const ValueKey('main-menu-online'),
                                  icon: Icons.public,
                                  accent: RelayColors.mint,
                                  badge: strings.onlineBadge,
                                  title: strings.onlineBattle,
                                  subtitle: strings.onlineSubtitle,
                                  onPressed: () {
                                    ref
                                        .read(productTelemetryProvider)
                                        .track(
                                          'mode_selected',
                                          context: const {'mode': 'online'},
                                        );
                                    _open(
                                      context,
                                      const EditorScreen(
                                        mode: EditorMode.online,
                                      ),
                                    );
                                  },
                                );
                                final career = _PrimaryModeCard(
                                  key: const ValueKey('main-menu-career'),
                                  icon: Icons.route_outlined,
                                  accent: RelayColors.cyan,
                                  badge: strings.careerBadge,
                                  title: strings.careerPath,
                                  subtitle: strings.careerSubtitle,
                                  onPressed: () {
                                    ref
                                        .read(productTelemetryProvider)
                                        .track(
                                          'mode_selected',
                                          context: const {'mode': 'career'},
                                        );
                                    _open(context, const CareerScreen());
                                  },
                                );
                                if (wide) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: online),
                                      const SizedBox(width: 14),
                                      Expanded(child: career),
                                    ],
                                  );
                                }
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    online,
                                    const SizedBox(height: 12),
                                    career,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth >= 680
                                    ? 2
                                    : 1;
                                const spacing = 12.0;
                                final itemWidth = columns == 1
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - spacing) / 2;
                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    if (RelayFeatures.clans)
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
                                        title: strings.statistics,
                                        subtitle: strings.statisticsSubtitle,
                                        onPressed: () => _open(
                                          context,
                                          const SeasonScreen(),
                                        ),
                                      ),
                                    ),
                                    if (RelayFeatures.store)
                                      SizedBox(
                                        width: itemWidth,
                                        child: _HubCard(
                                          key: const ValueKey(
                                            'main-menu-store',
                                          ),
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
                                        key: const ValueKey(
                                          'main-menu-profile',
                                        ),
                                        icon: Icons.account_circle_outlined,
                                        accent: RelayColors.coral,
                                        title: strings.profile,
                                        subtitle: strings.profileSubtitle,
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
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => screen));
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

class _PrimaryModeCard extends StatelessWidget {
  const _PrimaryModeCard({
    required this.icon,
    required this.accent,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color accent;
  final String badge;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ArcadeHoverLift(
      scale: 1.009,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: RelayDecorations.panel(accent: accent),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(icon, color: accent, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge,
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
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
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: accent, size: 28),
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
