import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';

class AnimatedCircuitBackground extends StatefulWidget {
  const AnimatedCircuitBackground({required this.child, this.pathCount = 16, super.key});
  final Widget child;
  final int pathCount;
  @override
  State<AnimatedCircuitBackground> createState() => _AnimatedCircuitBackgroundState();
}

class _AnimatedCircuitBackgroundState extends State<AnimatedCircuitBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _restartTimer;
  bool _motionDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 7800))..addStatusListener(_handleStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_motionDisabled == disabled && (_controller.isAnimating || disabled || _controller.value > 0)) return;
    _motionDisabled = disabled;
    _restartTimer?.cancel();
    if (disabled) {
      _controller.stop();
      _controller.value = 0.42;
    } else {
      _controller.forward(from: 0);
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _motionDisabled || !mounted) return;
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 520), () {
      if (mounted && !_motionDisabled) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _restartTimer?.cancel();
    _controller..removeStatusListener(_handleStatus)..dispose();
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
            painter: _CircuitCurrentPainter(phase: _controller.value, pathCount: widget.pathCount),
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
    final core = Offset(size.width * 0.86, size.height * 0.48);
    final coreRadius = math.min(size.width, size.height) * 0.075;
    final colors = <Color>[RelayColors.cyan, RelayColors.mint, RelayColors.violet, RelayColors.amber, RelayColors.electricBlue];

    for (var index = 0; index < pathCount; index++) {
      final path = _pathFor(index, size, core, coreRadius);
      final color = colors[index % colors.length];
      canvas.drawPath(path, Paint()..style=PaintingStyle.stroke..strokeWidth=1..strokeCap=StrokeCap.round..color=color.withValues(alpha:0.08));
      final metrics = path.computeMetrics().toList(growable:false);
      if (metrics.isEmpty) continue;
      final metric=metrics.first;
      final progress=(phase + index*0.113)%1.0;
      final head=metric.length*progress;
      final start=math.max(0.0, head-42).toDouble();
      final end=math.min(metric.length, head+10).toDouble();
      if (end<=start) continue;
      final pulse=metric.extractPath(start,end);
      canvas.drawPath(pulse, Paint()..style=PaintingStyle.stroke..strokeWidth=7..strokeCap=StrokeCap.round..color=color.withValues(alpha:0.06)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
      canvas.drawPath(pulse, Paint()..style=PaintingStyle.stroke..strokeWidth=1.8..strokeCap=StrokeCap.round..color=color.withValues(alpha:0.68));
      final tangent=metric.getTangentForOffset(head.clamp(0.0,metric.length).toDouble());
      if (tangent!=null) canvas.drawCircle(tangent.position,2.3,Paint()..color=color.withValues(alpha:0.82));
    }
    _drawCore(canvas, core, coreRadius);
  }

  Path _pathFor(int index, Size size, Offset core, double radius) {
    final row=((index*37)%92)/100.0;
    final startX=size.width*(0.01+((index*17)%34)/100.0);
    final startY=size.height*(0.06+row*0.88);
    final approachX=core.dx-radius*(1.05+(index%3)*0.18);
    final midX=startX+(approachX-startX)*(0.45+(index%4)*0.08);
    final targetY=core.dy + ((index%7)-3)*radius*0.18;
    return Path()
      ..moveTo(startX,startY)
      ..lineTo(midX,startY)
      ..lineTo(midX,targetY)
      ..lineTo(approachX,targetY);
  }

  void _drawCore(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius*1.42, Paint()..color=RelayColors.violet.withValues(alpha:0.035)..maskFilter=const MaskFilter.blur(BlurStyle.normal,24));
    canvas.drawCircle(center, radius*1.08, Paint()..style=PaintingStyle.stroke..strokeWidth=1.3..color=RelayColors.cyan.withValues(alpha:0.22));
    canvas.drawCircle(center, radius*0.82, Paint()..shader=const RadialGradient(colors:[Color(0x5538E8FF),Color(0x221C4C68),Color(0x00101725)]).createShader(Rect.fromCircle(center:center,radius:radius*0.82)));
    canvas.drawCircle(center, radius*0.52, Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=RelayColors.cyan.withValues(alpha:0.65));
    canvas.drawCircle(center, radius*0.18, Paint()..color=RelayColors.cyan.withValues(alpha:0.75)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
    for (var i=0;i<4;i++) {
      final angle=math.pi/2*i;
      final p=Offset(center.dx+math.cos(angle)*radius*0.86, center.dy+math.sin(angle)*radius*0.86);
      canvas.drawCircle(p,3.3,Paint()..color=RelayColors.amber.withValues(alpha:0.82));
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitCurrentPainter oldDelegate) => oldDelegate.phase!=phase || oldDelegate.pathCount!=pathCount;
}
