import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/replay_game.dart';
import '../models/relay_models.dart';
import '../theme/cosmetic_visuals.dart';
import '../theme/relay_theme.dart';

class ReplayAttackOverlay extends StatefulWidget {
  const ReplayAttackOverlay({
    required this.events,
    required this.match,
    this.leftVisuals = const EquippedVisuals.defaults(),
    this.rightVisuals = const EquippedVisuals.defaults(),
    super.key,
  });

  final ValueListenable<List<BattleEvent>> events;
  final MatchResponse match;
  final EquippedVisuals leftVisuals;
  final EquippedVisuals rightVisuals;

  @override
  State<ReplayAttackOverlay> createState() => _ReplayAttackOverlayState();
}

class _ReplayAttackOverlayState extends State<ReplayAttackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<BattleEvent> _events = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    widget.events.addListener(_handleEvents);
    _handleEvents();
  }

  @override
  void didUpdateWidget(covariant ReplayAttackOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events == widget.events) {
      return;
    }
    oldWidget.events.removeListener(_handleEvents);
    widget.events.addListener(_handleEvents);
    _handleEvents();
  }

  @override
  void dispose() {
    widget.events.removeListener(_handleEvents);
    _controller.dispose();
    super.dispose();
  }

  void _handleEvents() {
    _events = widget.events.value
        .where(
          (event) =>
              event.type == 'attack' ||
              event.type == 'core_damage' ||
              event.type == 'shield_absorb',
        )
        .toList(growable: false);
    if (_events.isEmpty) {
      _controller.reset();
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _AttackPainter(
              events: _events,
              match: widget.match,
              progress: Curves.easeOut.transform(_controller.value),
              leftVisuals: widget.leftVisuals,
              rightVisuals: widget.rightVisuals,
            ),
          );
        },
      ),
    );
  }
}

class _AttackPainter extends CustomPainter {
  const _AttackPainter({
    required this.events,
    required this.match,
    required this.progress,
    required this.leftVisuals,
    required this.rightVisuals,
  });

  final List<BattleEvent> events;
  final MatchResponse match;
  final double progress;
  final EquippedVisuals leftVisuals;
  final EquippedVisuals rightVisuals;

  @override
  void paint(Canvas canvas, Size size) {
    if (events.isEmpty || progress >= 1) {
      return;
    }
    final leftBoard = ReplayStageGeometry.leftBoard(size);
    final rightBoard = ReplayStageGeometry.rightBoard(size);
    final leftCore = leftBoard.center;
    final rightCore = rightBoard.center;

    for (final event in events) {
      _drawAttack(
        canvas,
        event,
        leftBoard: leftBoard,
        rightBoard: rightBoard,
        leftCore: leftCore,
        rightCore: rightCore,
      );
    }
  }

  void _drawAttack(
    Canvas canvas,
    BattleEvent event, {
    required Rect leftBoard,
    required Rect rightBoard,
    required Offset leftCore,
    required Offset rightCore,
  }) {
    final actorBoard =
        event.side == 'left' ? match.playerBoard : match.opponentBoard;
    final actorRect = event.side == 'left' ? leftBoard : rightBoard;
    final targetBoard =
        event.side == 'left' ? match.opponentBoard : match.playerBoard;
    final targetRect = event.side == 'left' ? rightBoard : leftBoard;
    final from = _modulePoint(event.actorId, actorBoard, actorRect) ??
        (event.side == 'left' ? leftCore : rightCore);
    final targetCore = event.side == 'left' ? rightCore : leftCore;
    final to = event.type == 'core_damage'
        ? targetCore
        : _modulePoint(event.targetId, targetBoard, targetRect) ??
            targetRect.center;
    final fade = (1 - progress).clamp(0.0, 1.0).toDouble();
    final sideVisuals = event.side == 'left' ? leftVisuals : rightVisuals;
    final color = event.type == 'shield_absorb'
        ? const Color(0xFF74A7FF)
        : sideVisuals.modules.attack;
    final head = Offset.lerp(from, to, progress)!;
    final tail = Offset.lerp(
      from,
      to,
      math.max(0.0, progress - 0.20),
    )!;

    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color.withValues(alpha: 0.16 * fade)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      tail,
      head,
      Paint()
        ..color = color.withValues(alpha: 0.94 * fade)
        ..strokeWidth = 3 + 4 * fade
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      head,
      5 + 5 * fade,
      Paint()..color = color.withValues(alpha: 0.92 * fade),
    );
  }

  Offset? _modulePoint(
    String? id,
    BoardDraft board,
    Rect rect,
  ) {
    if (id == null) {
      return null;
    }
    for (final module in board.modules) {
      if (module.id == id) {
        final cellSize = rect.width / 4;
        return Offset(
          rect.left + (module.column + 0.5) * cellSize,
          rect.top + (module.row + 0.5) * cellSize,
        );
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant _AttackPainter oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.progress != progress ||
        oldDelegate.match != match ||
        oldDelegate.leftVisuals.modules.id != leftVisuals.modules.id ||
        oldDelegate.rightVisuals.modules.id != rightVisuals.modules.id;
  }
}
