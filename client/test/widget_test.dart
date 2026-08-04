import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/api/relay_api.dart';
import 'package:project_relay_client/src/app.dart';
import 'package:project_relay_client/src/models/relay_models.dart';

void main() {
  testWidgets(
    'ana merkez sade menüyü ve üç oyun kipini açar',
    (tester) async {
      await _pumpApp(tester);

      expect(find.text('PROJECT RELAY'), findsOneWidget);
      expect(find.byKey(const ValueKey('player-status-bar')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('player-status-profile-action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('player-status-claim-badge')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('main-menu-play')), findsOneWidget);
      expect(find.byKey(const ValueKey('main-menu-clan')), findsOneWidget);
      expect(find.byKey(const ValueKey('main-menu-collection')), findsOneWidget);
      expect(find.byKey(const ValueKey('main-menu-store')), findsOneWidget);
      expect(find.byKey(const ValueKey('main-menu-profile')), findsOneWidget);
      expect(find.byKey(const ValueKey('main-menu-settings')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('main-menu-how-to-play')),
        findsOneWidget,
      );
      expect(find.text('SEZON VE ALFA'), findsNothing);
      expect(find.text('İSTATİSTİKLER'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('main-menu-play')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('play-mode-online')), findsOneWidget);
      expect(find.byKey(const ValueKey('play-mode-career')), findsOneWidget);
      expect(find.byKey(const ValueKey('play-mode-training')), findsOneWidget);
      expect(find.byKey(const ValueKey('play-mode-back-button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('play-mode-online')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('ÇEVRİMİÇİ SAVAŞ • v0.8.3'), findsOneWidget);
      expect(find.text('DEVREYİ KUR'), findsOneWidget);

      final editorBack = find.byKey(
        const ValueKey('editor-menu-back-button'),
      );
      await tester.ensureVisible(editorBack);
      await tester.pumpAndSettle();
      await tester.tap(editorBack);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('play-mode-training')));
      await tester.pumpAndSettle();
      expect(find.textContaining('ANTRENMAN • v0.8.3'), findsOneWidget);
      expect(find.byKey(const ValueKey('training-panel')), findsOneWidget);
    },
  );

  testWidgets(
    'üst çubuk profil ayarlar ve nasıl oynanır erişimi sağlar',
    (tester) async {
      await _pumpApp(tester);

      await tester.tap(
        find.byKey(const ValueKey('player-status-profile-action')),
      );
      await tester.pumpAndSettle();
      expect(find.text('PROFİL'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-section-selector')),
        findsOneWidget,
      );
      final profileBack = find.byKey(const ValueKey('profile-menu-back'));
      await tester.ensureVisible(profileBack);
      await tester.tap(profileBack);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('main-menu-settings')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('settings-replay-sound')),
        findsOneWidget,
      );
      final settingsBack = find.byKey(
        const ValueKey('settings-back-button'),
      );
      await tester.ensureVisible(settingsBack);
      await tester.tap(settingsBack);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('main-menu-how-to-play')));
      await tester.pumpAndSettle();
      expect(find.text('NASIL OYNANIR'), findsOneWidget);
      expect(find.text('OYUNUN AMACI NEDİR?'), findsOneWidget);
      expect(find.text('ENERJİ NASIL AKAR?'), findsOneWidget);
    },
  );

  testWidgets(
    'profil derece sezon geçmiş görev ve başarımları toplar',
    (tester) async {
      await _pumpApp(tester);
      final profile = find.byKey(const ValueKey('main-menu-profile'));
      await tester.ensureVisible(profile);
      await tester.tap(profile);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('profile-general-card')), findsOneWidget);

      await _tapProfileSection(
        tester,
        const ValueKey('profile-section-rating-season'),
      );
      expect(find.byKey(const ValueKey('profile-rating-card')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-weekly-league-card')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('profile-season-card')), findsOneWidget);

      await _tapProfileSection(
        tester,
        const ValueKey('profile-section-match-history'),
      );
      expect(
        find.byKey(const ValueKey('profile-match-history-card')),
        findsOneWidget,
      );

      await _tapProfileSection(
        tester,
        const ValueKey('profile-section-daily-missions'),
      );
      expect(
        find.byKey(const ValueKey('profile-daily-missions-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('profile-daily-first_signal')),
        findsOneWidget,
      );

      await _tapProfileSection(
        tester,
        const ValueKey('profile-section-achievements'),
      );
      expect(
        find.byKey(const ValueKey('profile-achievements-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('profile-achievement-first_battle')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'klan koleksiyon ve mağaza ana merkezden ayrık açılır',
    (tester) async {
      await _pumpApp(tester);

      final clan = find.byKey(const ValueKey('main-menu-clan'));
      await tester.ensureVisible(clan);
      await tester.tap(clan);
      await tester.pumpAndSettle();
      expect(find.text('KLAN'), findsWidgets);
      expect(find.byKey(const ValueKey('social-no-clan-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('social-clan-directory')), findsOneWidget);
      final socialBack = find.byKey(const ValueKey('social-menu-back'));
      await tester.ensureVisible(socialBack);
      await tester.tap(socialBack);
      await tester.pumpAndSettle();

      final collection = find.byKey(const ValueKey('main-menu-collection'));
      await tester.ensureVisible(collection);
      await tester.tap(collection);
      await tester.pumpAndSettle();
      expect(find.text('KOLEKSİYON'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collection-section-selector')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('controlled-kit-card')), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('collection-section-cosmetics')),
      );
      await tester.pumpAndSettle();
      expect(find.text('MODÜL KAPLAMALARI'), findsOneWidget);
      final collectionBack = find.byKey(
        const ValueKey('collection-menu-back'),
      );
      final collectionScrollable = find.descendant(
        of: find.byKey(const ValueKey('collection-scroll-view')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      expect(collectionScrollable, findsOneWidget);
      await tester.scrollUntilVisible(
        collectionBack,
        280,
        scrollable: collectionScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(collectionBack);
      await tester.pumpAndSettle();

      final store = find.byKey(const ValueKey('main-menu-store'));
      await tester.ensureVisible(store);
      await tester.tap(store);
      await tester.pumpAndSettle();
      expect(find.text('MAĞAZA'), findsOneWidget);
      expect(find.byKey(const ValueKey('store-intro-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('store-scroll-view')), findsOneWidget);
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


Future<void> _tapProfileSection(
  WidgetTester tester,
  Key sectionKey,
) async {
  final section = find.byKey(sectionKey);
  final horizontalScrollable = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable &&
        widget.axisDirection == AxisDirection.right,
  );

  expect(section, findsOneWidget);
  expect(horizontalScrollable, findsOneWidget);
  await tester.scrollUntilVisible(
    section,
    260,
    scrollable: horizontalScrollable,
  );
  await tester.pumpAndSettle();
  await tester.tap(section);
  await tester.pumpAndSettle();
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

        socialProvider.overrideWith(
          (ref) async => SocialSnapshotModel(
            profile: const SocialProfileModel(
              playerId: 'player-test',
              displayName: 'MaviRole-2026',
              statusMessage: 'Dengeli devreler kuruyorum.',
              favoriteModule: ModuleKind.battery,
              friendCount: 1,
            ),
            incomingRequests: [
              FriendRequestModel(
                requestId: 'incoming-1',
                player: const SocialPlayerModel(
                  playerId: 'player-incoming',
                  displayName: 'SinyalUstasi',
                  statusMessage: 'Kalkan düzenleri deniyorum.',
                  favoriteModule: ModuleKind.shield,
                  relationship: 'incoming',
                ),
                createdAt: DateTime.utc(2026, 8, 1),
              ),
            ],
            outgoingRequests: [
              FriendRequestModel(
                requestId: 'outgoing-1',
                player: const SocialPlayerModel(
                  playerId: 'player-outgoing',
                  displayName: 'VoltGezgini',
                  statusMessage: 'Enerji zincirleri kuruyorum.',
                  favoriteModule: ModuleKind.generator,
                  relationship: 'outgoing',
                ),
                createdAt: DateTime.utc(2026, 8, 1),
              ),
            ],
            friends: const [
              SocialPlayerModel(
                playerId: 'player-friend',
                displayName: 'DevreMuhafizi',
                statusMessage: 'Savunma ve onarım odaklı.',
                favoriteModule: ModuleKind.repair,
                relationship: 'friend',
              ),
            ],
            clan: null,
          ),
        ),
        clanDirectoryProvider.overrideWith(
          (ref) async => const [
            ClanModel(
              clanId: 'clan-alpha',
              name: 'Alfa Devreleri',
              tag: 'ALFA',
              description: 'Adil ve dengeli devreler kuran açık klan.',
              leaderPlayerId: 'player-leader',
              isOpen: true,
              memberCount: 4,
              members: [],
            ),
          ],
        ),
        seasonProvider.overrideWith(
          (ref) async => SeasonSnapshotModel(
            season: SeasonWindowModel(
              key: '2026-08',
              title: 'ALFA SEZONU 2026.08',
              startsAt: DateTime.utc(2026, 8, 1),
              endsAt: DateTime.utc(2026, 9, 1),
            ),
            entry: const SeasonEntryModel(
              points: 18,
              matches: 4,
              wins: 3,
              draws: 0,
              losses: 1,
              position: 1,
              participantCount: 2,
              claimedTiers: <int>{},
            ),
            tiers: const [
              SeasonTierModel(
                tier: 1,
                title: 'İlk Devre',
                requiredPoints: 12,
                rewardXp: 20,
                rewardCredits: 8,
                unlocked: true,
                claimed: false,
              ),
            ],
            leaderboard: const [
              SeasonStandingModel(
                position: 1,
                playerId: 'player-test',
                displayName: 'MaviRole-2026',
                points: 18,
                wins: 3,
                matches: 4,
                isCurrentPlayer: true,
              ),
            ],
          ),
        ),
        alphaSafetyProvider.overrideWith(
          (ref) async => const AlphaSafetySnapshotModel(
            matchRequests: 2,
            matchLimit: 20,
            matchWindowSeconds: 60,
            feedbackRequests: 0,
            feedbackLimit: 3,
            feedbackWindowSeconds: 3600,
            blockedUntil: null,
            serverAuthoritativeResults: true,
            idempotentRewards: true,
            boardValidation: true,
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
