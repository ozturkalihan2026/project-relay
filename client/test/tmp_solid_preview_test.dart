import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/models/relay_models.dart';
import 'package:project_relay_client/src/widgets/module_visuals.dart';

void main() {
  testWidgets('solid preview', (tester) async {
    const size = 760.0;
    const cell = 190.0;
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, size, size),
        Paint()..color = const Color(0xFF0D2233),
      );
      for (var index = 0; index < ModuleKind.values.length; index += 1) {
        final kind = ModuleKind.values[index];
        final column = index % 2;
        final row = index ~/ 2;
        final center = Offset(
          cell * column + cell / 2,
          cell * row + cell * 0.52,
        );
        paintModuleHardware(
          canvas,
          kind,
          center,
          92,
          moduleColor(kind),
        );
        final label = TextPainter(
          text: TextSpan(
            text: kind.displayName,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(
          canvas,
          Offset(
            cell * column + (cell - label.width) / 2,
            cell * row + 12,
          ),
        );
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        r'C:\Users\S-A\AppData\Local\Temp\opencode\solid_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
