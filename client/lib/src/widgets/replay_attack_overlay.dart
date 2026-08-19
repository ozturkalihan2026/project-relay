import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/battle_visual_director.dart';
import '../game/replay_game.dart';
import '../models/relay_models.dart';
import '../theme/cosmetic_visuals.dart';
import '../theme/relay_theme.dart';

class ReplayAttackOverlay extends StatefulWidget {
  const ReplayAttackOverlay({
    required this.events,
    required this.playerBoard,
    required this.opponentBoard,
    this.finalTick,
    this.leftVisuals = const EquippedVisuals.defaults(),
    this.rightVisuals = const EquippedVisuals.defaults(),
    super.key,
  });

  final ValueListenable<List<BattleEvent>> events;
  final BoardDraft playerBoard;
  final BoardDraft opponentBoard;
  final int? finalTick;
  final EquippedVisuals leftVisuals;
  final EquippedVisuals rightVisuals;

  @override
  State<ReplayAttackOverlay> createState() => _ReplayAttackOverlayState();
}

class _ReplayAttackOverlayState extends State<ReplayAttackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<BattleEvent> _events = const [];
  final Set<String> _destroyedIds = <String>{};
  String? _phaseCue;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
    widget.events.addListener(_handleEvents);
    _handleEvents();
  }

  @override
  void didUpdateWidget(covariant ReplayAttackOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events == widget.events) return;
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
              event.type == 'overload' ||
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
    _phaseCue = null;
    for (final event in _events.where((event) => event.type == 'overload')) {
      _phaseCue = 'AŞIRI YÜK K${event.amount.toStringAsFixed(0)}';
    }
    for (final event in _events.where((event) => event.type == 'destroyed')) {
      final target = event.targetId;
      if (target == null) continue;
      _destroyedIds.add(target);
      final enemyBoard = event.side == 'left'
          ? widget.opponentBoard
          : widget.playerBoard;
      ModulePlacement? targetModule;
      for (final module in enemyBoard.modules) {
        if (module.id == target) {
          targetModule = module;
          break;
        }
      }
      if (targetModule?.kind == ModuleKind.generator) {
        _phaseCue = 'ÇEKİRDEK AÇIKTA';
      } else {
        final regular = enemyBoard.modules
            .where((module) => module.kind != ModuleKind.generator)
            .map((module) => module.id)
            .toSet();
        if (regular.isNotEmpty && regular.every(_destroyedIds.contains)) {
          _phaseCue = 'JENERATÖR AÇIĞA ÇIKTI';
        }
      }
    }
    if (_events.any(
      (event) =>
          event.type == 'core_damage' &&
          widget.finalTick != null &&
          event.tick >= widget.finalTick!,
    )) {
      _phaseCue = 'ÇEKİRDEK ÇÖKTÜ';
    }
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _AttackPainter(
            events: _events,
            playerBoard: widget.playerBoard,
            opponentBoard: widget.opponentBoard,
            finalTick: widget.finalTick,
            progress: Curves.easeOutCubic.transform(_controller.value),
            rawProgress: _controller.value,
            leftVisuals: widget.leftVisuals,
            rightVisuals: widget.rightVisuals,
            phaseCue: _phaseCue,
          ),
        ),
      ),
    );
  }
}

class _AttackPainter extends CustomPainter {
  const _AttackPainter({
    required this.events,
    required this.playerBoard,
    required this.opponentBoard,
    required this.finalTick,
    required this.progress,
    required this.rawProgress,
    required this.leftVisuals,
    required this.rightVisuals,
    required this.phaseCue,
  });

  final List<BattleEvent> events;
  final BoardDraft playerBoard;
  final BoardDraft opponentBoard;
  final int? finalTick;
  final double progress;
  final double rawProgress;
  final EquippedVisuals leftVisuals;
  final EquippedVisuals rightVisuals;
  final String? phaseCue;

  @override
  void paint(Canvas canvas, Size size) {
    if (events.isEmpty || rawProgress >= 1) return;
    final leftBoard = ReplayStageGeometry.leftBoard(size);
    final rightBoard = ReplayStageGeometry.rightBoard(size);
    final leftCore = leftBoard.center;
    final rightCore = rightBoard.center;

    _drawBattleBeat(canvas, size, leftBoard, rightBoard);
    for (var index = 0; index < events.length; index++) {
      _drawEvent(
        canvas,
        events[index],
        eventIndex: index,
        leftBoard: leftBoard,
        rightBoard: rightBoard,
        leftCore: leftCore,
        rightCore: rightCore,
      );
    }
    if (phaseCue != null) {
      _drawPhaseCue(canvas, size, phaseCue!);
    }
  }

  void _drawPhaseCue(Canvas canvas, Size size, String cue) {
    final appear = math.sin(rawProgress * math.pi).clamp(0.0, 1.0);
    final color = cue.contains('ÇEKİRDEK') || cue.contains('AŞIRI YÜK')
        ? RelayColors.coral
        : RelayColors.amber;
    final painter = TextPainter(
      text: TextSpan(
        text: cue,
        style: TextStyle(
          color: color.withValues(alpha: appear),
          fontSize: cue == 'ÇEKİRDEK ÇÖKTÜ' ? 25 : 19,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.1,
          shadows: [
            Shadow(
              color: color.withValues(alpha: 0.70 * appear),
              blurRadius: 18,
            ),
            const Shadow(color: Colors.black, blurRadius: 6),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.56);
    final center = Offset(size.width / 2, size.height * 0.18);
    final panel = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: painter.width + 44,
        height: painter.height + 22,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      panel,
      Paint()..color = RelayColors.background.withValues(alpha: 0.76 * appear),
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..color = color.withValues(alpha: 0.58 * appear)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _drawBattleBeat(
    Canvas canvas,
    Size size,
    Rect leftBoard,
    Rect rightBoard,
  ) {
    final opacity = math.sin(rawProgress * math.pi).clamp(0.0, 1.0);
    if (opacity <= 0) return;
    final systemOverload = events.any((event) => event.type == 'overload');
    final leftActive =
        systemOverload || events.any((event) => event.side == 'left');
    final rightActive =
        systemOverload || events.any((event) => event.side == 'right');
    if (leftActive) {
      _drawBoardEdgePulse(
        canvas,
        leftBoard,
        leftVisuals.modules.attack,
        opacity,
      );
    }
    if (rightActive) {
      _drawBoardEdgePulse(canvas, rightBoard, RelayColors.coral, opacity);
    }
    if (events.any(
      (event) => event.type == 'destroyed' || event.type == 'core_damage',
    )) {
      final wash = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            RelayColors.coral.withValues(alpha: 0.035 * opacity),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, wash);
    }
  }

  void _drawBoardEdgePulse(
    Canvas canvas,
    Rect board,
    Color color,
    double opacity,
  ) {
    final inflated = board.inflate(7 + opacity * 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inflated, const Radius.circular(18)),
      Paint()
        ..color = color.withValues(alpha: 0.16 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  void _drawEvent(
    Canvas canvas,
    BattleEvent event, {
    required int eventIndex,
    required Rect leftBoard,
    required Rect rightBoard,
    required Offset leftCore,
    required Offset rightCore,
  }) {
    final actorBoard = event.side == 'left'
        ? playerBoard
        : opponentBoard;
    final actorRect = event.side == 'left' ? leftBoard : rightBoard;
    final targetOnEnemy =
        event.type == 'attack' ||
        event.type == 'core_damage' ||
        event.type == 'shield_absorb' ||
        event.type == 'destroyed';
    final targetBoard = targetOnEnemy
        ? (event.side == 'left' ? opponentBoard : playerBoard)
        : actorBoard;
    final targetRect = targetOnEnemy
        ? (event.side == 'left' ? rightBoard : leftBoard)
        : actorRect;
    final from =
        _modulePoint(event.actorId, actorBoard, actorRect) ??
        (event.side == 'left' ? leftCore : rightCore);
    final targetCore = event.side == 'left' ? rightCore : leftCore;
    final to = event.type == 'core_damage'
        ? targetCore
        : _modulePoint(event.targetId, targetBoard, targetRect) ?? from;
    final fade = (1 - progress).clamp(0.15, 1.0).toDouble();
    final sideVisuals = event.side == 'left' ? leftVisuals : rightVisuals;
    final color = switch (event.type) {
      'shield' || 'shield_absorb' => const Color(0xFF74A7FF),
      'repair' || 'recovered' => RelayColors.mint,
      'destroyed' => RelayColors.coral,
      'overheat' => RelayColors.amber,
      'cool' => RelayColors.cyan,
      'energy_starved' => RelayColors.violet,
      _ => sideVisuals.modules.attack,
    };

    if (event.type == 'attack' || event.type == 'core_damage') {
      final cue = BattleVisualDirector.cueFor(
        event,
        playerBoard: playerBoard,
        opponentBoard: opponentBoard,
      );
      if (cue.weapon == BattleWeapon.pulseCannon) {
        _drawProjectileEvent(canvas, event, from, to, color, fade, eventIndex);
      } else {
        _drawBeamEvent(canvas, event, from, to, color, fade, eventIndex);
      }
      return;
    }

    switch (event.type) {
      case 'shield':
      case 'shield_absorb':
        _drawShieldEvent(
          canvas,
          to,
          color,
          fade,
          event.type == 'shield_absorb',
        );
        break;
      case 'repair':
      case 'recovered':
        _drawRepairEvent(canvas, to, color, fade, event);
        break;
      case 'destroyed':
        _drawDestroyedEvent(canvas, to, color, fade);
        break;
      case 'overheat':
        _drawHeatEvent(canvas, to, color, fade, hot: true);
        break;
      case 'cool':
        _drawHeatEvent(canvas, to, color, fade, hot: false);
        break;
      case 'energy_starved':
        _drawEnergyStarved(canvas, to, color, fade);
        break;
      default:
        break;
    }
  }

  void _drawBeamEvent(
    Canvas canvas,
    BattleEvent event,
    Offset from,
    Offset to,
    Color color,
    double fade,
    int eventIndex,
  ) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = math.sqrt(dx * dx + dy * dy).clamp(1.0, double.infinity);
    final normal = Offset(-dy / distance, dx / distance);
    final arcDirection = event.side == 'left' ? -1.0 : 1.0;
    final control =
        Offset.lerp(from, to, 0.5)! +
        normal * (18 + eventIndex * 4) * arcDirection;
    final headT = progress.clamp(0.0, 1.0).toDouble();
    final head = _quadratic(from, control, to, headT);
    final tailT = math.max(0.0, headT - 0.22);
    final tail = _quadratic(from, control, to, tailT);

    final chargePhase = (rawProgress / 0.28).clamp(0.0, 1.0).toDouble();
    final chargeFade = (1 - chargePhase * 0.42) * fade;
    canvas.drawCircle(
      from,
      7 + 13 * chargePhase,
      Paint()
        ..color = color.withValues(alpha: 0.48 * chargeFade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawCircle(
      from,
      5 + 3 * (1 - chargePhase),
      Paint()
        ..color = color.withValues(alpha: 0.36 * chargeFade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    if (chargePhase > 0.1 && chargePhase < 0.92) {
      final sparkIntensity = chargePhase < 0.5
          ? chargePhase * 2
          : (1 - chargePhase) * 2;
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3 + eventIndex * 0.4;
        final dist = 10 + 22 * chargePhase;
        final spark =
            from + Offset(math.cos(angle), math.sin(angle)) * dist;
        canvas.drawCircle(
          spark,
          1.0 + sparkIntensity * 1.6,
          Paint()..color = color.withValues(alpha: 0.72 * chargeFade * sparkIntensity),
        );
        final trailEnd =
            spark + Offset(math.cos(angle), math.sin(angle)) * (4 + sparkIntensity * 5);
        canvas.drawLine(
          spark,
          trailEnd,
          Paint()
            ..color = color.withValues(alpha: 0.34 * chargeFade * sparkIntensity)
            ..strokeWidth = 1.0 + sparkIntensity
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    final beamPath = Path()
      ..moveTo(tail.dx, tail.dy)
      ..quadraticBezierTo(control.dx, control.dy, head.dx, head.dy);
    canvas.drawPath(
      beamPath,
      Paint()
        ..color = color.withValues(alpha: 0.28 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      beamPath,
      Paint()
        ..color = color.withValues(alpha: 0.96 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4 + 2.2 * fade
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 1; i <= 5; i++) {
      final ghostT = math.max(0.0, headT - i * 0.035);
      final ghost = _quadratic(from, control, to, ghostT);
      canvas.drawCircle(
        ghost,
        math.max(1.3, 4.6 - i * 0.55),
        Paint()..color = color.withValues(alpha: fade * (0.48 - i * 0.065)),
      );
    }
    canvas.drawCircle(
      head,
      7.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.86 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      head,
      4.8,
      Paint()..color = color.withValues(alpha: 0.98 * fade),
    );

    if (rawProgress > 0.48) {
      final impactProgress = ((rawProgress - 0.48) / 0.52)
          .clamp(0.0, 1.0)
          .toDouble();
      _drawImpactBurst(canvas, to, color, impactProgress, fade);
      if (event.type == 'core_damage' &&
          finalTick != null &&
          event.tick >= finalTick!) {
        _drawCoreCollapse(canvas, to, color, impactProgress, fade);
      }
      _drawTargetHitFrame(canvas, to, color, impactProgress, fade);
      _drawFloatingLabel(
        canvas,
        event.type == 'core_damage'
            ? '-${event.amount.toStringAsFixed(0)} ÇEKİRDEK'
            : '-${event.amount.toStringAsFixed(0)}',
        to + Offset(0, -24 - impactProgress * 18),
        color,
        fade * (1 - impactProgress * 0.34),
      );
    }
  }

  void _drawProjectileEvent(
    Canvas canvas,
    BattleEvent event,
    Offset from,
    Offset to,
    Color color,
    double fade,
    int eventIndex,
  ) {
    final phase = Curves.easeInOutCubic.transform(progress);
    final direction = to - from;
    final distance = direction.distance.clamp(1.0, double.infinity);
    final unit = direction / distance;
    final normal = Offset(-unit.dy, unit.dx);
    final arc =
        normal * (24 + eventIndex * 3) * (event.side == 'left' ? -1 : 1);
    final control = Offset.lerp(from, to, 0.5)! + arc;
    final projectile = _quadratic(from, control, to, phase);
    final recoil = (1 - (rawProgress / 0.18).clamp(0.0, 1.0)) * 12;
    final charge = (rawProgress / 0.24).clamp(0.0, 1.0);

    canvas.drawCircle(
      from - unit * recoil,
      8 + charge * 9,
      Paint()
        ..color = color.withValues(alpha: 0.18 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    if (charge > 0.1 && charge < 0.85) {
      final ringRadius = 6 + charge * 18;
      canvas.drawCircle(
        from - unit * recoil,
        ringRadius,
        Paint()
          ..color = color.withValues(alpha: 0.52 * fade * (1 - charge))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 + (1 - charge) * 2,
      );
      for (var i = 0; i < 5; i++) {
        final a = i * math.pi * 2 / 5 + eventIndex * 0.3;
        final d = 5 + charge * 12;
        final sp = from - unit * recoil + Offset(math.cos(a), math.sin(a)) * d;
        canvas.drawCircle(
          sp,
          0.8 + (1 - charge) * 1.2,
          Paint()..color = color.withValues(alpha: 0.6 * fade * (1 - charge)),
        );
      }
    }
    final trailStart = projectile - unit * 34;
    canvas.drawLine(
      trailStart,
      projectile,
      Paint()
        ..color = color.withValues(alpha: 0.34 * fade)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawLine(
      trailStart,
      projectile,
      Paint()
        ..color = RelayColors.white.withValues(alpha: 0.90 * fade)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      projectile,
      7.5,
      Paint()..color = color.withValues(alpha: 0.98 * fade),
    );
    canvas.drawCircle(
      projectile,
      15,
      Paint()
        ..color = color.withValues(alpha: 0.18 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    if (phase > 0.72) {
      final impact = ((phase - 0.72) / 0.28).clamp(0.0, 1.0);
      _drawImpactBurst(canvas, to, color, impact, fade);
      _drawTargetHitFrame(canvas, to, color, impact, fade);
      _drawFloatingLabel(
        canvas,
        event.type == 'core_damage'
            ? '-${event.amount.toStringAsFixed(0)} ÇEKİRDEK'
            : '-${event.amount.toStringAsFixed(0)}',
        to + Offset(0, -30 - impact * 18),
        color,
        fade,
      );
    }
  }

  void _drawShieldEvent(
    Canvas canvas,
    Offset to,
    Color color,
    double fade,
    bool absorbed,
  ) {
    final phase = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
    final radius = 22 + 42 * phase;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final point = to + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    final dome = Rect.fromCenter(
      center: to + const Offset(0, 8),
      width: radius * 2.5,
      height: radius * 1.5,
    );
    canvas.drawArc(
      dome,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.22 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawArc(
      dome,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.78 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.16 * fade)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.90 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.7,
    );
    final shield = Path()
      ..moveTo(to.dx, to.dy - radius * 0.54)
      ..quadraticBezierTo(
        to.dx + radius * 0.42,
        to.dy - radius * 0.34,
        to.dx + radius * 0.34,
        to.dy + radius * 0.12,
      )
      ..quadraticBezierTo(
        to.dx + radius * 0.20,
        to.dy + radius * 0.48,
        to.dx,
        to.dy + radius * 0.62,
      )
      ..quadraticBezierTo(
        to.dx - radius * 0.20,
        to.dy + radius * 0.48,
        to.dx - radius * 0.34,
        to.dy + radius * 0.12,
      )
      ..quadraticBezierTo(
        to.dx - radius * 0.42,
        to.dy - radius * 0.34,
        to.dx,
        to.dy - radius * 0.54,
      )
      ..close();
    canvas.drawPath(
      shield,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12 * fade)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      shield,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.84 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    _drawFloatingLabel(
      canvas,
      absorbed ? 'HASAR EMİLDİ' : 'KALKAN AKTİF',
      to + Offset(0, -radius - 14),
      color,
      fade,
    );
  }

  void _drawRepairEvent(
    Canvas canvas,
    Offset to,
    Color color,
    double fade,
    BattleEvent event,
  ) {
    final phase = Curves.easeOut.transform(progress);
    final radius = 11 + 30 * phase;
    canvas.drawCircle(
      to,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.60 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + rawProgress * 1.8;
      final center =
          to + Offset(math.cos(angle), math.sin(angle)) * (12 + 16 * phase);
      _drawPlus(canvas, center, color.withValues(alpha: 0.82 * fade), 4.5);
    }
    _drawFloatingLabel(
      canvas,
      event.type == 'recovered'
          ? 'TEKRAR AKTİF'
          : '+${event.amount.toStringAsFixed(0)} ONARIM',
      to + Offset(0, -20 - phase * 18),
      color,
      fade,
    );
  }

  void _drawDestroyedEvent(Canvas canvas, Offset to, Color color, double fade) {
    final phase = Curves.easeOutExpo.transform(progress);
    final radius = 12 + 38 * phase;
    canvas.drawCircle(
      to,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.72 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );
    canvas.drawCircle(
      to,
      13 * (1 - phase * 0.45),
      Paint()
        ..color = color.withValues(alpha: 0.42 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    for (var index = 0; index < 20; index++) {
      final angle = index * math.pi * 2 / 20 + rawProgress * 0.45;
      final start = to + Offset(math.cos(angle), math.sin(angle)) * 8;
      final finish =
          to +
          Offset(math.cos(angle), math.sin(angle)) *
              (22 + (38 + (index % 5) * 7) * phase);
      canvas.drawLine(
        start,
        finish,
        Paint()
          ..color = (index.isEven ? color : RelayColors.amber).withValues(
            alpha: 0.82 * fade,
          )
          ..strokeWidth = index.isEven ? 3.1 : 1.7
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var index = 0; index < 16; index++) {
      final angle = index * math.pi / 8 + 0.35;
      final distance = 13 + (48 + (index % 4) * 9) * phase;
      final center = to + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle + phase * 2.1);
      canvas.drawRect(
        Rect.fromLTWH(-3.5 - (index % 3), -2.2, 7.0 + (index % 3) * 2, 4.4),
        Paint()
          ..color = (index.isEven ? RelayColors.coral : RelayColors.amber)
              .withValues(alpha: 0.78 * fade),
      );
      canvas.restore();
    }
    _drawFloatingLabel(
      canvas,
      'DEVRE DIŞI',
      to + Offset(0, -34 - phase * 16),
      color,
      fade,
    );
  }

  void _drawHeatEvent(
    Canvas canvas,
    Offset to,
    Color color,
    double fade, {
    required bool hot,
  }) {
    final phase = Curves.easeOut.transform(progress);
    for (var i = 0; i < 6; i++) {
      final spread = (i - 2.5) * 6.0;
      final y = hot ? -12 - phase * (20 + i * 2) : 12 + phase * (18 + i * 2);
      canvas.drawCircle(
        to + Offset(spread, y),
        2.5 + (i % 2) * 1.2,
        Paint()..color = color.withValues(alpha: (0.72 - i * 0.07) * fade),
      );
    }
    _drawFloatingLabel(
      canvas,
      hot ? 'AŞIRI ISI' : 'SOĞUTMA',
      to + Offset(0, hot ? -36 : -28),
      color,
      fade,
    );
  }

  void _drawEnergyStarved(Canvas canvas, Offset to, Color color, double fade) {
    final phase = Curves.easeOut.transform(progress);
    for (var i = 0; i < 3; i++) {
      final radius = 10 + phase * (12 + i * 8);
      canvas.drawArc(
        Rect.fromCircle(center: to, radius: radius),
        -math.pi * 0.85 + i * 0.35,
        math.pi * 0.8,
        false,
        Paint()
          ..color = color.withValues(alpha: (0.68 - i * 0.13) * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
    _drawFloatingLabel(
      canvas,
      'ENERJİ YETERSİZ',
      to + Offset(0, -34 - 10 * phase),
      color,
      fade,
    );
  }

  void _drawImpactBurst(
    Canvas canvas,
    Offset center,
    Color color,
    double phase,
    double fade,
  ) {
    final outer = 8 + 34 * phase;
    final inner = 4 + 20 * phase;
    for (final entry in [(outer, 0.80), (inner, 0.48)]) {
      canvas.drawCircle(
        center,
        entry.$1,
        Paint()
          ..color = color.withValues(
            alpha: entry.$2 * fade * (1 - phase * 0.35),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = entry.$1 == outer ? 2.8 : 1.5,
      );
    }
    canvas.drawCircle(
      center,
      6 + 7 * (1 - phase),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.78 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    for (var index = 0; index < 8; index++) {
      final angle = index * math.pi / 4 + 0.22;
      final distance = 11 + 30 * phase;
      final particle =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(
        particle,
        1.6 + 2.2 * (1 - phase),
        Paint()..color = color.withValues(alpha: 0.78 * fade),
      );
    }
    for (var index = 0; index < 12; index++) {
      final angle = (index * 0.61803 + 0.7) * math.pi * 2;
      final speed = 14 + (index % 5) * 7;
      final travel = speed * phase;
      final gravity = phase * phase * 18;
      final spark = center +
          Offset(math.cos(angle) * travel, math.sin(angle) * travel + gravity);
      final sparkAlpha = (1 - phase * 0.85).clamp(0.0, 1.0);
      canvas.drawCircle(
        spark,
        math.max(0.5, 1.4 - phase * 0.7),
        Paint()..color = (index.isEven ? color : Colors.white).withValues(
          alpha: 0.68 * fade * sparkAlpha,
        ),
      );
      if (phase < 0.5) {
        final prevT = (phase - 0.06).clamp(0.0, 1.0);
        final prevTravel = speed * prevT;
        final prevGravity = prevT * prevT * 18;
        final prev = center + Offset(
          math.cos(angle) * prevTravel,
          math.sin(angle) * prevTravel + prevGravity,
        );
        canvas.drawLine(
          prev,
          spark,
          Paint()
            ..color = color.withValues(alpha: 0.32 * fade * sparkAlpha)
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawCoreCollapse(
    Canvas canvas,
    Offset center,
    Color color,
    double phase,
    double fade,
  ) {
    final t = phase;
    double window(double start, double end) => ((t - start) / (end - start))
        .clamp(0.0, 1.0)
        .toDouble();
    final out = Curves.easeOut.transform;

    final ember = window(0.45, 1);
    if (ember > 0) {
      canvas.drawCircle(
        center,
        16 + out(ember) * 52,
        Paint()
          ..color = color.withValues(alpha: 0.13 * fade * (1 - ember))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
      for (var i = 0; i < 18; i++) {
        final baseAngle = (i * 0.61803 + 1.7) * math.pi * 2;
        final rise = ember * (10 + (i % 5) * 9);
        final sway = math.sin(ember * math.pi * 3 + i * 0.9) * 7;
        final particle =
            center +
            Offset(math.cos(baseAngle) * 12 + sway, math.sin(baseAngle) * 8 - rise);
        canvas.drawCircle(
          particle,
          math.max(0.6, 1.6 - ember * 0.8),
          Paint()
            ..color = RelayColors.coral.withValues(
              alpha: 0.55 * fade * (1 - ember) * (0.5 + (i % 4) * 0.15),
            ),
        );
      }
    }

    final implode = window(0, 0.22);
    if (implode > 0) {
      canvas.drawCircle(
        center,
        (46 - implode * 36) * (1 - t * 0.2),
        Paint()
          ..color = RelayColors.white.withValues(
            alpha: 0.9 * fade * (1 - implode),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 + implode * 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    final flash = window(0, 0.34) * (1 - t * 0.9);
    if (flash > 0) {
      canvas.drawCircle(
        center,
        8 + out(t) * 46,
        Paint()
          ..color = RelayColors.white.withValues(alpha: 0.85 * fade * flash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
      );
      canvas.drawCircle(
        center,
        5 + out(t) * 30,
        Paint()
          ..color = color.withValues(alpha: 0.95 * fade * flash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    final fireball = window(0, 0.5);
    final fireballRadius = 6 + out(fireball) * 80;
    if (fireball > 0) {
      final fireballAlpha = fireball * (1 - t * 0.55);
      if (fireballAlpha > 0) {
        canvas.drawCircle(
          center,
          fireballRadius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                RelayColors.white.withValues(
                  alpha: 0.96 * fade * fireballAlpha,
                ),
                RelayColors.amber.withValues(alpha: 0.9 * fade * fireballAlpha),
                color.withValues(alpha: 0.62 * fade * fireballAlpha),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.32, 0.7, 1.0],
            ).createShader(Rect.fromCircle(center: center, radius: fireballRadius)),
        );
      }
      canvas.drawCircle(
        center,
        fireballRadius,
        Paint()
          ..color = RelayColors.white.withValues(alpha: 0.7 * fade * fireballAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 + 4 * (1 - fireball),
      );
    }

    final rays = window(0, 0.62);
    if (rays > 0) {
      final rayAlpha = 0.95 * fade * (1 - t * 0.4);
      for (var i = 0; i < 26; i++) {
        final angle = i * math.pi * 2 / 26 + t * 0.55;
        final longLance = i % 5 == 0;
        final length = out(rays) * (longLance ? 120 : 84) + (i % 7) * 6 * (1 - t);
        final direction = Offset(math.cos(angle), math.sin(angle));
        final tip = center + direction * length;
        canvas.drawLine(
          center + direction * 6,
          tip,
          Paint()
            ..color = (i.isEven ? RelayColors.amber : color)
                .withValues(alpha: rayAlpha)
            ..strokeWidth = (longLance ? 5.0 : 2.2) * (1 - t * 0.45)
            ..strokeCap = StrokeCap.round
            ..maskFilter = longLance
                ? const MaskFilter.blur(BlurStyle.normal, 3)
                : null,
        );
        canvas.drawCircle(
          tip,
          longLance ? 2.4 : 1.4,
          Paint()
            ..color = (longLance ? RelayColors.white : RelayColors.amber)
                .withValues(alpha: rayAlpha * 0.9),
        );
      }
    }

    final sparks = window(0.12, 0.95);
    if (sparks > 0) {
      final sparkAlpha = 0.95 * fade * (1 - sparks);
      for (var i = 0; i < 34; i++) {
        final baseAngle = (i * 0.61803) * math.pi * 2;
        final spread = ((i * 37) % 29) / 29.0;
        final angle = baseAngle + (spread - 0.5) * 0.55;
        final speed = 16 + ((i * 13) % 23) / 23.0 * 84;
        final drift = Offset(math.cos(angle), math.sin(angle));
        final distance = speed * out(sparks);
        final particle = center + drift * distance + Offset(0, sparks * sparks * 16);
        canvas.drawCircle(
          particle,
          math.max(0.7, 2.8 - sparks * 1.8),
          Paint()
            ..color = (i % 3 == 0 ? RelayColors.white : RelayColors.amber)
                .withValues(alpha: sparkAlpha * 0.85),
        );
      }
    }

    for (var i = 0; i < 3; i++) {
      final wave = window(0.2 + i * 0.1, 0.9 + i * 0.04);
      if (wave <= 0) continue;
      final radius = 14 + out(wave) * (94 + i * 26);
      final alpha = (0.85 - i * 0.2) * fade * (1 - wave);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = (i.isEven ? RelayColors.white : color)
              .withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.6 - i * 0.5) + (1 - wave) * 3
          ..maskFilter = i == 0
              ? const MaskFilter.blur(BlurStyle.normal, 4)
              : null,
      );
    }
  }

  void _drawTargetHitFrame(
    Canvas canvas,
    Offset center,
    Color color,
    double phase,
    double fade,
  ) {
    final extent = 11 + phase * 12;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.82 * fade * (1 - phase * 0.25))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final sx in [-1.0, 1.0]) {
      for (final sy in [-1.0, 1.0]) {
        final corner = center + Offset(sx * extent, sy * extent);
        canvas.drawLine(corner, corner + Offset(-sx * 7, 0), paint);
        canvas.drawLine(corner, corner + Offset(0, -sy * 7), paint);
      }
    }
  }

  void _drawPlus(Canvas canvas, Offset center, Color color, double size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center + Offset(-size, 0), center + Offset(size, 0), paint);
    canvas.drawLine(center + Offset(0, -size), center + Offset(0, size), paint);
  }

  void _drawFloatingLabel(
    Canvas canvas,
    String label,
    Offset center,
    Color color,
    double opacity,
  ) {
    final alpha = opacity.clamp(0.0, 1.0).toDouble();
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color.withValues(alpha: alpha),
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 5)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 150);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: painter.width + 14,
        height: painter.height + 7,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = RelayColors.background.withValues(alpha: 0.64 * alpha),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.34 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  Offset _quadratic(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  Offset? _modulePoint(String? id, BoardDraft board, Rect rect) {
    if (id == null) return null;
    for (final module in board.modules) {
      if (module.id == id) {
        final cellSize = rect.width / 4;
        final raw = Offset(
          rect.left + (module.column + 0.5) * cellSize,
          rect.top + (module.row + 0.5) * cellSize,
        );
        return ReplayStageGeometry.perspectivePoint(
          raw,
          rect,
          leftSide: identical(board, playerBoard),
        );
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant _AttackPainter oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.progress != progress ||
        oldDelegate.rawProgress != rawProgress ||
        oldDelegate.playerBoard != playerBoard ||
        oldDelegate.opponentBoard != opponentBoard ||
        oldDelegate.finalTick != finalTick ||
        oldDelegate.leftVisuals.modules.id != leftVisuals.modules.id ||
        oldDelegate.rightVisuals.modules.id != rightVisuals.modules.id ||
        oldDelegate.phaseCue != phaseCue;
  }
}
