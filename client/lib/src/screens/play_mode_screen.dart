import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';
import '../widgets/app_header_actions.dart';
import 'career_screen.dart';
import 'editor_screen.dart';

class PlayModeScreen extends StatelessWidget {
  const PlayModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'OYNA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        actions: const [
          AppHeaderActions(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'SAVAŞ TÜRÜNÜ SEÇ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RelayColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ModeCard(
                    key: const ValueKey('play-mode-online'),
                    icon: Icons.public,
                    color: RelayColors.mint,
                    title: 'ÇEVRİMİÇİ SAVAŞ',
                    subtitle:
                        'Kartını kaydet, eşit modüllü gerçek oyuncu düzeniyle '
                        'eşleş. Yeni rakip yoksa dengeli sunucu rakibi gelir.',
                    badge: 'ASENKRON PvP',
                    onPressed: () => _openEditor(
                      context,
                      EditorMode.online,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ModeCard(
                    key: const ValueKey('play-mode-career'),
                    icon: Icons.route_outlined,
                    color: RelayColors.cyan,
                    title: 'KARİYER',
                    subtitle:
                        'Beş savaşlık koşuda rakip devreleri incele, geçici '
                        'güçlendirici seç ve boss devresine ulaş.',
                    badge: 'KOŞU MODU',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const CareerScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ModeCard(
                    key: const ValueKey('play-mode-training'),
                    icon: Icons.smart_toy_outlined,
                    color: RelayColors.amber,
                    title: 'ANTRENMAN',
                    subtitle:
                        'Dokuz sabit rakipten birini seç, devreni kaydetmeden '
                        'düzenini ve karşı stratejilerini sına.',
                    badge: 'BOT SAVAŞI',
                    onPressed: () => _openEditor(
                      context,
                      EditorMode.training,
                    ),
                  ),
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    key: const ValueKey('play-mode-back-button'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('ANA MENÜYE DÖN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, EditorMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EditorScreen(mode: mode),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.55)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(icon, color: color, size: 32),
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
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: RelayColors.muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 18),
                child: Icon(
                  Icons.chevron_right,
                  color: RelayColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
