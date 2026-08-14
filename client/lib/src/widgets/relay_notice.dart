import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';
import 'circuit_credit_icon.dart';

enum RelayNoticeTone { info, success, warning, error }

enum RelayRewardKind { generic, xp, credits, victory, achievement, season }

String levelUnlockLabel(int level, {int? previousLevel}) {
  final before = previousLevel ?? level - 1;
  if (before < 40 && level >= 40) return 'BOSS GÜÇLENDİRİCİ KADEMESİ K5 AÇILDI';
  if (before < 30 && level >= 30) return 'BOSS GÜÇLENDİRİCİ KADEMESİ K4 AÇILDI';
  if (before < 20 && level >= 20) return 'BOSS GÜÇLENDİRİCİ KADEMESİ K3 AÇILDI';
  if (before < 10 && level >= 10) return 'BOSS GÜÇLENDİRİCİ KADEMESİ K2 AÇILDI';
  return 'SEVİYE $level ROZETİ AÇILDI';
}

abstract final class RelayNotice {
  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context,
    String message, {
    RelayNoticeTone tone = RelayNoticeTone.info,
    Duration? duration,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || message.trim().isEmpty) return;
    dismiss();
    final visibleDuration =
        duration ??
        (tone == RelayNoticeTone.error
            ? const Duration(seconds: 6)
            : const Duration(seconds: 4));
    late final OverlayEntry entry;
    void removeEntry() {
      if (!identical(_activeEntry, entry)) return;
      _activeEntry = null;
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) => _RelayNoticeOverlay(
        message: message,
        tone: tone,
        duration: visibleDuration,
        onDismiss: removeEntry,
      ),
    );
    _activeEntry = entry;
    overlay.insert(entry);
  }

  static void showReward(
    BuildContext context, {
    required String title,
    int xp = 0,
    int credits = 0,
    RelayRewardKind kind = RelayRewardKind.generic,
    String? detail,
    Duration duration = const Duration(seconds: 5),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    dismiss();
    late final OverlayEntry entry;
    void removeEntry() {
      if (!identical(_activeEntry, entry)) return;
      _activeEntry = null;
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) => _RelayRewardOverlay(
        title: title,
        xp: xp,
        credits: credits,
        kind: kind,
        detail: detail,
        duration: duration,
        onDismiss: removeEntry,
      ),
    );
    _activeEntry = entry;
    overlay.insert(entry);
  }

  static void showLevelUp(
    BuildContext context, {
    required int level,
    required int xp,
    required int credits,
    String? unlockLabel,
    bool soundEnabled = true,
    Duration duration = const Duration(seconds: 7),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    dismiss();
    late final OverlayEntry entry;
    void removeEntry() {
      if (!identical(_activeEntry, entry)) return;
      _activeEntry = null;
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) => _RelayLevelUpOverlay(
        level: level,
        xp: xp,
        credits: credits,
        unlockLabel: unlockLabel,
        soundEnabled: soundEnabled,
        duration: duration,
        onDismiss: removeEntry,
      ),
    );
    _activeEntry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    final entry = _activeEntry;
    _activeEntry = null;
    if (entry != null && entry.mounted) entry.remove();
  }
}

class _RelayNoticeOverlay extends StatefulWidget {
  const _RelayNoticeOverlay({
    required this.message,
    required this.tone,
    required this.duration,
    required this.onDismiss,
  });
  final String message;
  final RelayNoticeTone tone;
  final Duration duration;
  final VoidCallback onDismiss;
  @override
  State<_RelayNoticeOverlay> createState() => _RelayNoticeOverlayState();
}

class _RelayNoticeOverlayState extends State<_RelayNoticeOverlay> {
  Timer? _dismissTimer;
  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(widget.duration, widget.onDismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (widget.tone) {
      RelayNoticeTone.info => RelayColors.cyan,
      RelayNoticeTone.success => RelayColors.mint,
      RelayNoticeTone.warning => RelayColors.amber,
      RelayNoticeTone.error => RelayColors.coral,
    };
    final icon = switch (widget.tone) {
      RelayNoticeTone.info => Icons.info_outline,
      RelayNoticeTone.success => Icons.check_circle_outline,
      RelayNoticeTone.warning => Icons.warning_amber_rounded,
      RelayNoticeTone.error => Icons.error_outline,
    };
    return _OverlayShell(
      child: Container(
        key: const ValueKey('relay-centered-notice'),
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: _noticeDecoration(color),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(icon: icon, color: color),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: RelayColors.white,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelayRewardOverlay extends StatefulWidget {
  const _RelayRewardOverlay({
    required this.title,
    required this.xp,
    required this.credits,
    required this.kind,
    required this.detail,
    required this.duration,
    required this.onDismiss,
  });
  final String title;
  final int xp;
  final int credits;
  final RelayRewardKind kind;
  final String? detail;
  final Duration duration;
  final VoidCallback onDismiss;
  @override
  State<_RelayRewardOverlay> createState() => _RelayRewardOverlayState();
}

class _RelayRewardOverlayState extends State<_RelayRewardOverlay> {
  Timer? _dismissTimer;
  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(widget.duration, widget.onDismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon, creditGlyph) = switch (widget.kind) {
      RelayRewardKind.xp => (RelayColors.cyan, Icons.bolt_rounded, false),
      RelayRewardKind.credits => (
        RelayColors.amber,
        Icons.memory_rounded,
        true,
      ),
      RelayRewardKind.victory => (
        RelayColors.mint,
        Icons.emoji_events_outlined,
        false,
      ),
      RelayRewardKind.achievement => (
        RelayColors.violet,
        Icons.workspace_premium_outlined,
        false,
      ),
      RelayRewardKind.season => (RelayColors.amber, Icons.auto_awesome, false),
      RelayRewardKind.generic => (
        RelayColors.cyan,
        Icons.card_giftcard_outlined,
        false,
      ),
    };
    return _OverlayShell(
      scaleFrom: 0.88,
      child: Container(
        key: const ValueKey('relay-reward-notice'),
        constraints: const BoxConstraints(maxWidth: 470),
        padding: const EdgeInsets.all(18),
        decoration: _noticeDecoration(color),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(
              icon: icon,
              color: color,
              large: true,
              creditGlyph: creditGlyph,
            ),
            const SizedBox(height: 10),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.4,
              ),
            ),
            if (widget.detail?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                widget.detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: RelayColors.muted, fontSize: 11),
              ),
            ],
            if (widget.xp > 0 || widget.credits > 0) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: [
                  if (widget.xp > 0)
                    _RewardPill(
                      icon: Icons.bolt_rounded,
                      label: '+${widget.xp} XP',
                      color: RelayColors.cyan,
                    ),
                  if (widget.credits > 0)
                    _RewardPill(
                      label: '+${widget.credits} DK',
                      color: RelayColors.amber,
                      creditGlyph: true,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RelayLevelUpOverlay extends StatefulWidget {
  const _RelayLevelUpOverlay({
    required this.level,
    required this.xp,
    required this.credits,
    required this.unlockLabel,
    required this.soundEnabled,
    required this.duration,
    required this.onDismiss,
  });
  final int level;
  final int xp;
  final int credits;
  final String? unlockLabel;
  final bool soundEnabled;
  final Duration duration;
  final VoidCallback onDismiss;
  @override
  State<_RelayLevelUpOverlay> createState() => _RelayLevelUpOverlayState();
}

class _RelayLevelUpOverlayState extends State<_RelayLevelUpOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _dismissTimer;
  late final AnimationController _celebrationController;
  AudioPlayer? _celebrationPlayer;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();
    _dismissTimer = Timer(widget.duration, widget.onDismiss);
    if (widget.soundEnabled) unawaited(_playCelebration());
  }

  Future<void> _playCelebration() async {
    final player = AudioPlayer(playerId: 'relay-level-up');
    _celebrationPlayer = player;
    try {
      await player.play(AssetSource('sounds/level_up.wav'), volume: 0.46);
    } on Object {
      // Tarayıcı sesi kilitlerse görsel kutlama kesintisiz devam eder.
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _celebrationController.dispose();
    final player = _celebrationPlayer;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) => CustomPaint(
                key: const ValueKey('relay-level-up-fireworks'),
                painter: _CelebrationFireworksPainter(
                  progress: _celebrationController.value,
                ),
              ),
            ),
          ),
        ),
        _OverlayShell(
          scaleFrom: 0.72,
          elastic: true,
          child: Container(
            key: const ValueKey('relay-level-up-badge'),
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xF51A3553),
                  Color(0xF5222945),
                  Color(0xF53A2942),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: RelayColors.amber.withValues(alpha: 0.9),
                width: 1.7,
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 34,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: RelayColors.cyan.withValues(alpha: 0.18),
                  blurRadius: 30,
                ),
                BoxShadow(
                  color: RelayColors.amber.withValues(alpha: 0.18),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SEVİYE ATLADIN',
                  style: TextStyle(
                    color: RelayColors.amber,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 2.1,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 112,
                  height: 112,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: RelayColors.cyan.withValues(alpha: 0.42),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: RelayColors.cyan.withValues(alpha: 0.28),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              RelayColors.amber.withValues(alpha: 0.28),
                              RelayColors.violet.withValues(alpha: 0.10),
                            ],
                          ),
                          border: Border.all(
                            color: RelayColors.amber,
                            width: 2.5,
                          ),
                        ),
                      ),
                      Text(
                        '${widget.level}',
                        style: const TextStyle(
                          color: RelayColors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: [
                    if (widget.xp > 0)
                      _RewardPill(
                        icon: Icons.bolt_rounded,
                        label: '+${widget.xp} XP',
                        color: RelayColors.cyan,
                      ),
                    if (widget.credits > 0)
                      _RewardPill(
                        label: '+${widget.credits} DK',
                        color: RelayColors.amber,
                        creditGlyph: true,
                      ),
                  ],
                ),
                if (widget.unlockLabel?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: RelayColors.mint.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: RelayColors.mint.withValues(alpha: 0.42),
                      ),
                    ),
                    child: Text(
                      widget.unlockLabel!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: RelayColors.mint,
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                        letterSpacing: 0.45,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CelebrationFireworksPainter extends CustomPainter {
  const _CelebrationFireworksPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bursts = <(Offset, Color, double)>[
      (Offset(size.width * 0.22, size.height * 0.27), RelayColors.cyan, 0.00),
      (Offset(size.width * 0.78, size.height * 0.30), RelayColors.amber, 0.16),
      (Offset(size.width * 0.32, size.height * 0.72), RelayColors.violet, 0.34),
      (Offset(size.width * 0.72, size.height * 0.69), RelayColors.mint, 0.48),
    ];
    for (var burstIndex = 0; burstIndex < bursts.length; burstIndex += 1) {
      final burst = bursts[burstIndex];
      final phase = ((progress - burst.$3) / 0.48).clamp(0.0, 1.0);
      if (phase <= 0 || phase >= 1) continue;
      final expansion = Curves.easeOutCubic.transform(phase);
      final fade = math.sin(phase * math.pi).clamp(0.0, 1.0);
      final center = burst.$1;
      final radius = 18 + expansion * math.min(size.width, size.height) * 0.13;
      canvas.drawCircle(
        center,
        10 + expansion * 22,
        Paint()
          ..color = burst.$2.withValues(alpha: 0.12 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
      for (var particle = 0; particle < 22; particle += 1) {
        final angle = particle * math.pi * 2 / 22 + burstIndex * 0.37;
        final variance = 0.72 + (particle % 5) * 0.07;
        final vector = Offset(math.cos(angle), math.sin(angle));
        final tip = center + vector * radius * variance;
        final tail = center + vector * radius * variance * 0.68;
        final color = particle.isEven ? burst.$2 : RelayColors.white;
        canvas.drawLine(
          tail,
          tip,
          Paint()
            ..color = color.withValues(alpha: 0.86 * fade)
            ..strokeWidth = particle % 3 == 0 ? 2.8 : 1.6
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          tip,
          particle % 4 == 0 ? 2.8 : 1.7,
          Paint()..color = color.withValues(alpha: 0.92 * fade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationFireworksPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _OverlayShell extends StatelessWidget {
  const _OverlayShell({
    required this.child,
    this.scaleFrom = 0.92,
    this.elastic = false,
  });
  final Widget child;
  final double scaleFrom;
  final bool elastic;
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          minimum: const EdgeInsets.all(18),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: scaleFrom, end: 1),
              duration: Duration(milliseconds: elastic ? 420 : 180),
              curve: elastic ? Curves.elasticOut : Curves.easeOutCubic,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Material(color: Colors.transparent, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    this.large = false,
    this.creditGlyph = false,
  });

  final IconData icon;
  final Color color;
  final bool large;
  final bool creditGlyph;

  @override
  Widget build(BuildContext context) => Container(
    width: large ? 54 : 42,
    height: large ? 54 : 42,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 0.13),
      border: Border.all(color: color.withValues(alpha: 0.55)),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 18),
      ],
    ),
    alignment: Alignment.center,
    child: creditGlyph
        ? CircuitCreditGlyph(size: large ? 30 : 24, glow: true)
        : Icon(icon, color: color, size: large ? 28 : 22),
  );
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({
    required this.label,
    required this.color,
    this.icon,
    this.creditGlyph = false,
  });

  final IconData? icon;
  final String label;
  final Color color;
  final bool creditGlyph;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.38)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (creditGlyph)
          const CircuitCreditGlyph(size: 17)
        else if (icon != null)
          Icon(icon, color: color, size: 16),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

BoxDecoration _noticeDecoration(Color color) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.alphaBlend(color.withValues(alpha: 0.10), const Color(0xF5152A3B)),
      const Color(0xF5182334),
    ],
  ),
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: color.withValues(alpha: 0.72), width: 1.3),
  boxShadow: [
    const BoxShadow(color: Color(0x88000000), blurRadius: 30, spreadRadius: 2),
    BoxShadow(color: color.withValues(alpha: 0.16), blurRadius: 24),
  ],
);
