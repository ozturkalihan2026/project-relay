/// Shared presentation measurements for the preparation and battle boards.
///
/// Flutter widgets and the Flame canvas use different rendering pipelines, but
/// they must describe the same physical board. Keeping the durable geometry
/// here prevents the two scenes from drifting apart again.
abstract final class CircuitPresentationSpec {
  static const int gridSize = 4;

  static const double boardCornerRadius = 20;
  static const double boardBorderWidth = 2;
  static const double boardContentInset = 4;
  static const double cellInset = 4;
  static const double cellCornerRadius = 8;
  static const double coreExtentFactor = 0.48;
  static const double coreCornerRadius = 24;

  static const double preparationPerspectiveDepth = 0.00140;
  static const double preparationDeckTilt = -0.26;
  static const double preparationDeckYaw = 0.008;
  static const double battlePerspectiveShear = 0.018;
  static const double platformDepth = 20;

  static const double moduleDepth = 8;
  static const double compactModuleDepth = 5;
  static const double moduleInset = 4.5;
  static const double compactModuleInset = 2.5;
  static const double battleModuleDepthFactor = 0.065;
}
