import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/widgets/relay_notice.dart';

void main() {
  tearDown(RelayNotice.dismiss);

  testWidgets('seviye atlama bildirimi havai fişek katmanı gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => RelayNotice.showLevelUp(
                context,
                level: 12,
                xp: 80,
                credits: 25,
                soundEnabled: false,
                duration: const Duration(milliseconds: 500),
              ),
              child: const Text('Kutla'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Kutla'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('relay-level-up-fireworks')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('relay-level-up-badge')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.byKey(const ValueKey('relay-level-up-fireworks')),
      findsNothing,
    );
  });
}
