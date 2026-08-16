import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/relay_models.dart';

/// Draws a module as physical 3D hardware instead of a flat icon box.
///
/// The module is modelled in a 48-unit cell with the board plane on xy and the
/// height on z. Each kind builds a distinct device body that fills the cell;
/// a thin base plate seats it on the board. A fixed camera (yaw + tilt) plus a
/// directional light produce a consistent dimetric look across every scene;
/// faces are sorted back-to-front (painter's algorithm) so stacking works
/// without a z-buffer.
void paintModuleSolid3D(
  Canvas canvas,
  ModuleKind kind,
  Offset center,
  double size,
  Color color, {
  double intensity = 1,
}) {
  final alpha = intensity.clamp(0.18, 1.0).toDouble();
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(size / 48);
  final scene = _SolidScene(canvas, color, alpha);
  scene.paintModule(kind);
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

  static const double _cameraYaw = -0.45;
  static const double _cameraTilt = 0.60;
  static const double _cameraFov = 46;
  static const double _cameraDistance = 100;

  static const double _ambient = 0.48;
  static const double _diffuse = 0.55;
  static const _Vec3 _light = _Vec3(0.15, 0.25, 0.95);

  static const double _baseHeight = 4;

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

  void paintModule(ModuleKind kind) {
    _drawGroundShadow();
    _addBasePlate();
    _addDevice(kind);
    _render();
  }

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
        ..color = const Color(0xFF000000).withValues(alpha: 0.34 * _alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _addBasePlate() {
    final color = Color.alphaBlend(
      _accent.withValues(alpha: 0.18 * _alpha),
      const Color(0xFF0E1A21),
    );
    final height = _baseHeight;
    _addQuad(
      [
        _Vec3(-22, -22, height),
        _Vec3(22, -22, height),
        _Vec3(22, 22, height),
        _Vec3(-22, 22, height),
      ],
      const _Vec3(0, 0, 1),
      color,
      accentEdge: true,
    );
    _addQuad(
      [
        _Vec3(-22, -22, height),
        _Vec3(22, -22, height),
        _Vec3(22, -22, 0),
        _Vec3(-22, -22, 0),
      ],
      const _Vec3(0, -1, 0),
      color,
    );
    _addQuad(
      [
        _Vec3(-22, 22, height),
        _Vec3(22, 22, height),
        _Vec3(22, 22, 0),
        _Vec3(-22, 22, 0),
      ],
      const _Vec3(0, 1, 0),
      color,
    );
    _addQuad(
      [
        _Vec3(22, -22, height),
        _Vec3(22, 22, height),
        _Vec3(22, 22, 0),
        _Vec3(22, -22, 0),
      ],
      const _Vec3(1, 0, 0),
      color,
    );
    _addQuad(
      [
        _Vec3(-22, -22, height),
        _Vec3(-22, 22, height),
        _Vec3(-22, 22, 0),
        _Vec3(-22, -22, 0),
      ],
      const _Vec3(-1, 0, 0),
      color,
    );
  }

  void _addDevice(ModuleKind kind) {
    final z = _baseHeight;
    switch (kind) {
      case ModuleKind.generator:
        _addPrism(8, 14, 16, _Vec3(0, 0, z), _accent);
        _addPrism(8, 16, 2.5, _Vec3(0, 0, z + 16), _brighter(_accent));
        _glowDisc(_Vec3(0, 0, z + 19.5), 4.5, _accent);
        for (var index = 0; index < 3; index += 1) {
          final angle = -math.pi / 2 + index * math.pi * 2 / 3;
          final position = _Vec3(
            math.cos(angle) * 19,
            math.sin(angle) * 19,
            z,
          );
          _addPrism(8, 3.5, 12, position, _accent);
          _glowDisc(
            _Vec3(position.x, position.y, z + 12),
            1.8,
            _accent,
          );
        }
        break;
      case ModuleKind.battery:
        for (var index = 0; index < 3; index += 1) {
          final y = -8.5 + index * 8.5;
          _addPrism(
            8,
            5.5,
            16,
            _Vec3(0, y, z),
            index == 2 ? _brighter(_accent) : _accent,
          );
          _glowDisc(_Vec3(0, y, z + 16), 2.2, _accent);
        }
        _box(_Vec3(0, 0, z + 16), 30, 5, 3, _accent);
        _glowDisc(_Vec3(0, 0, z + 19.5), 4.0, _accent);
        break;
      case ModuleKind.laser:
        _box(_Vec3(0, 0, z), 34, 14, 6, _accent);
        _box(_Vec3(8, 0, z + 8.5), 28, 8, 5, _accent);
        _box(_Vec3(23, 0, z + 8.5), 6, 11, 6, _accent);
        _box(_Vec3(-16, 0, z + 8.5), 8, 12, 5, _accent);
        _box(_Vec3(2, 0, z + 8.5), 3, 12, 4, _accent);
        _box(_Vec3(14, 0, z + 13.5), 7, 2, 3, _accent);
        _glowDisc(_Vec3(26, 0, z + 8.5), 4.5, _accent);
        break;
      case ModuleKind.pulseCannon:
        _box(_Vec3(0, 0, z), 18, 20, 8, _accent);
        _box(_Vec3(6, 0, z + 10), 8, 12, 6, _accent);
        _box(_Vec3(11, -3.5, z + 10), 24, 4, 4.5, _accent);
        _box(_Vec3(11, 3.5, z + 10), 24, 4, 4.5, _accent);
        _box(_Vec3(4, 0, z + 10), 4, 13, 5, _accent);
        _glowDisc(_Vec3(23, -3.5, z + 10), 3.0, _accent);
        _glowDisc(_Vec3(23, 3.5, z + 10), 3.0, _accent);
        break;
      case ModuleKind.shield:
        _addPrism(8, 20, 6, _Vec3(0, 0, z), _accent);
        _addPrism(8, 15, 5, _Vec3(0, 0, z + 6), _accent);
        _addPrism(8, 10, 4, _Vec3(0, 0, z + 11), _brighter(_accent));
        _glowDisc(_Vec3(0, 0, z + 15), 9.0, _accent);
        _glowDisc(_Vec3(0, 0, z + 15), 4.0, _brighter(_accent));
        break;
      case ModuleKind.cooler:
        _addPrism(14, 20, 7, _Vec3(0, 0, z), _accent);
        _addPrism(
          16,
          14,
          0.8,
          _Vec3(0, 0, z + 7),
          const Color(0xFF050A0E),
        );
        for (var index = 0; index < 4; index += 1) {
          final angle = math.pi / 4 + index * math.pi / 2;
          _box(
            _Vec3(
              math.cos(angle) * 8.5,
              math.sin(angle) * 8.5,
              z + 7.8,
            ),
            17,
            3.5,
            3,
            _accent,
            rotate: angle,
          );
        }
        _box(_Vec3(0, 0, z + 7.8), 7, 7, 5, _accent);
        _glowDisc(_Vec3(0, 0, z + 12.8), 2.6, _accent);
        break;
      case ModuleKind.amplifier:
        _box(_Vec3(0, 0, z), 22, 22, 10, _accent);
        _glowDisc(_Vec3(0, 0, z + 10), 4.0, _accent);
        for (final position in const [
          (15.0, -14.0),
          (15.0, 14.0),
          (-17.0, 0.0),
        ]) {
          _addPrism(8, 5, 6, _Vec3(position.$1, position.$2, z), _accent);
          _glowDisc(
            _Vec3(position.$1, position.$2, z + 6),
            2.2,
            _accent,
          );
        }
        break;
      case ModuleKind.repair:
        _box(_Vec3(0, 0, z), 18, 18, 4, _accent);
        for (final direction in const [
          (-1.0, 0.0),
          (1.0, 0.0),
          (0.0, -1.0),
          (0.0, 1.0),
        ]) {
          final horizontal = direction.$1 != 0;
          _box(
            _Vec3(direction.$1 * 12, direction.$2 * 12, z + 4.5),
            horizontal ? 20 : 6,
            horizontal ? 6 : 20,
            5,
            _accent,
          );
        }
        _box(_Vec3(0, 16, z + 7), 10, 10, 6, _accent);
        _glowDisc(_Vec3(0, 21.5, z + 10.5), 3.5, _accent);
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
      final normal = rotate == 0 ? baseNormal : baseNormal.rotatedZ(rotate);
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
}
