import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/relay_features.dart';
import 'l10n/relay_strings.dart';
import 'screens/collection_screen.dart';
import 'screens/how_to_play_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_settings.dart';
import 'theme/relay_theme.dart';
import 'widgets/chat_dock.dart';

class RelayApp extends ConsumerWidget {
  const RelayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appSettingsProvider.select(
      (settings) => settings.language,
    ));
    return MaterialApp(
      title: 'Project Relay',
      debugShowCheckedModeBanner: false,
      theme: RelayTheme.dark(),
      locale: Locale(language.localeCode),
      supportedLocales: const [Locale('tr'), Locale('en')],
      localizationsDelegates: const [
        RelayStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
                  if (RelayFeatures.chat) const ChatDock(),
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
