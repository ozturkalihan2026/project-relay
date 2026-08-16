import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/relay_models.dart';

typedef ModuleTopGlyphPainter = void Function(Canvas canvas);

/// Draws a module as physical 3D hardware instead of a flat icon box.
///
/// The module is modelled in a 48-unit cell with the board plane on xy and the
/// height on z. A fixed camera (yaw + tilt) plus a directional light produce a
/// consistent dimetric look across every scene; faces are sorted back-to-front
/// (painter's algorithm) so stacking works without a z-buffer.
void paintModuleSolid3D(
  Canvas canvas,
  ModuleKind kind,
  Offset center,
  double size,
  Color color, {
  double intensity = 1,
  ModuleTopGlyphPainter? topGlyphPainter,
}) {
  final alpha = intensity.clamp(0.18, 1.0).toDouble();
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(size / 48);
  final scene = _SolidScene(canvas, color, alpha);
  scene.paintModule(kind, topGlyphPainter: topGlyphPainter);
  canvas.restore();
}

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  double get length => math.sqrt(x * x + y * y + z * z);

  _Vec3 get normalized {
    final magnitude = length;
    if (magnitude == 0) return const _Vec3(0, 0, 1);
    return _Vec3(x / magnitude, y / magnitude, z / magnitude);
  }

  double dot(_Vec3 other) => x * other.x + y * other.y + z * other.z;

  _Vec3 rotatedZ(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return _Vec3(x * cos - y * sin, x * sin + y * cos, z);
  }
}

class _Projected {
  const _Projected(this.depth, this.scale, this.point);

  final double depth;
  final double scale;
  final Offset point;
}

class _RenderItem {
  const _RenderItem({required this.depth, required this.draw});

  final double depth;
  final void Function(Canvas canvas) draw;
}

class _SolidScene {
  _SolidScene(this._canvas, this._accent, this._alpha);

  final Canvas _canvas;
  final Color _accent;
  final double _alpha;

  static const double _cameraYaw = -0.68;
  static const double _cameraTilt = 0.52;
  static const double _cameraFov = 46;
  static const double _cameraDistance = 96;

  static const double _ambient = 0.48;
  static const double _diffuse = 0.55;
  static const _Vec3 _light = _Vec3(0.15, 0.25, 0.95);

  late final double _cosYaw = math.cos(_cameraYaw);
  late final double _sinYaw = math.sin(_cameraYaw);
  late final double _cosTilt = math.cos(_cameraTilt);
  late final double _sinTilt = math.sin(_cameraTilt);
  late final _Vec3 _viewDirection =
      _Vec3(-_sinTilt * _sinYaw, _sinTilt * _cosYaw, _cosTilt);

  final List<_RenderItem> _items = [];

  _Projected _project(_Vec3 point) {
    final x1 = point.x * _cosYaw + point.y * _sinYaw;
    final y1 = -point.x * _sinYaw + point.y * _cosYaw;
    final depth = y1 * _sinTilt + point.z * _cosTilt + _cameraDistance;
    final scale = _cameraFov / depth;
    return _Projected(
      depth,
      scale,
      Offset(x1 * scale, (y1 * _cosTilt - point.z * _sinTilt) * scale),
    );
  }

  bool _visible(_Vec3 normal) => normal.dot(_viewDirection) > 0.02;

  Color _shade(Color color, _Vec3 normal) {
    final normalDotLight = math.max(0.0, normal.dot(_light.normalized));
    final brightness = math.min(1.0, _ambient + _diffuse * normalDotLight);
    return Color.lerp(const Color(0xFF000000), color, brightness)!;
  }

  Color _brighter(Color color) => Color.lerp(color, Colors.white, 0.32)!;

  void paintModule(
    ModuleKind kind, {
    ModuleTopGlyphPainter? topGlyphPainter,
  }) {
    final chassisHeight = _chassisHeight(kind);
    _drawGroundShadow();
    _addChassis(chassisHeight);
    _addMechanism(kind, chassisHeight);
    if (_usesTopGlyph(kind) && topGlyphPainter != null) {
      _paintTopGlyph(chassisHeight, topGlyphPainter);
    }
    _render();
  }

  double _chassisHeight(ModuleKind kind) => switch (kind) {
    ModuleKind.generator => 13,
    ModuleKind.battery => 15,
    ModuleKind.laser => 8,
    ModuleKind.pulseCannon => 9,
    ModuleKind.shield => 8,
    ModuleKind.cooler => 11,
    ModuleKind.amplifier => 9,
    ModuleKind.repair => 9,
  };

  bool _usesTopGlyph(ModuleKind kind) => switch (kind) {
    ModuleKind.generator ||
    ModuleKind.battery ||
    ModuleKind.amplifier ||
    ModuleKind.repair => true,
    _ => false,
  };

  void _drawGroundShadow() {
    final projected = [
      for (final corner in const [
        (-26.0, -26.0),
        (26.0, -26.0),
        (26.0, 26.0),
        (-26.0, 26.0),
      ])
        _project(_Vec3(corner.$1, corner.$2, 0)).point,
    ];
    _canvas.drawPath(
      Path()..addPolygon(projected, true),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.36 * _alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _addChassis(double height) {
    final color = Color.alphaBlend(
      _accent.withValues(alpha: 0.20 * _alpha),
      const Color(0xFF16252D),
    );
    final topHalf = _Vec3(20, 20, height);
    const baseHalf = _Vec3(22, 22, 0);
    _addQuad(
      [
        _Vec3(-topHalf.x, -topHalf.y, height),
        _Vec3(topHalf.x, -topHalf.y, height),
        _Vec3(baseHalf.x, -baseHalf.y, 0),
        _Vec3(-baseHalf.x, -baseHalf.y, 0),
      ],
      const _Vec3(0, -1, 0),
      color,
    );
    _addQuad(
      [
        _Vec3(-topHalf.x, topHalf.y, height),
        _Vec3(topHalf.x, topHalf.y, height),
        _Vec3(baseHalf.x, baseHalf.y, 0),
        _Vec3(-baseHalf.x, baseHalf.y, 0),
      ],
      const _Vec3(0, 1, 0),
      color,
    );
    _addQuad(
      [
        _Vec3(topHalf.x, -topHalf.y, height),
        _Vec3(topHalf.x, topHalf.y, height),
        _Vec3(baseHalf.x, baseHalf.y, 0),
        _Vec3(baseHalf.x, -baseHalf.y, 0),
      ],
      const _Vec3(1, 0, 0),
      color,
    );
    _addQuad(
      [
        _Vec3(-topHalf.x, -topHalf.y, height),
        _Vec3(-topHalf.x, topHalf.y, height),
        _Vec3(-baseHalf.x, baseHalf.y, 0),
        _Vec3(-baseHalf.x, -baseHalf.y, 0),
      ],
      const _Vec3(-1, 0, 0),
      color,
    );
    _addQuad(
      [
        _Vec3(-topHalf.x, -topHalf.y, height),
        _Vec3(topHalf.x, -topHalf.y, height),
        _Vec3(topHalf.x, topHalf.y, height),
        _Vec3(-topHalf.x, topHalf.y, height),
      ],
      const _Vec3(0, 0, 1),
      color,
      accentEdge: true,
    );
  }

  void _addMechanism(ModuleKind kind, double chassisHeight) {
    switch (kind) {
      case ModuleKind.generator:
        _addPrism(8, 15, 6, _Vec3(0, 0, chassisHeight), _accent);
        _glowDisc(_Vec3(0, 0, chassisHeight + 6), 4.0, _accent);
        for (var index = 0; index < 3; index += 1) {
          final angle = -math.pi / 2 + index * math.pi * 2 / 3;
          final tip = _Vec3(
            math.cos(angle) * 19,
            math.sin(angle) * 19,
            chassisHeight,
          );
          _addPrism(8, 3, 3, tip, _accent);
          _glowDisc(
            _Vec3(tip.x, tip.y, chassisHeight + 3),
            1.6,
            _accent,
          );
        }
        break;
      case ModuleKind.battery:
        for (var index = 0; index < 3; index += 1) {
          final y = -7.0 + index * 7.0;
          _box(
            _Vec3(0, y, chassisHeight),
            17,
            5.5,
            4.5,
            index == 2 ? _brighter(_accent) : _accent,
          );
        }
        _glowDisc(_Vec3(0, 0, chassisHeight + 4.5), 4.5, _accent);
        _box(_Vec3(0, 16, chassisHeight + 1.5), 9, 4, 3, _accent);
        break;
      case ModuleKind.laser:
        _box(_Vec3(-15, 0, chassisHeight + 2), 10, 9, 4, _accent);
        _box(_Vec3(11, 0, chassisHeight + 2.5), 16, 6, 5, _accent);
        _box(_Vec3(4, 0, chassisHeight + 2), 3, 10, 4, _accent);
        _glowDisc(_Vec3(19, 0, chassisHeight + 2.5), 3.2, _accent);
        break;
      case ModuleKind.pulseCannon:
        _box(_Vec3(-12, 0, chassisHeight + 1.5), 10, 12, 3, _accent);
        _box(_Vec3(10, -4, chassisHeight + 2.5), 18, 4.5, 5, _accent);
        _box(_Vec3(10, 4, chassisHeight + 2.5), 18, 4.5, 5, _accent);
        _box(_Vec3(6, 0, chassisHeight + 2.5), 5, 11, 5, _accent);
        _glowDisc(_Vec3(19, -4, chassisHeight + 2.5), 2.2, _accent);
        _glowDisc(_Vec3(19, 4, chassisHeight + 2.5), 2.2, _accent);
        break;
      case ModuleKind.shield:
        _addPrism(8, 16, 3, _Vec3(0, 0, chassisHeight), _accent);
        _addPrism(8, 12, 3, _Vec3(0, 0, chassisHeight + 3), _accent);
        _glowDisc(_Vec3(0, 0, chassisHeight + 6), 6.0, _accent);
        _glowDisc(_Vec3(0, 0, chassisHeight + 6), 2.6, _brighter(_accent));
        break;
      case ModuleKind.cooler:
        _addPrism(14, 16, 6, _Vec3(0, 0, chassisHeight), _accent);
        _addPrism(
          16,
          11,
          0.5,
          _Vec3(0, 0, chassisHeight + 6),
          const Color(0xFF050A0E),
        );
        for (var index = 0; index < 4; index += 1) {
          final angle = math.pi / 4 + index * math.pi / 2;
          _box(
            _Vec3(
              math.cos(angle) * 6.5,
              math.sin(angle) * 6.5,
              chassisHeight + 6.6,
            ),
            12,
            3.2,
            1.2,
            _accent,
            rotate: angle,
          );
        }
        _box(_Vec3(0, 0, chassisHeight + 6.6), 6, 6, 1.4, _accent);
        _glowDisc(_Vec3(0, 0, chassisHeight + 7.2), 2.4, _accent);
        break;
      case ModuleKind.amplifier:
        _box(_Vec3(0, 0, chassisHeight + 2), 11, 11, 4, _accent);
        _glowDisc(_Vec3(0, 0, chassisHeight + 4), 3.2, _accent);
        for (final position in const [
          (11.0, -12.0),
          (11.0, 12.0),
          (-16.0, 0.0),
        ]) {
          _addPrism(
            8,
            3.4,
            3.5,
            _Vec3(position.$1, position.$2, chassisHeight),
            _accent,
          );
          _glowDisc(
            _Vec3(position.$1, position.$2, chassisHeight + 3.5),
            1.8,
            _accent,
          );
        }
        break;
      case ModuleKind.repair:
        _box(_Vec3(0, 0, chassisHeight + 1), 9, 9, 2, _accent);
        for (final direction in const [
          (-1.0, 0.0),
          (1.0, 0.0),
          (0.0, -1.0),
          (0.0, 1.0),
        ]) {
          final horizontal = direction.$1 != 0;
          _box(
            _Vec3(
              direction.$1 * 7,
              direction.$2 * 7,
              chassisHeight + 1.5,
            ),
            horizontal ? 9 : 4,
            horizontal ? 4 : 9,
            3,
            _accent,
          );
        }
        _box(_Vec3(0, 16, chassisHeight + 2), 7, 7, 4, _accent);
        _glowDisc(
          _Vec3(0, 19.6, chassisHeight + 3),
          2.6,
          _accent,
        );
        break;
    }
  }

  void _box(
    _Vec3 center,
    double sx,
    double sy,
    double sz,
    Color color, {
    double rotate = 0,
  }) {
    final corners = <_Vec3>[];
    for (final z in const [0.0, 1.0]) {
      for (final dy in const [-0.5, 0.5]) {
        for (final dx in const [-0.5, 0.5]) {
          var local = _Vec3(dx * sx, dy * sy, z * sz);
          if (rotate != 0) {
            local = local.rotatedZ(rotate);
          }
          corners.add(
            _Vec3(center.x + local.x, center.y + local.y, center.z + local.z),
          );
        }
      }
    }
    const faces = <(double, double, double, List<int>)>[
      (0, 0, 1, [4, 5, 7, 6]),
      (0, 1, 0, [2, 3, 7, 6]),
      (0, -1, 0, [0, 1, 5, 4]),
      (1, 0, 0, [1, 3, 7, 5]),
      (-1, 0, 0, [0, 2, 6, 4]),
    ];
    for (final face in faces) {
      final baseNormal = _Vec3(face.$1, face.$2, face.$3);
      final normal =
          rotate == 0 ? baseNormal : baseNormal.rotatedZ(rotate);
      _addQuad(
        [for (final index in face.$4) corners[index]],
        normal,
        color,
      );
    }
  }

  void _addPrism(
    int sides,
    double radius,
    double height,
    _Vec3 center,
    Color color, {
    double rotate = 0,
  }) {
    final topPoints = <_Vec3>[];
    for (var index = 0; index < sides; index += 1) {
      final angle = rotate + index * math.pi * 2 / sides;
      topPoints.add(
        _Vec3(
          center.x + math.cos(angle) * radius,
          center.y + math.sin(angle) * radius,
          center.z + height,
        ),
      );
    }
    final bottomPoints = [
      for (final point in topPoints) _Vec3(point.x, point.y, center.z),
    ];
    for (var index = 0; index < sides; index += 1) {
      final next = (index + 1) % sides;
      final middle = rotate + (index + 0.5) * math.pi * 2 / sides;
      _addQuad(
        [topPoints[index], topPoints[next], bottomPoints[next], bottomPoints[index]],
        _Vec3(math.cos(middle), math.sin(middle), 0),
        color,
      );
    }
    _addQuad(topPoints, const _Vec3(0, 0, 1), color);
  }

  void _addQuad(
    List<_Vec3> points,
    _Vec3 normal,
    Color color, {
    bool accentEdge = false,
  }) {
    final unitNormal = normal.normalized;
    if (!_visible(unitNormal)) {
      return;
    }
    final projected = points.map(_project).toList();
    final depth = projected.fold<double>(0, (sum, p) => sum + p.depth) /
        projected.length;
    _items.add(
      _RenderItem(
        depth: depth,
        draw: (canvas) {
          final path = Path()..addPolygon(
            [for (final p in projected) p.point],
            true,
          );
          canvas.drawPath(
            path,
            Paint()..color = _shade(color, unitNormal).withValues(alpha: _alpha),
          );
          canvas.drawPath(
            path,
            Paint()
              ..color = accentEdge
                  ? _accent.withValues(alpha: 0.55 * _alpha)
                  : const Color(0x59060B0F).withValues(alpha: _alpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = accentEdge ? 1.4 : 1.1
              ..strokeJoin = StrokeJoin.round,
          );
        },
      ),
    );
  }

  void _paintTopGlyph(double chassisHeight, ModuleTopGlyphPainter painter) {
    final projectedCorners = [
      for (final corner in const [
        (-20.0, -20.0),
        (20.0, -20.0),
        (20.0, 20.0),
        (-20.0, 20.0),
      ])
        _project(_Vec3(corner.$1, corner.$2, chassisHeight)),
    ];
    final glyphDepth =
        projectedCorners.fold<double>(0, (sum, p) => sum + p.depth) /
            projectedCorners.length +
        0.01;
    final clip = Path()..addPolygon(
      [for (final p in projectedCorners) p.point],
      true,
    );
    final affine = _fitAffine(
      const [
        Offset(-24, -24),
        Offset(24, -24),
        Offset(24, 24),
        Offset(-24, 24),
      ],
      [for (final p in projectedCorners) p.point],
    );
    _items.add(
      _RenderItem(
        depth: glyphDepth,
        draw: (canvas) {
          canvas.save();
          canvas.clipPath(clip);
          canvas.transform(affine.storage);
          painter(canvas);
          canvas.restore();
        },
      ),
    );
  }

  void _glowDisc(_Vec3 center, double radius, Color glow) {
    final projected = _project(center);
    _items.add(
      _RenderItem(
        depth: projected.depth + 0.02,
        draw: (canvas) {
          canvas.drawCircle(
            projected.point,
            radius * projected.scale * 3.0,
            Paint()
              ..color = glow.withValues(alpha: 0.28 * _alpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
          canvas.drawCircle(
            projected.point,
            radius * projected.scale,
            Paint()
              ..color = glow.withValues(alpha: 0.92 * _alpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
          );
        },
      ),
    );
  }

  void _render() {
    _items.sort((a, b) => a.depth.compareTo(b.depth));
    for (final item in _items) {
      item.draw(_canvas);
    }
  }

  Matrix4 _fitAffine(List<Offset> source, List<Offset> target) {
    var sxx = 0.0, sxy = 0.0, syy = 0.0;
    var sx = 0.0, sy = 0.0, sn = 0.0;
    var sux = 0.0, svx = 0.0;
    var suy = 0.0, svy = 0.0;
    var sumX = 0.0, sumY = 0.0;
    for (var index = 0; index < source.length; index += 1) {
      final u = source[index].dx;
      final v = source[index].dy;
      final x = target[index].dx;
      final y = target[index].dy;
      sxx += u * u;
      sxy += u * v;
      syy += v * v;
      sx += u;
      sy += v;
      sn += 1;
      sux += u * x;
      svx += v * x;
      suy += u * y;
      svy += v * y;
      sumX += x;
      sumY += y;
    }
    final normal = <List<double>>[
      [sxx, sxy, sx],
      [sxy, syy, sy],
      [sx, sy, sn],
    ];
    final xSolution = _solve3x3(normal, [sux, svx, sumX]);
    final ySolution = _solve3x3(normal, [suy, svy, sumY]);
    return Matrix4(
      xSolution[0],
      ySolution[0],
      0,
      0,
      xSolution[1],
      ySolution[1],
      0,
      0,
      0,
      0,
      1,
      0,
      xSolution[2],
      ySolution[2],
      0,
      1,
    );
  }

  List<double> _solve3x3(List<List<double>> matrix, List<double> vector) {
    double determinant(List<List<double>> m) {
      return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
          m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
          m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
    }

    final base = determinant(matrix);
    return List<double>.generate(3, (column) {
      final replaced = [
        for (var row = 0; row < 3; row += 1)
          [
            for (var entry = 0; entry < 3; entry += 1)
              entry == column ? vector[row] : matrix[row][entry],
          ],
      ];
      return determinant(replaced) / base;
    });
  }
}
