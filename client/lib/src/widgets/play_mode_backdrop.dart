import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';

/// Oyna ekranında dikkat dağıtmadan oyunun 4x4 devre yapısını hatırlatan
/// düşük opaklıklı arka plan kompozisyonu.
class PlayModeBackdrop extends StatelessWidget {
  const PlayModeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _PlayModeBackdropPainter(),
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}

class _PlayModeBackdropPainter extends CustomPainter {
  const _PlayModeBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final extent = math.max(size.width, size.height) * 1.06;
    final left = (size.width - extent) / 2;
    final top = (size.height - extent) / 2;
    final board = Rect.fromLTWH(left, top, extent, extent);
    final cell = extent / 4;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    canvas.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(24)),
      Paint()
        ..color = RelayColors.cyan.withValues(alpha: 0.018)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(24)),
      Paint()
        ..color = RelayColors.cyan.withValues(alpha: 0.065)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 4; column++) {
        final rect = Rect.fromLTWH(
          board.left + column * cell + 5,
          board.top + row * cell + 5,
          cell - 10,
          cell - 10,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(12)),
          Paint()
            ..color = RelayColors.cyan.withValues(alpha: 0.032)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    final core = Rect.fromLTWH(
      board.left + cell + 6,
      board.top + cell + 6,
      cell * 2 - 12,
      cell * 2 - 12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(core, const Radius.circular(22)),
      Paint()
        ..color = RelayColors.violet.withValues(alpha: 0.032)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(core, const Radius.circular(22)),
      Paint()
        ..color = RelayColors.cyan.withValues(alpha: 0.11)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final center = core.center;
    for (final radius in [core.width * 0.15, core.width * 0.25]) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = RelayColors.cyan.withValues(alpha: 0.055)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    final nodes = <Offset>[
      Offset(board.left + cell * 0.5, board.top + cell * 0.5),
      Offset(board.left + cell * 3.5, board.top + cell * 0.5),
      Offset(board.left + cell * 0.5, board.top + cell * 3.5),
      Offset(board.left + cell * 3.5, board.top + cell * 3.5),
    ];
    final nodeColors = [
      RelayColors.mint,
      RelayColors.amber,
      RelayColors.cyan,
      RelayColors.violet,
    ];
    for (var i = 0; i < nodes.length; i++) {
      canvas.drawLine(
        nodes[i],
        center,
        Paint()
          ..color = nodeColors[i].withValues(alpha: 0.050)
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(
        nodes[i],
        4,
        Paint()..color = nodeColors[i].withValues(alpha: 0.11),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlayModeBackdropPainter oldDelegate) => false;
}
