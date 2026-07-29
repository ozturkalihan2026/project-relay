import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';

class CareerScreen extends StatelessWidget {
  const CareerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'KARİYER',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
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
                    children: [
                      const Icon(
                        Icons.route_outlined,
                        color: RelayColors.amber,
                        size: 54,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'KARİYER HAZIRLANIYOR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Görev tabanlı ilerleme, öğretici karşılaşmalar ve '
                        'koşul hedefleri yol haritasındaki kariyer sürümünde '
                        'açılacak. Bu ekran şimdilik gerçek ödül veya ilerleme '
                        'varmış gibi davranmaz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: RelayColors.muted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CareerTag(
                            icon: Icons.flag_outlined,
                            label: 'GÖREVLER',
                          ),
                          _CareerTag(
                            icon: Icons.school_outlined,
                            label: 'ÖĞRETİCİ',
                          ),
                          _CareerTag(
                            icon: Icons.alt_route,
                            label: 'KARŞI STRATEJİ',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        key: const ValueKey('career-back-button'),
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

class _CareerTag extends StatelessWidget {
  const _CareerTag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: RelayColors.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF315E6B)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: RelayColors.amber, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
