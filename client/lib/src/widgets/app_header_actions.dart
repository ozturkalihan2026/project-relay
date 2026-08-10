import 'package:flutter/material.dart';

import 'player_status_bar.dart';

/// Ortak üst sol profil alanı.
class AppHeaderProfile extends StatelessWidget {
  const AppHeaderProfile({
    this.showClaimBadge = true,
    super.key,
  });

  final bool showClaimBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: PlayerStatusBar(
          compact: true,
          showClaimBadge: showClaimBadge,
          onTap: () => Navigator.of(context).pushNamed('/profile'),
        ),
      ),
    );
  }
}

/// Ortak üst sağ erişim alanı. Profil soldadır; kredi, ayarlar ve yardım sağda kalır.
class AppHeaderActions extends StatelessWidget {
  const AppHeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircuitCreditButton(
          onTap: () => Navigator.of(context).pushNamed('/store'),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          key: const ValueKey('global-settings-action'),
          tooltip: 'Ayarlar',
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          key: const ValueKey('global-how-to-play-action'),
          tooltip: 'Nasıl oynanır?',
          onPressed: () => Navigator.of(context).pushNamed('/how-to-play'),
          icon: const Icon(Icons.help_outline),
        ),
      ],
    );
  }
}

/// Tüm ikincil ekranlarda aynı merkez başlık düzenini kullanır.
class AppHeaderTitle extends StatelessWidget {
  const AppHeaderTitle({
    required this.pageTitle,
    this.version = 'v0.8.22-r1-fix1',
    super.key,
  });

  final String pageTitle;
  final String version;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          pageTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.35,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          'PROJECT RELAY • $version',
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFA7C1D2),
            fontSize: 9.5,
            letterSpacing: 0.55,
          ),
        ),
      ],
    );
  }
}
