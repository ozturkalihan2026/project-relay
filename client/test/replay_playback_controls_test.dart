import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/widgets/replay_playback_controls.dart';

void main() {
  testWidgets(
    'tekrar kontrolleri ortalanmış düğmeler olarak bütün eylemleri çalıştırır',
    (tester) async {
      var playbackToggles = 0;
      var restarts = 0;
      var soundToggles = 0;
      var newGames = 0;
      double? selectedSpeed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 540,
              child: ReplayPlaybackControls(
                playing: true,
                soundEnabled: true,
                speed: 1,
                onTogglePlayback: () => playbackToggles++,
                onRestart: () => restarts++,
                onToggleSound: () => soundToggles++,
                onSpeedChanged: (value) => selectedSpeed = value,
                onNewGame: () => newGames++,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Duraklat'), findsOneWidget);
      expect(find.text('Yeniden Oynat'), findsOneWidget);
      expect(find.text('Ses Açık'), findsOneWidget);
      expect(find.text('Hız 1×'), findsOneWidget);
      expect(find.text('YENİ OYUN'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('replay-new-game-button')),
          matching: find.byIcon(Icons.add_circle_outline),
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('replay-playback-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('replay-restart-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('replay-sound-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('replay-new-game-button')),
      );

      expect(playbackToggles, 1);
      expect(restarts, 1);
      expect(soundToggles, 1);
      expect(newGames, 1);
      expect(
        tester.getCenter(
          find.byKey(const ValueKey('replay-new-game-button')),
        ).dy,
        greaterThan(
          tester.getCenter(
            find.byKey(const ValueKey('replay-playback-button')),
          ).dy,
        ),
      );
      final speedButtonCenterY = tester.getCenter(
        find.byKey(const ValueKey('replay-speed-button')),
      ).dy;
      final playbackButtonCenterY = tester.getCenter(
        find.byKey(const ValueKey('replay-playback-button')),
      ).dy;
      expect(
        speedButtonCenterY,
        closeTo(playbackButtonCenterY, 0.001),
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('replay-new-game-button')),
        ),
        const Size(220, 40),
      );

      await tester.tap(
        find.byKey(const ValueKey('replay-speed-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('2×'));
      await tester.pumpAndSettle();

      expect(selectedSpeed, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('kariyer birincil eylemi sonuçtan önce devre dışıdır',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 540,
            child: ReplayPlaybackControls(
              playing: true,
              soundEnabled: true,
              speed: 1,
              onTogglePlayback: () {},
              onRestart: () {},
              onToggleSound: () {},
              onSpeedChanged: (_) {},
              onNewGame: () {},
              primaryActionLabel: 'SONRAKİ SAVAŞ',
              primaryActionKey: 'career-battle-primary-action',
              primaryActionEnabled: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('SONRAKİ SAVAŞ'), findsOneWidget);
    final action = tester.widget<FilledButton>(
      find.byKey(const ValueKey('career-battle-primary-action')),
    );
    expect(action.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dar alanda kontrol düğmeleri taşmadan satıra sarılır',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 230,
            child: ReplayPlaybackControls(
              playing: false,
              soundEnabled: false,
              speed: 0.75,
              onTogglePlayback: () {},
              onRestart: () {},
              onToggleSound: () {},
              onSpeedChanged: (_) {},
              onNewGame: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Devam Et'), findsOneWidget);
    expect(find.text('Ses Kapalı'), findsOneWidget);
    expect(find.text('Hız 0.75×'), findsOneWidget);
    expect(find.text('YENİ OYUN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
