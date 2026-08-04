import 'package:flutter/material.dart';

import 'player_status_bar.dart';

/// Ortak üst sağ erişim alanı.
///
/// Profil kartı, Ayarlar ve Nasıl Oynanır bütün ana ekranlarda aynı yerde ve
/// aktif kalır. Rotalar [RelayApp] içinde adlandırılmıştır.
class AppHeaderActions extends StatelessWidget {
  const AppHeaderActions({
    this.showClaimBadge = true,
    super.key,
  });

  final bool showClaimBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerStatusBar(
          compact: true,
          showClaimBadge: showClaimBadge,
          onTap: () => Navigator.of(context).pushNamed('/profile'),
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
