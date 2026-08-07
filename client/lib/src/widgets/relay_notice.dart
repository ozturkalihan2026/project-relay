import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';

enum RelayNoticeTone { info, success, warning, error }

enum RelayRewardKind { generic, xp, credits, victory, achievement, season }

String levelUnlockLabel(
  int level, {
  int? previousLevel,
}) {
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
    final visibleDuration = duration ??
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
  const _RelayNoticeOverlay({required this.message, required this.tone, required this.duration, required this.onDismiss});
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
                style: const TextStyle(color: RelayColors.white, fontSize: 14, height: 1.35, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelayRewardOverlay extends StatefulWidget {
  const _RelayRewardOverlay({required this.title, required this.xp, required this.credits, required this.kind, required this.detail, required this.duration, required this.onDismiss});
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
    final (color, icon) = switch (widget.kind) {
      RelayRewardKind.xp => (RelayColors.cyan, Icons.bolt_rounded),
      RelayRewardKind.credits => (RelayColors.amber, Icons.toll_outlined),
      RelayRewardKind.victory => (RelayColors.mint, Icons.emoji_events_outlined),
      RelayRewardKind.achievement => (RelayColors.violet, Icons.workspace_premium_outlined),
      RelayRewardKind.season => (RelayColors.amber, Icons.auto_awesome),
      RelayRewardKind.generic => (RelayColors.cyan, Icons.card_giftcard_outlined),
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
            _IconBadge(icon: icon, color: color, large: true),
            const SizedBox(height: 10),
            Text(widget.title, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.4)),
            if (widget.detail?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(widget.detail!, textAlign: TextAlign.center, style: const TextStyle(color: RelayColors.muted, fontSize: 11)),
            ],
            if (widget.xp > 0 || widget.credits > 0) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: [
                  if (widget.xp > 0) _RewardPill(icon: Icons.bolt_rounded, label: '+${widget.xp} XP', color: RelayColors.cyan),
                  if (widget.credits > 0) _RewardPill(icon: Icons.toll_outlined, label: '+${widget.credits} DK', color: RelayColors.amber),
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
  const _RelayLevelUpOverlay({required this.level, required this.xp, required this.credits, required this.unlockLabel, required this.duration, required this.onDismiss});
  final int level;
  final int xp;
  final int credits;
  final String? unlockLabel;
  final Duration duration;
  final VoidCallback onDismiss;
  @override
  State<_RelayLevelUpOverlay> createState() => _RelayLevelUpOverlayState();
}

class _RelayLevelUpOverlayState extends State<_RelayLevelUpOverlay> {
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
    return _OverlayShell(
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
            colors: [Color(0xF51A3553), Color(0xF5222945), Color(0xF53A2942)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: RelayColors.amber.withValues(alpha: 0.9), width: 1.7),
          boxShadow: [
            const BoxShadow(color: Color(0x99000000), blurRadius: 34, spreadRadius: 4),
            BoxShadow(color: RelayColors.cyan.withValues(alpha: 0.18), blurRadius: 30),
            BoxShadow(color: RelayColors.amber.withValues(alpha: 0.18), blurRadius: 24),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('SEVİYE ATLADIN', style: TextStyle(color: RelayColors.amber, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2.1)),
            const SizedBox(height: 12),
            SizedBox(
              width: 112,
              height: 112,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: RelayColors.cyan.withValues(alpha: 0.42), width: 2), boxShadow: [BoxShadow(color: RelayColors.cyan.withValues(alpha: 0.28), blurRadius: 24)])),
                  Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [RelayColors.amber.withValues(alpha: 0.28), RelayColors.violet.withValues(alpha: 0.10)]), border: Border.all(color: RelayColors.amber, width: 2.5))),
                  Text('${widget.level}', style: const TextStyle(color: RelayColors.white, fontSize: 42, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: [
                if (widget.xp > 0) _RewardPill(icon: Icons.bolt_rounded, label: '+${widget.xp} XP', color: RelayColors.cyan),
                if (widget.credits > 0) _RewardPill(icon: Icons.toll_outlined, label: '+${widget.credits} DK', color: RelayColors.amber),
              ],
            ),
            if (widget.unlockLabel?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(color: RelayColors.mint.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(12), border: Border.all(color: RelayColors.mint.withValues(alpha: 0.42))),
                child: Text(widget.unlockLabel!, textAlign: TextAlign.center, style: const TextStyle(color: RelayColors.mint, fontWeight: FontWeight.w900, fontSize: 10.5, letterSpacing: 0.45)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverlayShell extends StatelessWidget {
  const _OverlayShell({required this.child, this.scaleFrom = 0.92, this.elastic = false});
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
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Material(color: Colors.transparent, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color, this.large = false});
  final IconData icon;
  final Color color;
  final bool large;
  @override
  Widget build(BuildContext context) => Container(
        width: large ? 54 : 42,
        height: large ? 54 : 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.13),
          border: Border.all(color: color.withValues(alpha: 0.55)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 18)],
        ),
        child: Icon(icon, color: color, size: large ? 28 : 22),
      );
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.38))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 16), const SizedBox(width: 5), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11))]),
      );
}

BoxDecoration _noticeDecoration(Color color) => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.alphaBlend(color.withValues(alpha: 0.10), const Color(0xF5152A3B)), const Color(0xF5182334)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.72), width: 1.3),
      boxShadow: [const BoxShadow(color: Color(0x88000000), blurRadius: 30, spreadRadius: 2), BoxShadow(color: color.withValues(alpha: 0.16), blurRadius: 24)],
    );
