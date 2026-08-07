import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/replay_game.dart';
import '../models/relay_models.dart';
import '../theme/cosmetic_visuals.dart';

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
      duration: const Duration(milliseconds: 940),
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
              event.type == 'shield_absorb' ||
              event.type == 'shield' ||
              event.type == 'repair' ||
              event.type == 'recovered' ||
              event.type == 'destroyed' ||
              event.type == 'overheat' ||
              event.type == 'cool' ||
              event.type == 'energy_starved',
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
    final targetOnEnemy = event.type == 'attack' ||
        event.type == 'core_damage' ||
        event.type == 'shield_absorb' ||
        event.type == 'destroyed';
    final targetBoard = targetOnEnemy
        ? (event.side == 'left' ? match.opponentBoard : match.playerBoard)
        : actorBoard;
    final targetRect = targetOnEnemy
        ? (event.side == 'left' ? rightBoard : leftBoard)
        : actorRect;
    final from = _modulePoint(event.actorId, actorBoard, actorRect) ??
        (event.side == 'left' ? leftCore : rightCore);
    final targetCore = event.side == 'left' ? rightCore : leftCore;
    final to = event.type == 'core_damage'
        ? targetCore
        : _modulePoint(event.targetId, targetBoard, targetRect) ?? from;
    final fade = (1 - progress).clamp(0.0, 1.0).toDouble();
    final sideVisuals = event.side == 'left' ? leftVisuals : rightVisuals;
    final color = switch (event.type) {
      'shield' || 'shield_absorb' => const Color(0xFF74A7FF),
      'repair' || 'recovered' => const Color(0xFF72F0B7),
      'destroyed' => const Color(0xFFFF7A7A),
      'overheat' => const Color(0xFFFFD166),
      'cool' => const Color(0xFF46E7FF),
      'energy_starved' => const Color(0xFFB092FF),
      _ => sideVisuals.modules.attack,
    };
    final isBeam = event.type == 'attack' || event.type == 'core_damage';

    if (isBeam) {
      final easedHead = Curves.easeOutCubic.transform(progress);
      final head = Offset.lerp(from, to, easedHead)!;
      final tail = Offset.lerp(
        from,
        to,
        math.max(0.0, easedHead - 0.23),
      )!;
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.32 * fade)
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawLine(tail, head, glowPaint);
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..color = color.withValues(alpha: 0.96 * fade)
          ..strokeWidth = 3.2 + 2.6 * fade
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        head,
        5.5 + 4.5 * fade,
        Paint()..color = color.withValues(alpha: 0.96 * fade),
      );
      if (progress > 0.58) {
        final impactProgress = ((progress - 0.58) / 0.42).clamp(0.0, 1.0).toDouble();
        _drawImpactBurst(
          canvas,
          to,
          color,
          impactProgress,
          fade,
        );
        _drawFloatingLabel(
          canvas,
          event.type == 'core_damage'
              ? '-${event.amount.toStringAsFixed(0)} ÇEKİRDEK'
              : '-${event.amount.toStringAsFixed(0)}',
          to + Offset(0, -18 - impactProgress * 14),
          color,
          fade * (1 - impactProgress * 0.45),
        );
      }
      return;
    }

    final ringProgress = Curves.easeOut.transform(progress);
    final radius = 10 + 30 * ringProgress;
    canvas.drawCircle(
      to,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.72 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );
    canvas.drawCircle(
      to,
      math.max(4.0, radius * 0.52),
      Paint()
        ..color = color.withValues(alpha: 0.15 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final label = switch (event.type) {
      'shield' => 'KALKAN',
      'shield_absorb' => 'EMİLDİ',
      'repair' => '+${event.amount.toStringAsFixed(0)} ONARIM',
      'recovered' => 'TEKRAR AKTİF',
      'destroyed' => 'DEVRE DIŞI',
      'overheat' => 'AŞIRI ISI',
      'cool' => 'SOĞUTMA',
      'energy_starved' => 'ENERJİ YETERSİZ',
      _ => '',
    };
    if (event.type == 'destroyed') {
      for (var index = 0; index < 8; index++) {
        final angle = index * math.pi / 4;
        final start = to + Offset(math.cos(angle), math.sin(angle)) * 9;
        final finish = to +
            Offset(math.cos(angle), math.sin(angle)) *
                (17 + 18 * ringProgress);
        canvas.drawLine(
          start,
          finish,
          Paint()
            ..color = color.withValues(alpha: 0.84 * fade)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    if (label.isNotEmpty) {
      _drawFloatingLabel(
        canvas,
        label,
        to + Offset(0, -18 - ringProgress * 12),
        color,
        fade,
      );
    }
  }

  void _drawImpactBurst(
    Canvas canvas,
    Offset center,
    Color color,
    double impactProgress,
    double fade,
  ) {
    final radius = 7 + 27 * impactProgress;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.78 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      center,
      5 + 6 * (1 - impactProgress),
      Paint()
        ..color = color.withValues(alpha: 0.92 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    for (var index = 0; index < 6; index++) {
      final angle = index * math.pi / 3 + 0.35;
      final distance = 10 + 24 * impactProgress;
      final particle = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(
        particle,
        1.8 + 1.6 * (1 - impactProgress),
        Paint()..color = color.withValues(alpha: 0.78 * fade),
      );
    }
  }

  void _drawFloatingLabel(
    Canvas canvas,
    String label,
    Offset center,
    Color color,
    double opacity,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color.withValues(alpha: opacity.clamp(0.0, 1.0).toDouble()),
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 5)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 140);
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
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
