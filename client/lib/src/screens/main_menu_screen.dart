import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';
import 'career_screen.dart';
import 'how_to_play_screen.dart';
import 'play_mode_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _RelayMark(),
                  const SizedBox(height: 34),
                  FilledButton.icon(
                    key: const ValueKey('main-menu-play'),
                    onPressed: () => _open(
                      context,
                      const PlayModeScreen(),
                    ),
                    icon: const Icon(Icons.sports_esports),
                    label: const Text('OYNA'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MenuButton(
                    key: const ValueKey('main-menu-career'),
                    icon: Icons.route_outlined,
                    title: 'KARİYER',
                    subtitle: 'Derece, haftalık lig ve maç geçmişi',
                    onPressed: () => _open(
                      context,
                      const CareerScreen(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MenuButton(
                    key: const ValueKey('main-menu-how-to-play'),
                    icon: Icons.menu_book_outlined,
                    title: 'NASIL OYNANIR',
                    subtitle: 'Kurallar, bağlantılar ve modül rehberi',
                    onPressed: () => _open(
                      context,
                      const HowToPlayScreen(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MenuButton(
                    key: const ValueKey('main-menu-settings'),
                    icon: Icons.tune,
                    title: 'AYARLAR',
                    subtitle: 'Tekrar sesi ve oynatma hızı',
                    onPressed: () => _open(
                      context,
                      const SettingsScreen(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'ASENKRON DEVRE SAVAŞI • v0.5.0',
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
    return Column(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0x2238E8FF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x5538E8FF),
                blurRadius: 34,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(22),
            child: Icon(
              Icons.memory,
              color: RelayColors.cyan,
              size: 58,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'PROJECT RELAY',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'DEVRENİ KUR • KARŞI STRATEJİYİ BUL',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: RelayColors.cyan,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(58),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        side: const BorderSide(color: Color(0xFF2B5969)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: RelayColors.cyan),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: RelayColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: RelayColors.muted,
          ),
        ],
      ),
    );
  }
}
