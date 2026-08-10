import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/relay_models.dart';

class BattleCameraRig extends StatefulWidget {
  const BattleCameraRig({
    required this.events,
    required this.match,
    required this.child,
    super.key,
  });

  final ValueListenable<List<BattleEvent>> events;
  final MatchResponse match;
  final Widget child;

  @override
  State<BattleCameraRig> createState() => _BattleCameraRigState();
}

class _BattleCameraRigState extends State<BattleCameraRig>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _strength = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    widget.events.addListener(_handle);
  }

  @override
  void didUpdateWidget(covariant BattleCameraRig oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events == widget.events) return;
    oldWidget.events.removeListener(_handle);
    widget.events.addListener(_handle);
  }

  void _handle() {
    final events = widget.events.value;
    if (events.isEmpty) return;
    _strength = events.fold<double>(0, (value, event) {
      final next = switch (event.type) {
        'core_damage' => event.tick >= widget.match.result.ticks ? 1.35 : 1.0,
        'destroyed' => 0.78,
        'attack' => _isPulse(event.actorId) ? 0.58 : 0.24,
        'shield_absorb' => 0.30,
        _ => 0.12,
      };
      return math.max(value, next);
    });
    _controller.forward(from: 0);
  }

  bool _isPulse(String id) {
    for (final module in [...widget.match.playerBoard.modules, ...widget.match.opponentBoard.modules]) {
      if (module.id == id) return module.kind == ModuleKind.pulseCannon;
    }
    return false;
  }

  @override
  void dispose() {
    widget.events.removeListener(_handle);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final fade = (1 - t).clamp(0.0, 1.0);
        final shake = math.sin(t * math.pi * 7) * 4.5 * _strength * fade;
        final zoom = 1 + math.sin(t * math.pi) * 0.018 * _strength;
        return Transform.translate(
          offset: Offset(shake, -shake * 0.28),
          child: Transform.scale(scale: zoom, child: child),
        );
      },
    );
  }
}
