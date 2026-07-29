import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/api/relay_api.dart';
import 'package:project_relay_client/src/app.dart';
import 'package:project_relay_client/src/models/relay_models.dart';

void main() {
  testWidgets('Project Relay düzenleyici ekranını açar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogsProvider.overrideWith(
            (ref) async => const CatalogBundle(
              rulesVersion: '0.1',
              modules: <ModuleSpec>[],
              bots: <BotDefinition>[],
            ),
          ),
          guestSessionProvider.overrideWith(
            (ref) async => GuestSession(
              player: PlayerProfile(
                id: 'player-test',
                displayName: 'MaviRole-2026',
                createdAt: DateTime.utc(2026, 7, 29),
              ),
              tokens: const AuthTokens(
                accessToken: 'access-token',
                refreshToken: 'refresh-token',
                accessExpiresIn: 900,
                refreshExpiresIn: 2592000,
              ),
            ),
          ),
        ],
        child: const RelayApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PROJECT RELAY'), findsOneWidget);
    expect(find.textContaining('DEVRE LABORATUVARI'), findsOneWidget);
    expect(find.text('NASIL OYNANIR?'), findsOneWidget);
    expect(find.text('OYUN EL KİTABI'), findsOneWidget);
    expect(find.text('DEVREYİ KUR'), findsOneWidget);
    expect(find.text('ASENKRON PvP'), findsOneWidget);
    expect(find.text('KARTI KAYDET VE OYUNCU BUL'), findsOneWidget);
    expect(find.byKey(const ValueKey('guest-session-badge')), findsOneWidget);
    final compactHelp = find.byKey(
      const ValueKey('compact-how-to-play-card'),
    );
    expect(compactHelp, findsOneWidget);
    expect(tester.getSize(compactHelp).height, lessThan(110));

    await tester.tap(find.text('OYUN EL KİTABI'));
    await tester.pumpAndSettle();

    expect(find.text('OYUNUN AMACI NEDİR?'), findsOneWidget);
    expect(find.text('ENERJİ NASIL AKAR?'), findsOneWidget);
    expect(find.text('KALKAN NASIL ÇALIŞIR?'), findsOneWidget);

    final bottomBack = find.byKey(
      const ValueKey('manual-bottom-back-button'),
    );
    expect(bottomBack, findsOneWidget);
    await tester.ensureVisible(bottomBack);
    await tester.tap(bottomBack);
    await tester.pumpAndSettle();

    expect(find.textContaining('DEVRE LABORATUVARI'), findsOneWidget);
  });
}
