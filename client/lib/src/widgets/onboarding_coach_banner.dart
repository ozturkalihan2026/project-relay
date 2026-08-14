import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';

class OnboardingCoachBanner extends StatelessWidget {
  const OnboardingCoachBanner({
    required this.stepLabel,
    required this.title,
    required this.message,
    required this.onSkip,
    this.icon = Icons.touch_app_outlined,
    super.key,
  });

  final String stepLabel;
  final String title;
  final String message;
  final VoidCallback onSkip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          key: const ValueKey('onboarding-coach-banner'),
          elevation: 18,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
            decoration: RelayDecorations.panel(
              accent: RelayColors.amber,
              soft: true,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: RelayColors.amber.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(icon, color: RelayColors.amber, size: 24),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$stepLabel • $title',
                        style: const TextStyle(
                          color: RelayColors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: const TextStyle(fontSize: 11, height: 1.3),
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: onSkip, child: const Text('ATLA')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
