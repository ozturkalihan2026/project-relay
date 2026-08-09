import 'package:flutter/material.dart';

import 'screens/collection_screen.dart';
import 'screens/how_to_play_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/relay_theme.dart';
import 'widgets/chat_dock.dart';

class RelayApp extends StatelessWidget {
  const RelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Relay',
      debugShowCheckedModeBanner: false,
      theme: RelayTheme.dark(),
      builder: (context, child) => Navigator(
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (overlayContext, animation, secondaryAnimation) {
            return DecoratedBox(
              decoration: RelayDecorations.appBackground(),
              child: Stack(
                children: [
                  Positioned.fill(child: child ?? const SizedBox.shrink()),
                  const ChatDock(),
                ],
              ),
            );
          },
        ),
      ),
      home: const MainMenuScreen(),
      routes: {
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/how-to-play': (context) => const HowToPlayScreen(),
        '/store': (context) => const CollectionScreen(
              mode: CollectionScreenMode.store,
            ),
      },
    );
  }
}
