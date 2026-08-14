import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/state/onboarding_tour.dart';

void main() {
  test('tamamlanmamış ilk kullanım turunu sırasıyla ilerletir', () async {
    final store = _MemoryOnboardingTourStore();
    final container = ProviderContainer(
      overrides: [onboardingTourStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    container.read(onboardingTourProvider);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(onboardingTourProvider).step,
      OnboardingTourStep.mainMenu,
    );

    final controller = container.read(onboardingTourProvider.notifier);
    controller.onlineBattleOpened();
    expect(
      container.read(onboardingTourProvider).step,
      OnboardingTourStep.modulePlacement,
    );

    controller.modulePlaced();
    expect(
      container.read(onboardingTourProvider).step,
      OnboardingTourStep.validateAndBattle,
    );

    controller.battleViewed();
    expect(
      container.read(onboardingTourProvider).step,
      OnboardingTourStep.settings,
    );

    controller.settingsOpened();
    expect(
      container.read(onboardingTourProvider).step,
      OnboardingTourStep.sound,
    );

    controller.complete();
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(onboardingTourProvider).step,
      OnboardingTourStep.inactive,
    );
    expect(store.completed, isTrue);
  });

  test('tamamlanmış turu yeniden göstermez', () async {
    final store = _MemoryOnboardingTourStore(completed: true);
    final container = ProviderContainer(
      overrides: [onboardingTourStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    container.read(onboardingTourProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(onboardingTourProvider);
    expect(state.initialized, isTrue);
    expect(state.step, OnboardingTourStep.inactive);
  });
}

class _MemoryOnboardingTourStore implements OnboardingTourStore {
  _MemoryOnboardingTourStore({this.completed = false});

  bool completed;

  @override
  Future<bool> isComplete() async => completed;

  @override
  Future<void> markComplete() async => completed = true;
}
