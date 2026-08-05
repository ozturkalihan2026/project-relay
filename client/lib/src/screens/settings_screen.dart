import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/navigation_actions.dart';
import '../state/app_settings.dart';
import 'alpha_feedback_screen.dart';
import '../theme/relay_theme.dart';
import '../widgets/app_header_actions.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'AYARLAR',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        actions: const [
          AppHeaderActions(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: SwitchListTile(
                      key: const ValueKey('settings-replay-sound'),
                      value: settings.replaySoundEnabled,
                      onChanged: controller.setReplaySoundEnabled,
                      secondary: Icon(
                        settings.replaySoundEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: RelayColors.cyan,
                      ),
                      title: const Text(
                        'Savaş tekrarı sesi',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: const Text(
                        'Yeni savaş tekrarları bu ses tercihiyle başlar.',
                        style: TextStyle(
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
                          const Row(
                            children: [
                              Icon(
                                Icons.speed,
                                color: RelayColors.cyan,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Varsayılan tekrar hızı',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<double>(
                              key: const ValueKey(
                                'settings-replay-speed',
                              ),
                              segments: const [
                                ButtonSegment(
                                  value: 0.25,
                                  label: Text('0.25×'),
                                ),
                                ButtonSegment(
                                  value: 0.5,
                                  label: Text('0.5×'),
                                ),
                                ButtonSegment(
                                  value: 1,
                                  label: Text('1×'),
                                ),
                                ButtonSegment(
                                  value: 2,
                                  label: Text('2×'),
                                ),
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
                  const Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.palette_outlined,
                        color: RelayColors.amber,
                      ),
                      title: Text(
                        'Görünüm',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        'Yüksek kontrastlı koyu devre teması etkin.',
                        style: TextStyle(
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
                      title: const Text(
                        'Alfa geri bildirimi',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: const Text(
                        'Denge, hata ve arayüz geri bildirimlerini buradan gönder.',
                        style: TextStyle(
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
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    key: const ValueKey('settings-back-button'),
                    onPressed: () => returnToMainMenu(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('ANA MENÜYE DÖN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
