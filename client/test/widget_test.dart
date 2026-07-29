import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/api/relay_api.dart';
import 'package:project_relay_client/src/app.dart';
import 'package:project_relay_client/src/models/relay_models.dart';

void main() {
  testWidgets(
    'ana menü çevrimiçi savaş ve antrenmanı ayrı açar',
    (tester) async {
      await _pumpApp(tester);

      expect(find.text('PROJECT RELAY'), findsOneWidget);
      expect(find.byKey(const ValueKey('main-menu-play')), findsOneWidget);
      expect(find.text('OYNA'), findsOneWidget);
      expect(find.text('KARİYER'), findsOneWidget);
      expect(find.text('AYARLAR'), findsOneWidget);
      expect(find.text('DEVREYİ KUR'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('main-menu-play')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('play-mode-online')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('play-mode-training')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('play-mode-online')));
      await tester.pumpAndSettle();

      expect(find.textContaining('ÇEVRİMİÇİ SAVAŞ • v0.4.7'), findsOneWidget);
      expect(find.text('DEVREYİ KUR'), findsOneWidget);
      expect(find.text('ASENKRON PvP'), findsOneWidget);
      expect(
        find.text('KARTI KAYDET VE OYUNCU BUL'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('guest-session-badge')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('training-panel')), findsNothing);
      expect(
        find.byKey(const ValueKey('module-stat-badges-P-GEN')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('module-stat-badges-P-LASER')),
        findsOneWidget,
      );

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

      expect(find.textContaining('ÇEVRİMİÇİ SAVAŞ'), findsOneWidget);

      Navigator.of(
        tester.element(find.byType(Scaffold).first),
      ).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('play-mode-training')));
      await tester.pumpAndSettle();

      expect(find.textContaining('ANTRENMAN • v0.4.7'), findsOneWidget);
      expect(find.byKey(const ValueKey('training-panel')), findsOneWidget);
      expect(find.text('ANTRENMAN RAKİPLERİ'), findsOneWidget);
      expect(find.text('SEÇİLİ BOTLA SAVAŞ'), findsOneWidget);
      expect(find.byKey(const ValueKey('async-pvp-card')), findsNothing);
      expect(
        find.byKey(const ValueKey('guest-session-badge')),
        findsNothing,
      );
    },
  );

  testWidgets('kariyer ve ayarlar kendi ekranlarını açar', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('main-menu-career')));
    await tester.pumpAndSettle();
    expect(find.text('KARİYER HAZIRLANIYOR'), findsOneWidget);
    expect(find.text('GÖREVLER'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('career-back-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('main-menu-settings')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-replay-sound')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-replay-speed')),
      findsOneWidget,
    );

    await tester.tap(find.text('2×'));
    await tester.pumpAndSettle();
    final segmented = tester.widget<SegmentedButton<double>>(
      find.byKey(const ValueKey('settings-replay-speed')),
    );
    expect(segmented.selected, {2.0});
  });

  testWidgets(
    'yerleşim uyarısı okunabilir bağlamsal kartta gösterilir',
    (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('main-menu-play')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('play-mode-online')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('palette-module-generator')),
      );
      await tester.tap(find.byKey(const ValueKey('circuit-cell-0')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('editor-context-notice')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Jeneratör yalnızca çekirdeğin dört kapı'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);

      final dismissButton = find.byKey(
        const ValueKey('editor-notice-dismiss'),
      );
      await tester.ensureVisible(dismissButton);
      await tester.pumpAndSettle();
      await tester.tap(dismissButton);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('editor-context-notice')),
        findsNothing,
      );
    },
  );
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogsProvider.overrideWith(
          (ref) async => CatalogBundle(
            rulesVersion: '0.8',
            modules: _moduleSpecs(),
            bots: const [
              BotDefinition(
                id: 'starter_laser',
                displayName: 'Başlangıç Lazeri',
                difficulty: 'Kolay',
                description: 'Dengeli başlangıç rakibi.',
                availableModuleCounts: [2],
              ),
            ],
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
}

List<ModuleSpec> _moduleSpecs() {
  return const [
    ModuleSpec(
      kind: ModuleKind.generator,
      displayName: 'Jeneratör',
      description: 'Enerji üretir.',
      maxHp: 52,
      ports: {
        RelayDirection.north,
        RelayDirection.east,
        RelayDirection.south,
      },
      energyOutput: 8,
      batteryCapacity: 0,
      energyCost: 0,
      cooldownTicks: 0,
      heatPerAction: 0,
      damage: 0,
      shield: 0,
      cooling: 0,
      repair: 0,
      threat: 60,
    ),
    ModuleSpec(
      kind: ModuleKind.laser,
      displayName: 'Lazer',
      description: 'Sık ateş eder.',
      maxHp: 27,
      ports: {RelayDirection.west},
      energyOutput: 0,
      batteryCapacity: 0,
      energyCost: 4,
      cooldownTicks: 2,
      heatPerAction: 14,
      damage: 8,
      shield: 0,
      cooling: 0,
      repair: 0,
      threat: 100,
    ),
  ];
}
