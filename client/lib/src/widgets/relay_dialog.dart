import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';

class RelayConfirmDialog extends StatelessWidget {
  const RelayConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = false,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? RelayColors.coral : RelayColors.mint;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: RelayDecorations.panel(accent: accent),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withValues(alpha: 0.55)),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.16),
                          blurRadius: 18,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Icon(
                      destructive ? Icons.warning_amber_rounded : Icons.hub_outlined,
                      color: accent,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: RelayColors.background.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: RelayColors.cyan.withValues(alpha: 0.13),
                  ),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: RelayColors.white,
                    height: 1.45,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('VAZGEÇ'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: destructive
                          ? FilledButton.styleFrom(
                              backgroundColor: RelayColors.coral,
                              foregroundColor: Colors.white,
                            )
                          : FilledButton.styleFrom(
                              backgroundColor: RelayColors.mint,
                              foregroundColor: RelayColors.background,
                            ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
