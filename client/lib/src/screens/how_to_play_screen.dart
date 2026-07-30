import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../theme/relay_theme.dart';
import '../widgets/game_manual.dart';

class HowToPlayScreen extends ConsumerWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogs = ref.watch(catalogsProvider);
    return catalogs.when(
      data: (bundle) => GameManualScreen(modules: bundle.modules),
      loading: () => const _ManualCatalogState(
        icon: Icons.sync,
        title: 'OYUN EL KİTABI YÜKLENİYOR',
        message: 'Güncel modül değerleri sunucudan alınıyor.',
      ),
      error: (error, _) => _ManualCatalogState(
        icon: Icons.cloud_off_outlined,
        title: 'EL KİTABI AÇILAMADI',
        message: 'Modül kataloğuna ulaşılamadı: $error',
        onRetry: () => ref.invalidate(catalogsProvider),
      ),
    );
  }
}

class _ManualCatalogState extends StatelessWidget {
  const _ManualCatalogState({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'NASIL OYNANIR',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: RelayColors.cyan, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: RelayColors.muted,
                          height: 1.4,
                        ),
                      ),
                      if (onRetry != null) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('YENİDEN DENE'),
                        ),
                      ],
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        key: const ValueKey('manual-loading-back-button'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('ANA MENÜYE DÖN'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
