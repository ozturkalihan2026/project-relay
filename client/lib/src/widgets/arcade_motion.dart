import 'package:flutter/material.dart';

/// Masaüstünde kartlara hafif bir oyun hissi veren hover yükselmesi.
/// Dokunmatik cihazlarda normal boyutta kalır.
class ArcadeHoverLift extends StatefulWidget {
  const ArcadeHoverLift({
    required this.child,
    this.scale = 1.012,
    super.key,
  });

  final Widget child;
  final double scale;

  @override
  State<ArcadeHoverLift> createState() => _ArcadeHoverLiftState();
}

class _ArcadeHoverLiftState extends State<ArcadeHoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: !animationsDisabled && _hovered ? widget.scale : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
