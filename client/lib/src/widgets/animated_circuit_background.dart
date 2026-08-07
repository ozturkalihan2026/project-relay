import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';

/// Ana merkez için düşük yoğunluklu, devre yolları üzerinde akan enerji zemini.
///
/// Animasyon sürekli bir ticker yerine kısa döngüler ve aradaki küçük beklemelerle
/// ilerler. Böylece ekran canlı kalırken widget testlerinin `pumpAndSettle`
/// akışı sonsuz animasyona takılmaz.
class AnimatedCircuitBackground extends StatefulWidget {
  const AnimatedCircuitBackground({
    required this.child,
    this.pathCount = 14,
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
  Timer? _restartTimer;
  bool _motionDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    )..addStatusListener(_handleStatus);
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
    _restartTimer?.cancel();
    if (disabled) {
      _controller.stop();
      _controller.value = 0.34;
    } else {
      _controller.forward(from: 0);
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _motionDisabled || !mounted) {
      return;
    }
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted && !_motionDisabled) {
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _restartTimer?.cancel();
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
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
  const _CircuitCurrentPainter({
    required this.phase,
    required this.pathCount,
  });

  final double phase;
  final int pathCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final colors = <Color>[
      RelayColors.cyan,
      RelayColors.mint,
      RelayColors.violet,
      RelayColors.amber,
    ];

    for (var index = 0; index < pathCount; index++) {
      final path = _pathFor(index, size);
      final color = colors[index % colors.length];
      final tracePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.075);
      canvas.drawPath(path, tracePaint);

      final metrics = path.computeMetrics().toList(growable: false);
      if (metrics.isEmpty) continue;
      final metric = metrics.first;
      final progress = (phase + index * 0.137) % 1.0;
      final head = metric.length * progress;
      final start = math.max(0.0, head - 34).toDouble();
      final end = math.min(metric.length, head + 9).toDouble();
      if (end <= start) continue;

      final pulse = metric.extractPath(start, end);
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.055)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.62);
      canvas
        ..drawPath(pulse, glowPaint)
        ..drawPath(pulse, corePaint);

      final tangent = metric.getTangentForOffset(
        head.clamp(0.0, metric.length).toDouble(),
      );
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          2.2,
          Paint()..color = color.withValues(alpha: 0.78),
        );
      }
    }
  }

  Path _pathFor(int index, Size size) {
    final row = ((index * 37) % 88) / 100.0;
    final startRatio = ((index * 19) % 28) / 100.0;
    final lengthRatio = 0.34 + ((index * 11) % 31) / 100.0;
    final y = size.height * (0.06 + row * 0.93);
    final startX = size.width * startRatio;
    final endX = math
        .min(size.width * 0.98, startX + size.width * lengthRatio)
        .toDouble();
    final middleX = startX + (endX - startX) * (0.34 + (index % 3) * 0.13);
    final jog = (index.isEven ? 1.0 : -1.0) *
        size.height * (0.018 + (index % 4) * 0.007);
    final finalY = (y + jog).clamp(0.0, size.height).toDouble();

    return Path()
      ..moveTo(startX, y)
      ..lineTo(middleX, y)
      ..lineTo(middleX, finalY)
      ..lineTo(endX, finalY);
  }

  @override
  bool shouldRepaint(covariant _CircuitCurrentPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.pathCount != pathCount;
  }
}
