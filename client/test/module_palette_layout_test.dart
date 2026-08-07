import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/widgets/module_palette.dart';

void main() {
  testWidgets('dar palette geri bırakma uyarısı taşmadan render edilir', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 162,
              child: ModulePaletteReturnBanner(),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('return')), findsOneWidget);
    expect(find.text('BURAYA BIRAK: KARTTAN KALDIR'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final bannerSize = tester.getSize(
      find.byType(ModulePaletteReturnBanner),
    );
    expect(bannerSize.width, 162);
    expect(bannerSize.height, greaterThan(0));
  });
}
