import 'dart:ui' as ui;

/// Shared cable geometry and paint primitives for preparation and battle.
abstract final class CircuitCableVisual {
  static ui.Path path(ui.Offset from, ui.Offset to) {
    final delta = to - from;
    final distance = delta.distance;
    if (distance < 1) return ui.Path()..moveTo(from.dx, from.dy);
    final direction = delta / distance;
    final normal = ui.Offset(-direction.dy, direction.dx);
    final bend = (distance * 0.10).clamp(2.0, 7.0);
    return ui.Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(
        from.dx + delta.dx * 0.34 + normal.dx * bend,
        from.dy + delta.dy * 0.34 + normal.dy * bend,
        from.dx + delta.dx * 0.66 - normal.dx * bend,
        from.dy + delta.dy * 0.66 - normal.dy * bend,
        to.dx,
        to.dy,
      );
  }

  static void drawCable(
    ui.Canvas canvas,
    ui.Path path, {
    required ui.Color color,
    required bool energized,
    bool emphasized = false,
  }) {
    final outerWidth = emphasized ? 10.5 : 8.5;
    if (energized) {
      canvas.drawPath(
        path,
        ui.Paint()
          ..color = color.withValues(alpha: emphasized ? 0.24 : 0.18)
          ..strokeWidth = emphasized ? 14 : 12
          ..strokeCap = ui.StrokeCap.round
          ..style = ui.PaintingStyle.stroke
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
      );
    }
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = const ui.Color(0xF2050D11)
        ..strokeWidth = outerWidth
        ..strokeCap = ui.StrokeCap.round
        ..style = ui.PaintingStyle.stroke,
    );
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = ui.Color.alphaBlend(
          color.withValues(alpha: energized ? 0.40 : 0.12),
          const ui.Color(0xFF17272E),
        )
        ..strokeWidth = outerWidth - 2.4
        ..strokeCap = ui.StrokeCap.round
        ..style = ui.PaintingStyle.stroke,
    );
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = color.withValues(alpha: energized ? 0.72 : 0.20)
        ..strokeWidth = emphasized ? 1.8 : 1.4
        ..strokeCap = ui.StrokeCap.round
        ..style = ui.PaintingStyle.stroke,
    );
  }

  static void drawPacket(
    ui.Canvas canvas,
    ui.Path path, {
    required double phase,
    required ui.Color color,
    double opacity = 1,
    bool emphasized = false,
  }) {
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty || metrics.first.length < 1) return;
    final metric = metrics.first;
    final normalizedPhase = phase % 1;
    final tangent = metric.getTangentForOffset(metric.length * normalizedPhase);
    if (tangent == null || tangent.vector.distance < 0.001) return;
    final direction = tangent.vector / tangent.vector.distance;
    final center = tangent.position;
    final halfLength = emphasized ? 6.5 : 5.0;
    final start = center - direction * halfLength;
    final end = center + direction * halfLength;

    canvas.drawLine(
      start,
      end,
      ui.Paint()
        ..color = color.withValues(alpha: 0.34 * opacity)
        ..strokeWidth = emphasized ? 7 : 6
        ..strokeCap = ui.StrokeCap.round
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
    );
    canvas.drawLine(
      start,
      end,
      ui.Paint()
        ..color = color.withValues(alpha: 0.92 * opacity)
        ..strokeWidth = emphasized ? 3.2 : 2.6
        ..strokeCap = ui.StrokeCap.round,
    );
    canvas.drawLine(
      center,
      end,
      ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.78 * opacity)
        ..strokeWidth = emphasized ? 1.6 : 1.2
        ..strokeCap = ui.StrokeCap.round,
    );
  }
}
