import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_support.dart';

void main() {
  setUpAll(enableStrictWidgetTestMode);

  testWidgets(
    'benzersiz kaydırıcı yardımcısı iç içe Scrollable alanlarını ayırır',
    (tester) async {
      const rootKey = ValueKey('nested-scroll-root');
      const targetKey = ValueKey('nested-scroll-target');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              key: rootKey,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 180,
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [Text('İç kaydırıcı')],
                  ),
                ),
                const SizedBox(height: 900),
                const FilledButton(
                  key: targetKey,
                  onPressed: null,
                  child: Text('Hedef'),
                ),
              ],
            ),
          ),
        ),
      );

      final scrollable = findUniqueScrollableWithin(
        root: find.byKey(rootKey),
        axisDirection: AxisDirection.down,
        physicsMatches: (physics) => physics is AlwaysScrollableScrollPhysics,
        description: 'iç içe dikey test kaydırıcısı',
      );

      expect(scrollable, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(rootKey),
          matching: find.byType(Scrollable),
        ),
        findsNWidgets(2),
      );
    },
  );

  testWidgets(
    'kaydırma yardımcısı tembel oluşturulan hedefi bulur ve görünür yapar',
    (tester) async {
      const rootKey = ValueKey('lazy-scroll-root');
      const targetKey = ValueKey('lazy-scroll-target');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              key: rootKey,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: 42,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return SizedBox(
                    height: 160,
                    child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [Text('İç tembel kaydırıcı')],
                    ),
                  );
                }
                if (index == 41) {
                  return FilledButton(
                    key: targetKey,
                    onPressed: () {},
                    child: const Text('Tembel hedef'),
                  );
                }
                return SizedBox(
                  height: 96,
                  child: Center(child: Text('Satır $index')),
                );
              },
            ),
          ),
        ),
      );

      final target = find.byKey(targetKey);
      expect(target, findsNothing);

      final scrollable = findUniqueScrollableWithin(
        root: find.byKey(rootKey),
        axisDirection: AxisDirection.down,
        physicsMatches: (physics) => physics is AlwaysScrollableScrollPhysics,
        description: 'tembel hedef ana kaydırıcısı',
      );

      await scrollIntoView(
        tester: tester,
        target: target,
        scrollable: scrollable,
        delta: 320,
      );

      expect(target, findsOneWidget);
      expect(target.hitTestable(), findsOneWidget);
    },
  );

}
