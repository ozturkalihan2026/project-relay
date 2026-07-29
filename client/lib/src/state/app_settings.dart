import 'package:flutter_riverpod/flutter_riverpod.dart';

const supportedReplaySpeeds = <double>[0.25, 0.5, 1, 2];

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);

class AppSettings {
  const AppSettings({
    this.replaySoundEnabled = true,
    this.replaySpeed = 1,
  });

  final bool replaySoundEnabled;
  final double replaySpeed;

  AppSettings copyWith({
    bool? replaySoundEnabled,
    double? replaySpeed,
  }) {
    return AppSettings(
      replaySoundEnabled:
          replaySoundEnabled ?? this.replaySoundEnabled,
      replaySpeed: replaySpeed ?? this.replaySpeed,
    );
  }
}

class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void setReplaySoundEnabled(bool enabled) {
    state = state.copyWith(replaySoundEnabled: enabled);
  }

  void setReplaySpeed(double speed) {
    if (!supportedReplaySpeeds.contains(speed)) {
      throw ArgumentError.value(speed, 'speed', 'Desteklenmeyen hız');
    }
    state = state.copyWith(replaySpeed: speed);
  }
}
