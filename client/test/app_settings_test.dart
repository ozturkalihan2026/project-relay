import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/state/app_settings.dart';

void main() {
  test('savaş tekrarı varsayılanlarını günceller', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(appSettingsProvider).replaySoundEnabled, isTrue);
    expect(container.read(appSettingsProvider).replaySpeed, 0.75);

    final controller = container.read(appSettingsProvider.notifier)
      ..setReplaySoundEnabled(false)
      ..setReplaySpeed(2);

    expect(container.read(appSettingsProvider).replaySoundEnabled, isFalse);
    expect(container.read(appSettingsProvider).replaySpeed, 2);
    expect(controller, isNotNull);
  });

  test('desteklenmeyen tekrar hızını reddeder', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container
          .read(appSettingsProvider.notifier)
          .setReplaySpeed(3),
      throwsArgumentError,
    );
  });

  test('desteklenen tekrar hızlarının tamamını kabul eder', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(appSettingsProvider.notifier);
    for (final speed in supportedReplaySpeeds) {
      controller.setReplaySpeed(speed);
      expect(container.read(appSettingsProvider).replaySpeed, speed);
    }
  });
}
