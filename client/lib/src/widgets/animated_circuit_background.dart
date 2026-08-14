import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';
import 'relay_emblem.dart';

class AnimatedCircuitBackground extends StatefulWidget {
  const AnimatedCircuitBackground({
    required this.child,
    this.pathCount = 16,
    super.key,
  });
  final Widget child;
  final int pathCount;
  @override
  State<AnimatedCircuitBackground> createState() =>
      _AnimatedCircuitBackgroundState();
}

class _AnimatedCircuitBackgroundState extends State<AnimatedCircuitBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _motionDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_motionDisabled == disabled &&
        (_controller.isAnimating || disabled || _controller.value > 0)) {
      return;
    }
    _motionDisabled = disabled;
    if (disabled) {
      _controller.stop();
      _controller.value = 0.42;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: RelayDecorations.screenShell(),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            key: const ValueKey('animated-circuit-background'),
            painter: _CircuitCurrentPainter(
              phase: _controller.value,
              pathCount: widget.pathCount,
            ),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _CircuitCurrentPainter extends CustomPainter {
  const _CircuitCurrentPainter({required this.phase, required this.pathCount});
  final double phase;
  final int pathCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final emblemCenter = Offset(size.width * 0.86, size.height * 0.49);
    final emblemRadius = math.min(size.width, size.height) * 0.070;
    final ports = RelayEmblemPainter.portOffsets(emblemRadius)
        .map(
          (offset) => emblemCenter + offset + _outwardFor(offset, emblemRadius),
        )
        .toList(growable: false);
    final colors = <Color>[
      RelayColors.cyan,
      RelayColors.mint,
      RelayColors.electricBlue,
      RelayColors.amber,
      RelayColors.violet,
      RelayColors.coral,
    ];

    for (var index = 0; index < pathCount; index++) {
      final port = ports[index % ports.length];
      final path = _pathFor(index, size, port);
      final color = colors[index % colors.length];
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.095),
      );
      final metrics = path.computeMetrics().toList(growable: false);
      if (metrics.isEmpty) continue;
      final metric = metrics.first;
      final progress = (phase + index * 0.087) % 1.0;
      final head = metric.length * progress;
      final start = math.max(0.0, head - 46).toDouble();
      final end = math.min(metric.length, head + 12).toDouble();
      if (end <= start) continue;
      final pulse = metric.extractPath(start, end);
      canvas.drawPath(
        pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.065)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
      canvas.drawPath(
        pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.9
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.74),
      );
      final tangent = metric.getTangentForOffset(
        head.clamp(0.0, metric.length).toDouble(),
      );
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          2.5,
          Paint()..color = color.withValues(alpha: 0.90),
        );
      }
    }

    RelayEmblemPainter.drawEmblem(
      canvas,
      center: emblemCenter,
      radius: emblemRadius,
      accent: RelayColors.cyan,
      secondary: RelayColors.violet,
      glow: true,
      opacity: 0.58,
    );
  }

  Offset _outwardFor(Offset offset, double radius) {
    final horizontal = offset.dx.abs() > offset.dy.abs();
    return horizontal
        ? Offset(offset.dx.sign * radius * 0.22, 0)
        : Offset(0, offset.dy.sign * radius * 0.22);
  }

  Path _pathFor(int index, Size size, Offset target) {
    final side = index % 4;
    late Offset start;
    if (side == 0) {
      start = Offset(
        size.width * (0.015 + ((index * 13) % 22) / 100),
        size.height * (0.08 + ((index * 29) % 82) / 100),
      );
    } else if (side == 1) {
      start = Offset(
        size.width * (0.18 + ((index * 17) % 38) / 100),
        size.height * 0.04,
      );
    } else if (side == 2) {
      start = Offset(
        size.width * (0.04 + ((index * 11) % 48) / 100),
        size.height * 0.94,
      );
    } else {
      start = Offset(
        size.width * (0.08 + ((index * 19) % 45) / 100),
        size.height * (0.10 + ((index * 31) % 76) / 100),
      );
    }

    final elbowX =
        start.dx + (target.dx - start.dx) * (0.40 + (index % 4) * 0.09);
    final secondX = target.dx - size.width * (0.025 + (index % 3) * 0.008);
    return Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(elbowX, start.dy)
      ..lineTo(elbowX, target.dy)
      ..lineTo(secondX, target.dy)
      ..lineTo(target.dx, target.dy);
  }

  @override
  bool shouldRepaint(covariant _CircuitCurrentPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.pathCount != pathCount;
}
