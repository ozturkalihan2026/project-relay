import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/relay_theme.dart';

/// Lightweight arena ambience that stays independent from the deterministic
/// replay state. It adds depth without obscuring modules or combat telemetry.
class BattleArenaAtmosphere extends StatefulWidget {
  const BattleArenaAtmosphere({
    required this.events,
    required this.child,
    super.key,
  });

  final ValueListenable<List<BattleEvent>> events;
  final Widget child;

  @override
  State<BattleArenaAtmosphere> createState() => _BattleArenaAtmosphereState();
}

class _BattleArenaAtmosphereState extends State<BattleArenaAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Color _impactColor = RelayColors.cyan;
  double _impactStrength = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    widget.events.addListener(_onEvents);
  }

  @override
  void didUpdateWidget(covariant BattleArenaAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events == widget.events) return;
    oldWidget.events.removeListener(_onEvents);
    widget.events.addListener(_onEvents);
  }

  void _onEvents() {
    final events = widget.events.value;
    if (events.isEmpty) return;
    setState(() {
      _impactStrength =
          events.any(
            (event) => event.type == 'core_damage' || event.type == 'destroyed',
          )
          ? 1
          : 0.45;
      _impactColor =
          events.any(
            (event) => event.type == 'shield' || event.type == 'shield_absorb',
          )
          ? RelayColors.electricBlue
          : events.any((event) => event.type == 'repair')
          ? RelayColors.mint
          : RelayColors.coral;
    });
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (mounted) setState(() => _impactStrength = 0);
    });
  }

  @override
  void dispose() {
    widget.events.removeListener(_onEvents);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          child!,
          IgnorePointer(
            child: CustomPaint(
              painter: _ArenaAtmospherePainter(
                phase: _controller.value,
                impactColor: _impactColor,
                impactStrength: _impactStrength,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArenaAtmospherePainter extends CustomPainter {
  const _ArenaAtmospherePainter({
    required this.phase,
    required this.impactColor,
    required this.impactStrength,
  });

  final double phase;
  final Color impactColor;
  final double impactStrength;

  @override
  void paint(Canvas canvas, Size size) {
    final scanY = (phase * 1.35 % 1) * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, scanY, size.width, 2),
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.transparent, Color(0x1653E5FF), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, scanY, size.width, 2)),
    );

    for (var i = 0; i < 18; i++) {
      final seed = i * 0.173;
      final x = ((seed + phase * (0.025 + i % 3 * 0.009)) % 1) * size.width;
      final y =
          ((seed * 4.7 + phase * (0.12 + i % 4 * 0.02)) % 1) * size.height;
      final pulse = 0.3 + 0.7 * math.sin((phase + seed) * math.pi * 2).abs();
      canvas.drawCircle(
        Offset(x, y),
        0.7 + (i % 3) * 0.45,
        Paint()..color = RelayColors.cyan.withValues(alpha: 0.09 * pulse),
      );
    }

    final vignette = RadialGradient(
      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.20)],
      stops: const [0.68, 1],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = vignette.createShader(Offset.zero & size),
    );

    if (impactStrength > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.transparent,
              impactColor.withValues(alpha: 0.16 * impactStrength),
            ],
            stops: const [0.42, 1],
          ).createShader(Offset.zero & size),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArenaAtmospherePainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.impactStrength != impactStrength ||
      oldDelegate.impactColor != impactColor;
}
