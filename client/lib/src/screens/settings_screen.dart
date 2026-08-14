import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/relay_features.dart';
import '../l10n/relay_strings.dart';
import '../navigation/navigation_actions.dart';
import '../state/app_settings.dart';
import '../state/onboarding_tour.dart';
import '../state/product_telemetry.dart';
import '../theme/relay_theme.dart';
import 'alpha_feedback_screen.dart';
import 'editor_screen.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/onboarding_coach_banner.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);
    final tour = ref.watch(onboardingTourProvider);
    final strings = RelayStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 224,
        leading: const AppHeaderProfile(),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: AppHeaderTitle(pageTitle: strings.settingsTitle),
        actions: const [AppHeaderActions(), SizedBox(width: 8)],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  18,
                  6,
                  18,
                  tour.step == OnboardingTourStep.sound ? 126 : 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: SwitchListTile(
                          key: const ValueKey('settings-replay-sound'),
                          value: settings.replaySoundEnabled,
                          onChanged: (enabled) {
                            controller.setReplaySoundEnabled(enabled);
                            if (tour.step == OnboardingTourStep.sound) {
                              ref
                                  .read(onboardingTourProvider.notifier)
                                  .complete();
                            }
                          },
                          secondary: Icon(
                            settings.replaySoundEnabled
                                ? Icons.volume_up
                                : Icons.volume_off,
                            color: RelayColors.cyan,
                          ),
                          title: Text(
                            strings.replaySound,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            strings.replaySoundSubtitle,
                            style: const TextStyle(
                              color: RelayColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.speed,
                                    color: RelayColors.cyan,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    strings.replaySpeed,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<double>(
                                  key: const ValueKey('settings-replay-speed'),
                                  segments: const [
                                    ButtonSegment(
                                      value: 0.75,
                                      label: Text('0.75×'),
                                    ),
                                    ButtonSegment(value: 1, label: Text('1×')),
                                    ButtonSegment(
                                      value: 1.25,
                                      label: Text('1.25×'),
                                    ),
                                    ButtonSegment(
                                      value: 1.5,
                                      label: Text('1.5×'),
                                    ),
                                    ButtonSegment(value: 2, label: Text('2×')),
                                  ],
                                  selected: {settings.replaySpeed},
                                  onSelectionChanged: (selection) {
                                    controller.setReplaySpeed(selection.single);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.palette_outlined,
                            color: RelayColors.amber,
                          ),
                          title: Text(
                            strings.appearance,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            strings.appearanceSubtitle,
                            style: const TextStyle(
                              color: RelayColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.language_outlined,
                                    color: RelayColors.cyan,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          strings.language,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          strings.languageSubtitle,
                                          style: const TextStyle(
                                            color: RelayColors.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<AppLanguage>(
                                  key: const ValueKey('settings-language'),
                                  segments: const [
                                    ButtonSegment(
                                      value: AppLanguage.turkish,
                                      label: Text('Türkçe'),
                                    ),
                                    ButtonSegment(
                                      value: AppLanguage.english,
                                      label: Text('English'),
                                    ),
                                  ],
                                  selected: {settings.language},
                                  onSelectionChanged: (selection) {
                                    controller.setLanguage(selection.single);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: SwitchListTile(
                          key: const ValueKey('settings-telemetry'),
                          value: settings.telemetryEnabled,
                          onChanged: controller.setTelemetryEnabled,
                          secondary: const Icon(
                            Icons.query_stats_outlined,
                            color: RelayColors.violet,
                          ),
                          title: Text(
                            strings.telemetry,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            strings.telemetrySubtitle,
                            style: const TextStyle(
                              color: RelayColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          key: const ValueKey('settings-alpha-feedback'),
                          leading: const Icon(
                            Icons.feedback_outlined,
                            color: RelayColors.cyan,
                          ),
                          title: Text(
                            strings.alphaFeedback,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            strings.alphaFeedbackSubtitle,
                            style: const TextStyle(
                              color: RelayColors.muted,
                              fontSize: 11,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const AlphaFeedbackScreen(),
                            ),
                          ),
                        ),
                      ),
                      if (RelayFeatures.sandboxLab) ...[
                        const SizedBox(height: 12),
                        Card(
                          child: ListTile(
                            key: const ValueKey('settings-sandbox-lab'),
                            leading: const Icon(
                              Icons.science_outlined,
                              color: RelayColors.lime,
                            ),
                            title: Text(
                              strings.sandbox,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              strings.sandboxSubtitle,
                              style: const TextStyle(
                                color: RelayColors.muted,
                                fontSize: 11,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ref
                                  .read(productTelemetryProvider)
                                  .track('sandbox_opened');
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => const EditorScreen(
                                    mode: EditorMode.training,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                        key: const ValueKey('settings-back-button'),
                        onPressed: () => returnToMainMenu(context),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(strings.backToMain),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (tour.step == OnboardingTourStep.sound)
            Align(
              alignment: Alignment.bottomCenter,
              child: OnboardingCoachBanner(
                stepLabel: '4/4',
                title: 'SESÄ°NÄ° AYARLA',
                message:
                    'YukarÄ±daki ses anahtarÄ±nÄ± deneyin. SeÃ§iminiz kaydedilir ve tur tamamlanÄ±r.',
                onSkip: ref.read(onboardingTourProvider.notifier).complete,
                icon: Icons.volume_up_outlined,
              ),
            ),
        ],
      ),
    );
  }
}
