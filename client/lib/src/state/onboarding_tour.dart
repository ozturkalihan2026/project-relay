import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum OnboardingTourStep {
  inactive,
  mainMenu,
  modulePlacement,
  validateAndBattle,
  settings,
  sound,
}

class OnboardingTourState {
  const OnboardingTourState({
    this.initialized = false,
    this.step = OnboardingTourStep.inactive,
  });

  final bool initialized;
  final OnboardingTourStep step;

  bool get active => step != OnboardingTourStep.inactive;
}

abstract interface class OnboardingTourStore {
  Future<bool> isComplete();

  Future<void> markComplete();
}

class SecureOnboardingTourStore implements OnboardingTourStore {
  SecureOnboardingTourStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _completeKey = 'relay.onboarding.completed';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> isComplete() async =>
      await _storage.read(key: _completeKey) == 'true';

  @override
  Future<void> markComplete() =>
      _storage.write(key: _completeKey, value: 'true');
}

final onboardingTourStoreProvider = Provider<OnboardingTourStore>(
  (ref) => SecureOnboardingTourStore(),
);

final onboardingTourProvider =
    NotifierProvider<OnboardingTourController, OnboardingTourState>(
      OnboardingTourController.new,
    );

class OnboardingTourController extends Notifier<OnboardingTourState> {
  @override
  OnboardingTourState build() {
    scheduleMicrotask(_restore);
    return const OnboardingTourState();
  }

  Future<void> _restore() async {
    try {
      final complete = await ref.read(onboardingTourStoreProvider).isComplete();
      state = OnboardingTourState(
        initialized: true,
        step: complete
            ? OnboardingTourStep.inactive
            : OnboardingTourStep.mainMenu,
      );
    } catch (_) {
      // Güvenli depolama kullanılamıyorsa tur arayüzü ana akışı engellemez.
      state = const OnboardingTourState(initialized: true);
    }
  }

  void onlineBattleOpened() {
    if (state.step != OnboardingTourStep.mainMenu) return;
    state = const OnboardingTourState(
      initialized: true,
      step: OnboardingTourStep.modulePlacement,
    );
  }

  void modulePlaced() {
    if (state.step != OnboardingTourStep.modulePlacement) return;
    state = const OnboardingTourState(
      initialized: true,
      step: OnboardingTourStep.validateAndBattle,
    );
  }

  void battleViewed() {
    if (state.step != OnboardingTourStep.validateAndBattle) return;
    state = const OnboardingTourState(
      initialized: true,
      step: OnboardingTourStep.settings,
    );
  }

  void settingsOpened() {
    if (state.step != OnboardingTourStep.settings) return;
    state = const OnboardingTourState(
      initialized: true,
      step: OnboardingTourStep.sound,
    );
  }

  void complete() {
    state = const OnboardingTourState(initialized: true);
    unawaited(ref.read(onboardingTourStoreProvider).markComplete());
  }
}
