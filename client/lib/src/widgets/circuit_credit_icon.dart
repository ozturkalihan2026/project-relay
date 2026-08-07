import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';

/// Project Relay'in tekil Devre Kredisi amblemi.
///
/// Üst bar, ödül bildirimi ve mağaza fiyatlarında aynı sembol kullanılır.
class CircuitCreditGlyph extends StatelessWidget {
  const CircuitCreditGlyph({
    this.size = 20,
    this.glow = false,
    super.key,
  });

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              RelayColors.amber.withValues(alpha: 0.26),
              RelayColors.amber.withValues(alpha: 0.07),
            ],
          ),
          border: Border.all(
            color: RelayColors.amber.withValues(alpha: 0.82),
            width: 1.2,
          ),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: RelayColors.amber.withValues(alpha: 0.28),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            Icons.memory_rounded,
            size: size * 0.50,
            color: RelayColors.amber,
          ),
        ),
      ),
    );
  }
}
