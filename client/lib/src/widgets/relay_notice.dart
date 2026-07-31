import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';

enum RelayNoticeTone { info, success, warning, error }

/// Oyun genelinde bildirimleri aynı görünüm ve davranışla gösterir.
///
/// Bildirim, sayfa akışına yer kaplatmaz; kök overlay üzerinde ekranın
/// ortasında görünür. Böylece kaydırılmış sayfalarda ve dar ekranlarda da
/// metin okunabilir kalır.
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
    _dismissTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone;
    final message = widget.message;
    final color = switch (tone) {
      RelayNoticeTone.info => RelayColors.cyan,
      RelayNoticeTone.success => RelayColors.mint,
      RelayNoticeTone.warning => RelayColors.amber,
      RelayNoticeTone.error => RelayColors.coral,
    };
    final icon = switch (tone) {
      RelayNoticeTone.info => Icons.info_outline,
      RelayNoticeTone.success => Icons.check_circle_outline,
      RelayNoticeTone.warning => Icons.warning_amber_rounded,
      RelayNoticeTone.error => Icons.error_outline,
    };

    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          minimum: const EdgeInsets.all(18),
          child: Center(
            child: Semantics(
              liveRegion: true,
              label: message,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 150),
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: child,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      key: const ValueKey('relay-centered-notice'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xEA071820),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.withValues(alpha: 0.88),
                          width: 1.5,
                        ),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: color.withValues(alpha: 0.20),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: color, size: 26),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.35,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
