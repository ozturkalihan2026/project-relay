import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget testlerinde görünmeyen veya başka bir widget tarafından kapatılan
/// hedeflere yapılan tap çağrılarını uyarı olarak bırakmak yerine doğrudan
/// test hatasına dönüştürür.
void enableStrictWidgetTestMode() {
  WidgetController.hitTestWarningShouldBeFatal = true;
}

/// Bir ekran bölümü içindeki asıl kaydırma alanını benzersiz biçimde bulur.
///
/// Bazı Project Relay ekranlarında devre kartı gibi iç bileşenler kendi
/// `Scrollable` nesnelerini üretir. Yalnız eksene bakmak birden fazla sonuç
/// döndürebilir. Bu yardımcı hem ekseni hem de fizik türünü denetleyerek dış
/// ekran kaydırıcısını iç kaydırıcılardan ayırır.
Finder findUniqueScrollableWithin({
  required Finder root,
  required AxisDirection axisDirection,
  required bool Function(ScrollPhysics? physics) physicsMatches,
  required String description,
}) {
  expect(
    root,
    findsOneWidget,
    reason: '$description için kök ekran bölümü benzersiz olmalıdır.',
  );

  final scrollable = find.descendant(
    of: root,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          widget.axisDirection == axisDirection &&
          physicsMatches(widget.physics),
      description: description,
    ),
  );

  expect(
    scrollable,
    findsOneWidget,
    reason:
        '$description için eksen ve fizik filtresine uyan tek Scrollable bulunmalıdır.',
  );
  return scrollable;
}

/// Hedefi belirtilen kaydırma alanında görünür hâle getirir ve gerçekten
/// tıklanabilir bir noktaya ulaştığını doğrular.
Future<void> scrollIntoView({
  required WidgetTester tester,
  required Finder target,
  required Finder scrollable,
  double delta = 300,
  int maxScrolls = 50,
}) async {
  expect(
    scrollable,
    findsOneWidget,
    reason: 'Kaydırma alanı benzersiz olmalıdır.',
  );

  // ListView ve GridView hedefleri tembel (lazy) üretebilir. Bu nedenle hedefin
  // kaydırmadan önce widget ağacında bulunmasını zorunlu tutmuyoruz. Ancak aynı
  // anahtarla birden fazla hedef zaten oluşturulmuşsa bunu erken yakalıyoruz.
  final initialTargetCount = target.evaluate().length;
  expect(
    initialTargetCount <= 1,
    isTrue,
    reason:
        'Kaydırılacak hedef kaydırma öncesinde en fazla bir kez bulunmalıdır.',
  );

  if (initialTargetCount == 0) {
    final distance = delta.abs();
    var attempts = 0;
    while (target.evaluate().isEmpty && attempts < maxScrolls) {
      final position = tester.state<ScrollableState>(scrollable).position;
      final forward =
          position.axisDirection == AxisDirection.down ||
          position.axisDirection == AxisDirection.right;
      final next = (position.pixels + (forward ? distance : -distance))
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if (next == position.pixels) break;
      position.jumpTo(next);
      await tester.pump();
      attempts += 1;
    }
  }
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();

  expect(
    target,
    findsOneWidget,
    reason:
        'Kaydırma tamamlandığında hedef oluşturulmuş ve benzersiz olmalıdır.',
  );
  expect(
    target.hitTestable(),
    findsOneWidget,
    reason: 'Hedef görünür olduktan sonra tıklanabilir olmalıdır.',
  );
}

/// Görünürlük kontrolünden sonra güvenli biçimde tap yapar.
Future<void> tapVisible({
  required WidgetTester tester,
  required Finder target,
}) async {
  expect(
    target,
    findsOneWidget,
    reason: 'Tıklanacak hedef benzersiz olmalıdır.',
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}
