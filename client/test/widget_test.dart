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
      expect(find.byKey(const ValueKey('player-status-bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('player-status-name')), findsOneWidget);
      expect(find.byKey(const ValueKey('player-status-level')), findsOneWidget);
      expect(find.byKey(const ValueKey('player-status-credits')), findsOneWidget);
      expect(find.byKey(const ValueKey('player-status-xp')), findsOneWidget);
      expect(find.text('OYNA'), findsOneWidget);
      expect(find.text('KARİYER'), findsOneWidget);
      expect(find.text('KOLEKSİYON'), findsOneWidget);
      expect(find.text('İSTATİSTİKLER'), findsOneWidget);
      expect(find.text('NASIL OYNANIR'), findsOneWidget);
      expect(find.text('AYARLAR'), findsOneWidget);
      expect(find.text('DEVREYİ KUR'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('main-menu-play')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('play-mode-online')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('play-mode-training')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('play-mode-back-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('play-mode-online')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final generatorPaletteTile = find.byKey(
        const ValueKey('palette-module-generator'),
      );
      expect(generatorPaletteTile, findsOneWidget);
      expect(tester.getSize(generatorPaletteTile).height, 66);

      expect(find.textContaining('ÇEVRİMİÇİ SAVAŞ • v0.6.2'), findsOneWidget);
      expect(find.text('DEVREYİ KUR'), findsOneWidget);
      expect(find.text('ASENKRON PvP'), findsOneWidget);
      expect(
        find.text('SAVAŞA BAŞLA'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('editor-menu-back-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('editor-menu-back-button')),
        findsOneWidget,
      );
      expect(find.text('SUNUCU YETKİLİ SAVAŞ'), findsNothing);
      expect(
        find.byKey(const ValueKey('player-status-bar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('guest-session-badge')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('training-panel')), findsNothing);
      expect(
        find.byKey(
          const ValueKey('palette-module-properties-generator'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('palette-module-properties-laser'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('module-icon-P-GEN')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('module-icon-P-LASER')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('module-name-P-GEN')), findsNothing);
      expect(find.byTooltip('90° döndür'), findsWidgets);
      expect(
        find.byKey(const ValueKey('compact-how-to-play-card')),
        findsNothing,
      );
      expect(find.text('OYUN EL KİTABI'), findsNothing);

      final editorBack = find.byKey(
        const ValueKey('editor-menu-back-button'),
      );
      await tester.ensureVisible(editorBack);
      await tester.pumpAndSettle();
      await tester.tap(editorBack);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('play-mode-training')));
      await tester.pumpAndSettle();

      expect(find.textContaining('ANTRENMAN • v0.6.2'), findsOneWidget);
      expect(find.byKey(const ValueKey('training-panel')), findsOneWidget);
      expect(find.text('ANTRENMAN RAKİPLERİ'), findsOneWidget);
      expect(find.text('SEÇİLİ BOTLA SAVAŞ'), findsOneWidget);
      expect(find.byKey(const ValueKey('async-pvp-card')), findsNothing);
      expect(
        find.byKey(const ValueKey('editor-menu-back-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('editor-menu-back-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('player-status-bar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('guest-session-badge')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'nasıl oynanır istatistikler ile ayarlar arasında açılır',
    (tester) async {
      await _pumpApp(tester);

      final career = find.byKey(const ValueKey('main-menu-career'));
      final collection = find.byKey(const ValueKey('main-menu-collection'));
      final statistics = find.byKey(
        const ValueKey('main-menu-statistics'),
      );
      final manual = find.byKey(const ValueKey('main-menu-how-to-play'));
      final settings = find.byKey(const ValueKey('main-menu-settings'));
      expect(
        tester.getCenter(career).dy,
        lessThan(tester.getCenter(collection).dy),
      );
      expect(
        tester.getCenter(collection).dy,
        lessThan(tester.getCenter(statistics).dy),
      );
      expect(
        tester.getCenter(statistics).dy,
        lessThan(tester.getCenter(manual).dy),
      );
      expect(tester.getCenter(manual).dy, lessThan(tester.getCenter(settings).dy));

      await tester.ensureVisible(manual);
      await tester.pumpAndSettle();
      await tester.tap(manual);
      await tester.pumpAndSettle();

      expect(find.text('NASIL OYNANIR'), findsOneWidget);
      expect(find.text('OYUNUN AMACI NEDİR?'), findsOneWidget);
      expect(find.text('ENERJİ NASIL AKAR?'), findsOneWidget);
      expect(find.text('KALKAN NASIL ÇALIŞIR?'), findsOneWidget);
      expect(find.text('SEKİZLİ KİT VE KOLEKSİYON'), findsWidgets);
      final careerGuide = find.text('KARİYER KOŞUSU VE KARŞI DEVRE');
      await tester.scrollUntilVisible(careerGuide, 260);
      await tester.pumpAndSettle();
      expect(careerGuide, findsOneWidget);

      final bottomBack = find.byKey(
        const ValueKey('manual-bottom-back-button'),
      );
      expect(bottomBack, findsOneWidget);
      expect(find.text('ANA MENÜYE DÖN'), findsOneWidget);
      await tester.ensureVisible(bottomBack);
      await tester.tap(bottomBack);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('main-menu-play')), findsOneWidget);
    },
  );

  testWidgets(
    'kariyer istatistikler oyna ve ayarlar ana menüye döner',
    (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('main-menu-career')));
      await tester.pumpAndSettle();
      expect(find.text('OYUNCU SEVİYESİ'), findsOneWidget);
      expect(find.text('BEŞ SAVAŞLIK KARİYER KOŞUSU'), findsOneWidget);
      expect(find.text('KOŞUYU BAŞLAT'), findsOneWidget);
      expect(find.text('GÜNLÜK GÖREVLER'), findsOneWidget);
      final boosterMasteryTitle = find.text('GÜÇLENDİRİCİ USTALIĞI');
      await tester.scrollUntilVisible(boosterMasteryTitle, 220);
      await tester.pumpAndSettle();
      expect(boosterMasteryTitle, findsOneWidget);
      final careerBack = find.byKey(const ValueKey('career-back-button'));
      await tester.scrollUntilVisible(careerBack, 220);
      await tester.pumpAndSettle();
      await tester.tap(careerBack);
      await tester.pumpAndSettle();

      final statisticsMenu = find.byKey(
        const ValueKey('main-menu-statistics'),
      );
      await tester.ensureVisible(statisticsMenu);
      await tester.pumpAndSettle();
      await tester.tap(statisticsMenu);
      await tester.pumpAndSettle();
      expect(find.text('DERECE PUANI'), findsOneWidget);
      expect(find.text('HAFTALIK LİG'), findsOneWidget);
      final recentMatchesTitle = find.text('SON MAÇLAR');
      await tester.scrollUntilVisible(recentMatchesTitle, 220);
      await tester.pumpAndSettle();
      expect(recentMatchesTitle, findsOneWidget);
      final statisticsBack = find.byKey(
        const ValueKey('statistics-back-button'),
      );
      await tester.scrollUntilVisible(statisticsBack, 180);
      await tester.pumpAndSettle();
      await tester.tap(statisticsBack);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('main-menu-play')));
      await tester.pumpAndSettle();
      final playBack = find.byKey(const ValueKey('play-mode-back-button'));
      await tester.ensureVisible(playBack);
      await tester.tap(playBack);
      await tester.pumpAndSettle();

      final settingsMenu = find.byKey(const ValueKey('main-menu-settings'));
      await tester.ensureVisible(settingsMenu);
      await tester.pumpAndSettle();
      await tester.tap(settingsMenu);
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

      final settingsBack = find.byKey(
        const ValueKey('settings-back-button'),
      );
      await tester.ensureVisible(settingsBack);
      await tester.tap(settingsBack);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('main-menu-play')), findsOneWidget);
    },
  );

  testWidgets(
    'koleksiyon ekranı kontrollü sekizli kiti ve kozmetikleri gösterir',
    (tester) async {
      await _pumpApp(tester);

      final collectionMenu = find.byKey(
        const ValueKey('main-menu-collection'),
      );
      await tester.ensureVisible(collectionMenu);
      await tester.tap(collectionMenu);
      await tester.pumpAndSettle();

      expect(find.text('KOLEKSİYON VE KİT'), findsOneWidget);
      expect(find.text('KONTROLLÜ SEKİZLİ KİT'), findsOneWidget);
      expect(find.byKey(const ValueKey('collection-credits')), findsOneWidget);
      expect(find.byKey(const ValueKey('controlled-kit-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('kit-slot-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('kit-slot-7')), findsOneWidget);
      expect(find.byKey(const ValueKey('save-controlled-kit')), findsOneWidget);

      final back = find.byKey(const ValueKey('collection-menu-back'));
      await tester.scrollUntilVisible(back, 280);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('main-menu-play')), findsOneWidget);
    },
  );

  testWidgets(
    'yerleşim uyarısı ortalanmış ortak bildirimde gösterilir',
    (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('main-menu-play')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('play-mode-online')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('palette-module-laser')),
      );
      await tester.tap(find.byKey(const ValueKey('circuit-cell-5')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('relay-centered-notice')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Ortadaki 2×2 alan pasif çekirdeğe ayrılmıştır'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);

      await tester.pump(const Duration(seconds: 7));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('relay-centered-notice')),
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
        collectionProvider.overrideWith(
          (ref) async => CollectionSnapshot(
            playerId: 'player-test',
            credits: 230,
            cosmetics: const [
              CosmeticItem(
                id: 'module_neon_cyan',
                category: 'module_skin',
                displayName: 'Neon Sinyal',
                description: 'Başlangıç modül kaplaması.',
                creditCost: 0,
                accentHex: '#38E8FF',
                owned: true,
                equipped: true,
              ),
              CosmeticItem(
                id: 'board_midnight_grid',
                category: 'board_theme',
                displayName: 'Gece Izgarası',
                description: 'Başlangıç devre kartı teması.',
                creditCost: 0,
                accentHex: '#184B5B',
                owned: true,
                equipped: true,
              ),
              CosmeticItem(
                id: 'frame_signal',
                category: 'profile_frame',
                displayName: 'Sinyal Çerçevesi',
                description: 'Başlangıç profil çerçevesi.',
                creditCost: 0,
                accentHex: '#68F5C0',
                owned: true,
                equipped: true,
              ),
            ],
            kit: ControlledKit(
              name: 'Dengeli Sekizli',
              moduleKinds: const [
                ModuleKind.generator,
                ModuleKind.battery,
                ModuleKind.laser,
                ModuleKind.laser,
                ModuleKind.pulseCannon,
                ModuleKind.shield,
                ModuleKind.cooler,
                ModuleKind.repair,
              ],
              updatedAt: DateTime.utc(2026, 7, 31),
            ),
            equippedModuleSkinId: 'module_neon_cyan',
            equippedBoardThemeId: 'board_midnight_grid',
            equippedProfileFrameId: 'frame_signal',
          ),
        ),
        statisticsProvider.overrideWith(
          (ref) async => CareerSnapshot(
            profile: const RatingProfile(
              playerId: 'player-test',
              rating: 1016,
              peakRating: 1016,
              ratedMatches: 1,
              wins: 1,
              draws: 0,
              losses: 0,
              winRate: 1,
            ),
            league: LeagueEntry(
              weekKey: '2026-W31',
              startsAt: DateTime.utc(2026, 7, 27),
              endsAt: DateTime.utc(2026, 8, 3),
              points: 3,
              wins: 1,
              draws: 0,
              losses: 0,
              position: 1,
              participantCount: 2,
            ),
            leaderboard: const [
              LeagueStanding(
                position: 1,
                playerId: 'player-test',
                displayName: 'MaviRole-2026',
                points: 3,
                wins: 1,
                draws: 0,
                losses: 0,
                rating: 1016,
                isCurrentPlayer: true,
              ),
            ],
            recentMatches: const [],
            matchmaking: const MatchmakingMetrics(
              searches: 1,
              humanOpponents: 1,
              botFallbacks: 0,
              humanOpponentRate: 1,
            ),
          ),
        ),
        progressionProvider.overrideWith(
          (ref) async => ProgressionSnapshot(
            dayKey: '2026-07-31',
            profile: const PlayerProgression(
              playerId: 'player-test',
              totalXp: 50,
              level: 1,
              xpIntoLevel: 50,
              xpForNextLevel: 100,
              credits: 30,
              matchesCompleted: 1,
              wins: 1,
              draws: 0,
              losses: 0,
            ),
            dailyMissions: const [
              DailyMission(
                id: 'first_signal',
                title: 'İlk Sinyal',
                description: 'Bir asenkron devre savaşını tamamla.',
                progress: 1,
                target: 1,
                completed: true,
                claimed: false,
                rewardXp: 30,
                rewardCredits: 25,
              ),
            ],
            achievements: const [
              PlayerAchievement(
                id: 'first_battle',
                title: 'Devreye Giriş',
                description: 'İlk asenkron savaşını tamamla.',
                progress: 1,
                target: 1,
                unlocked: true,
                claimed: false,
                rewardXp: 100,
                rewardCredits: 50,
              ),
            ],
            boosters: const [
              BoosterMastery(
                id: 'overcharge',
                displayName: 'Aşırı Şarj',
                description: 'Koşu içinde geçici üretim artışı.',
                unlockLevel: 1,
                unlocked: true,
                tier: 1,
                effectValue: 5,
                effectLabel: 'Jeneratör üretimi +%5',
                nextTierLevel: 10,
              ),
            ],
          ),
        ),
        careerRunProvider.overrideWith(
          (ref) async => const CareerRunSnapshot(
            runId: null,
            status: 'idle',
            stageIndex: 0,
            totalStages: 5,
            wins: 0,
            selectedBoosters: [],
            offeredBoosters: [],
            opponent: null,
            lastMatchId: null,
            reward: null,
            boardRequired: false,
            canBattle: false,
            canChooseBooster: false,
            startedAt: null,
            endedAt: null,
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
