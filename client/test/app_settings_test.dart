import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/state/app_settings.dart';

void main() {
  test('savaş tekrarı varsayılanlarını günceller', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(appSettingsProvider).replaySoundEnabled, isTrue);
    expect(container.read(appSettingsProvider).replaySpeed, 0.75);
    expect(container.read(appSettingsProvider).language, AppLanguage.turkish);
    expect(container.read(appSettingsProvider).telemetryEnabled, isTrue);

    final controller = container.read(appSettingsProvider.notifier)
      ..setReplaySoundEnabled(false)
      ..setReplaySpeed(2)
      ..setLanguage(AppLanguage.english)
      ..setTelemetryEnabled(false);

    expect(container.read(appSettingsProvider).replaySoundEnabled, isFalse);
    expect(container.read(appSettingsProvider).replaySpeed, 2);
    expect(container.read(appSettingsProvider).language, AppLanguage.english);
    expect(container.read(appSettingsProvider).telemetryEnabled, isFalse);
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

  test('kaydedilmiş ayarları yükler ve sonraki değişikliği saklar', () async {
    final store = _MemorySettingsStore(
      const AppSettings(
        replaySoundEnabled: false,
        replaySpeed: 1.5,
        language: AppLanguage.english,
        telemetryEnabled: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [appSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    container.read(appSettingsProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(appSettingsProvider).replaySoundEnabled, isFalse);
    expect(container.read(appSettingsProvider).replaySpeed, 1.5);
    expect(container.read(appSettingsProvider).language, AppLanguage.english);
    expect(container.read(appSettingsProvider).telemetryEnabled, isFalse);

    container
        .read(appSettingsProvider.notifier)
        .setTelemetryEnabled(true);
    await Future<void>.delayed(Duration.zero);
    expect(store.saved?.telemetryEnabled, isTrue);
  });
}

class _MemorySettingsStore implements AppSettingsStore {
  _MemorySettingsStore(this.value);

  AppSettings? value;
  AppSettings? saved;

  @override
  Future<AppSettings?> load() async => value;

  @override
  Future<void> save(AppSettings settings) async {
    saved = settings;
    value = settings;
  }
}
