import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/circuit_presentation.dart';
import '../theme/relay_theme.dart';
import 'module_solid3d.dart';

Color moduleColor(ModuleKind kind) => switch (kind) {
  ModuleKind.generator => RelayColors.amber,
  ModuleKind.battery => RelayColors.mint,
  ModuleKind.laser => RelayColors.coral,
  ModuleKind.pulseCannon => const Color(0xFFFF8C42),
  ModuleKind.shield => const Color(0xFF74A7FF),
  ModuleKind.cooler => RelayColors.cyan,
  ModuleKind.amplifier => const Color(0xFFB48CFF),
  ModuleKind.repair => const Color(0xFF62D89A),
};

/// A compact, code-native 2.5D hardware representation of a module.
class ModuleHardware extends StatelessWidget {
  const ModuleHardware({
    required this.kind,
    required this.color,
    this.size = 28,
    this.intensity = 1,
    super.key,
  });

  final ModuleKind kind;
  final Color color;
  final double size;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ModuleHardwarePainter(
          kind: kind,
          color: color,
          intensity: intensity,
        ),
      ),
    );
  }
}

void paintModuleHardware(
  Canvas canvas,
  ModuleKind kind,
  Offset center,
  double size,
  Color color, {
  double intensity = 1,
}) {
  paintModuleSolid3D(
    canvas,
    kind,
    center,
    size,
    color,
    intensity: intensity,
  );
}

class _ModuleHardwarePainter extends CustomPainter {
  const _ModuleHardwarePainter({
    required this.kind,
    required this.color,
    required this.intensity,
  });

  final ModuleKind kind;
  final Color color;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    paintModuleHardware(
      canvas,
      kind,
      center,
      size.shortestSide,
      color,
      intensity: intensity,
    );
  }

  @override
  bool shouldRepaint(covariant _ModuleHardwarePainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.intensity != intensity;
}

IconData directionIcon(RelayDirection direction) => switch (direction) {
  RelayDirection.north => Icons.arrow_upward,
  RelayDirection.east => Icons.arrow_forward,
  RelayDirection.south => Icons.arrow_downward,
  RelayDirection.west => Icons.arrow_back,
};

bool usesConnectionDirectionArrow(ModuleKind kind) => switch (kind) {
  ModuleKind.laser ||
  ModuleKind.pulseCannon ||
  ModuleKind.shield ||
  ModuleKind.cooler ||
  ModuleKind.repair => true,
  _ => false,
};

RelayDirection moduleDisplayDirection(
  ModuleKind kind,
  RelayDirection orientation,
) {
  return usesConnectionDirectionArrow(kind)
      ? orientation.opposite
      : orientation;
}

String moduleDirectionTooltip(ModuleKind kind, RelayDirection orientation) {
  final direction = moduleDisplayDirection(kind, orientation);
  return switch (kind) {
    ModuleKind.generator => 'Jeneratör çekirdeğe dönük kalır',
    ModuleKind.battery =>
      'Dört yönlü kavşak • yalnız kullanılabilir uçlar gösterilir',
    ModuleKind.amplifier => 'Etki yönü: ${direction.displayName}',
    _ => 'Enerji bağlantısı: ${direction.displayName}',
  };
}

/// Raised hardware shell used by placed modules and drag previews.
///
/// The outer widget keeps the full slot hit area while the visible module
/// chassis is inset, cut-cornered and physically lifted above the board.
class ModuleChassis extends StatelessWidget {
  const ModuleChassis({
    required this.accent,
    required this.child,
    this.lifted = false,
    this.animateSeat = false,
    this.compact = false,
    this.animationKey,
    super.key,
  });

  final Color accent;
  final Widget child;
  final bool lifted;
  final bool animateSeat;
  final bool compact;
  final Key? animationKey;

  @override
  Widget build(BuildContext context) {
    Widget buildAt(double settled) {
      final sideDepth = compact
          ? CircuitPresentationSpec.compactModuleDepth
          : CircuitPresentationSpec.moduleDepth;
      final inset = compact
          ? CircuitPresentationSpec.compactModuleInset
          : CircuitPresentationSpec.moduleInset;
      final restingLift = compact ? 1.5 : 3.5;
      final approachLift = compact ? 8.0 : 14.0;
      final extraLift = lifted ? (compact ? 4.0 : 7.0) : 0.0;
      final topLift = restingLift + ((1 - settled) * approachLift) + extraLift;
      final scale = 1 + ((1 - settled) * (compact ? 0.035 : 0.055));

      return Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            left: inset + 1,
            right: inset + 1,
            top: sideDepth + 3,
            bottom: 0,
            child: IgnorePointer(
              child: PhysicalShape(
                clipper: _ModuleChassisClipper(compact: compact),
                elevation: lifted ? 13 : 8,
                shadowColor: Color.alphaBlend(
                  accent.withValues(alpha: lifted ? 0.28 : 0.12),
                  const Color(0xD9000000),
                ),
                color: const Color(0xFF050D11),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.alphaBlend(
                          accent.withValues(alpha: 0.18),
                          const Color(0xFF132830),
                        ),
                        const Color(0xFF030A0D),
                      ],
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: lifted ? 0.72 : 0.38),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, -topLift),
            child: Transform.scale(
              scale: scale,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  inset,
                  compact ? 1.0 : 1.0,
                  inset,
                  sideDepth,
                ),
                child: ClipPath(
                  clipper: _ModuleChassisClipper(compact: compact),
                  child: child,
                ),
              ),
            ),
          ),
          Positioned(
            left: compact ? 12 : 16,
            right: compact ? 12 : 16,
            bottom: compact ? 2 : 3,
            child: IgnorePointer(
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      accent.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (!animateSeat) {
      return buildAt(1);
    }
    return TweenAnimationBuilder<double>(
      key: animationKey,
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      builder: (context, value, _) => buildAt(value),
    );
  }
}

class _ModuleChassisClipper extends CustomClipper<Path> {
  const _ModuleChassisClipper({required this.compact});

  final bool compact;

  @override
  Path getClip(Size size) {
    final cut = size.shortestSide * (compact ? 0.10 : 0.12);
    return Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, cut)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(cut, size.height)
      ..lineTo(0, size.height - cut)
      ..lineTo(0, cut)
      ..close();
  }

  @override
  bool shouldReclip(covariant _ModuleChassisClipper oldClipper) =>
      oldClipper.compact != compact;
}
