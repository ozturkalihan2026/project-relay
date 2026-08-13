import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const supportedReplaySpeeds = <double>[0.75, 1, 1.25, 1.5, 2];

enum AppLanguage {
  turkish('tr', 'Türkçe'),
  english('en', 'English');

  const AppLanguage(this.localeCode, this.displayName);

  final String localeCode;
  final String displayName;

  static AppLanguage parse(String? value) => switch (value) {
        'en' => AppLanguage.english,
        _ => AppLanguage.turkish,
      };
}

class AppSettings {
  const AppSettings({
    this.replaySoundEnabled = true,
    this.replaySpeed = 0.75,
    this.language = AppLanguage.turkish,
    this.telemetryEnabled = true,
  });

  final bool replaySoundEnabled;
  final double replaySpeed;
  final AppLanguage language;
  final bool telemetryEnabled;

  AppSettings copyWith({
    bool? replaySoundEnabled,
    double? replaySpeed,
    AppLanguage? language,
    bool? telemetryEnabled,
  }) {
    return AppSettings(
      replaySoundEnabled: replaySoundEnabled ?? this.replaySoundEnabled,
      replaySpeed: replaySpeed ?? this.replaySpeed,
      language: language ?? this.language,
      telemetryEnabled: telemetryEnabled ?? this.telemetryEnabled,
    );
  }
}

abstract interface class AppSettingsStore {
  Future<AppSettings?> load();

  Future<void> save(AppSettings settings);
}

class SecureAppSettingsStore implements AppSettingsStore {
  SecureAppSettingsStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _soundKey = 'relay.settings.replay_sound';
  static const _speedKey = 'relay.settings.replay_speed';
  static const _languageKey = 'relay.settings.language';
  static const _telemetryKey = 'relay.settings.telemetry';

  final FlutterSecureStorage _storage;

  @override
  Future<AppSettings?> load() async {
    final values = await Future.wait([
      _storage.read(key: _soundKey),
      _storage.read(key: _speedKey),
      _storage.read(key: _languageKey),
      _storage.read(key: _telemetryKey),
    ]);
    if (values.every((value) => value == null)) return null;
    final speed = double.tryParse(values[1] ?? '');
    return AppSettings(
      replaySoundEnabled: values[0] != 'false',
      replaySpeed: speed != null && supportedReplaySpeeds.contains(speed)
          ? speed
          : 0.75,
      language: AppLanguage.parse(values[2]),
      telemetryEnabled: values[3] != 'false',
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _storage.write(
        key: _soundKey,
        value: settings.replaySoundEnabled.toString(),
      ),
      _storage.write(key: _speedKey, value: settings.replaySpeed.toString()),
      _storage.write(key: _languageKey, value: settings.language.localeCode),
      _storage.write(
        key: _telemetryKey,
        value: settings.telemetryEnabled.toString(),
      ),
    ]);
  }
}

final appSettingsStoreProvider = Provider<AppSettingsStore>(
  (ref) => SecureAppSettingsStore(),
);

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);

class AppSettingsController extends Notifier<AppSettings> {
  bool _changedLocally = false;

  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  AppSettings build() {
    scheduleMicrotask(_restore);
    return const AppSettings();
  }

  Future<void> _restore() async {
    try {
      final saved = await _store.load();
      if (!_changedLocally && saved != null) state = saved;
    } catch (_) {
      // Depolama kullanılamadığında güvenli varsayılanlarla devam edilir.
    }
  }

  void setReplaySoundEnabled(bool enabled) {
    _update(state.copyWith(replaySoundEnabled: enabled));
  }

  void setReplaySpeed(double speed) {
    if (!supportedReplaySpeeds.contains(speed)) {
      throw ArgumentError.value(speed, 'speed', 'Desteklenmeyen hız');
    }
    _update(state.copyWith(replaySpeed: speed));
  }

  void setLanguage(AppLanguage language) {
    _update(state.copyWith(language: language));
  }

  void setTelemetryEnabled(bool enabled) {
    _update(state.copyWith(telemetryEnabled: enabled));
  }

  void _update(AppSettings next) {
    _changedLocally = true;
    state = next;
    unawaited(_persist(next));
  }

  Future<void> _persist(AppSettings settings) async {
    try {
      await _store.save(settings);
    } catch (_) {
      // Ayar değişikliği oturum içinde geçerli kalır; sonraki yazmada tekrar denenir.
    }
  }
}
