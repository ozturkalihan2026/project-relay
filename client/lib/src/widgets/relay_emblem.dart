import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';

class RelayEmblem extends StatelessWidget {
  const RelayEmblem({
    this.size = 48,
    this.accent = RelayColors.cyan,
    this.secondary = RelayColors.violet,
    this.glow = true,
    super.key,
  });

  final double size;
  final Color accent;
  final Color secondary;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: RelayEmblemPainter(
          accent: accent,
          secondary: secondary,
          glow: glow,
        ),
      ),
    );
  }
}

class RelayEmblemPainter extends CustomPainter {
  const RelayEmblemPainter({
    this.accent = RelayColors.cyan,
    this.secondary = RelayColors.violet,
    this.glow = true,
    this.opacity = 1,
  });

  final Color accent;
  final Color secondary;
  final bool glow;
  final double opacity;

  static List<Offset> portOffsets(double radius) {
    const spread = 0.30;
    return <Offset>[
      Offset(-radius, -radius * spread),
      Offset(-radius, radius * spread),
      Offset(radius, -radius * spread),
      Offset(radius, radius * spread),
      Offset(-radius * spread, -radius),
      Offset(radius * spread, -radius),
      Offset(-radius * spread, radius),
      Offset(radius * spread, radius),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;
    drawEmblem(
      canvas,
      center: center,
      radius: radius,
      accent: accent,
      secondary: secondary,
      glow: glow,
      opacity: opacity,
    );
  }

  static void drawEmblem(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color accent,
    required Color secondary,
    bool glow = true,
    double opacity = 1,
  }) {
    final shellRect = Rect.fromCenter(
      center: center,
      width: radius * 1.42,
      height: radius * 1.42,
    );
    final coreRect = Rect.fromCenter(
      center: center,
      width: radius * 0.72,
      height: radius * 0.72,
    );

    if (glow) {
      canvas.drawCircle(
        center,
        radius * 1.20,
        Paint()
          ..color = secondary.withValues(alpha: 0.10 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
      canvas.drawCircle(
        center,
        radius * 0.92,
        Paint()
          ..color = accent.withValues(alpha: 0.12 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    final shellPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            accent.withValues(alpha: 0.22 * opacity),
            RelayColors.surfaceSoft,
          ),
          Color.alphaBlend(
            secondary.withValues(alpha: 0.18 * opacity),
            RelayColors.surface,
          ),
        ],
      ).createShader(shellRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shellRect, Radius.circular(radius * 0.22)),
      shellPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shellRect, Radius.circular(radius * 0.22)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, radius * 0.045)
        ..color = accent.withValues(alpha: 0.82 * opacity),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(coreRect, Radius.circular(radius * 0.11)),
      Paint()
        ..color = RelayColors.background.withValues(alpha: 0.70 * opacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(coreRect, Radius.circular(radius * 0.11)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, radius * 0.035)
        ..color = accent.withValues(alpha: 0.95 * opacity),
    );

    final innerRect = Rect.fromCenter(
      center: center,
      width: radius * 0.30,
      height: radius * 0.30,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(radius * 0.055)),
      Paint()..color = accent.withValues(alpha: 0.88 * opacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: radius * 0.15,
          height: radius * 0.15,
        ),
        Radius.circular(radius * 0.03),
      ),
      Paint()..color = RelayColors.background.withValues(alpha: 0.92 * opacity),
    );

    final ports = portOffsets(radius);
    for (var index = 0; index < ports.length; index++) {
      final offset = ports[index];
      final isHorizontal = offset.dx.abs() > offset.dy.abs();
      final outward = isHorizontal
          ? Offset(offset.dx.sign * radius * 0.22, 0)
          : Offset(0, offset.dy.sign * radius * 0.22);
      final inner = center + offset * 0.72;
      final outer = center + offset + outward;
      final portColor = index.isEven ? accent : secondary;
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1.2, radius * 0.045)
          ..color = portColor.withValues(alpha: 0.86 * opacity),
      );
      canvas.drawCircle(
        outer,
        math.max(1.8, radius * 0.065),
        Paint()..color = portColor.withValues(alpha: 0.95 * opacity),
      );
      if (glow) {
        canvas.drawCircle(
          outer,
          math.max(3.6, radius * 0.12),
          Paint()
            ..color = portColor.withValues(alpha: 0.15 * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant RelayEmblemPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.secondary != secondary ||
        oldDelegate.glow != glow ||
        oldDelegate.opacity != opacity;
  }
}
