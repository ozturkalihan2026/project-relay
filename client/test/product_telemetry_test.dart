import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/state/product_telemetry.dart';

void main() {
  test('izin açıkken sözlük olayını kimlik ve bağlamla gönderir', () async {
    String? receivedId;
    String? receivedName;
    Map<String, Object?>? receivedContext;
    final telemetry = ProductTelemetry(
      isEnabled: () => true,
      send: ({
        required eventId,
        required eventName,
        required context,
        required occurredAt,
      }) async {
        receivedId = eventId;
        receivedName = eventName;
        receivedContext = context;
      },
    );

    telemetry.track(
      'mode_selected',
      context: const {'mode': 'career'},
    );
    await Future<void>.delayed(Duration.zero);

    expect(receivedId, startsWith('evt:'));
    expect(receivedName, 'mode_selected');
    expect(receivedContext, const {'mode': 'career'});
  });

  test('izin kapalıyken hiçbir olay göndermez', () async {
    var sends = 0;
    final telemetry = ProductTelemetry(
      isEnabled: () => false,
      send: ({
        required eventId,
        required eventName,
        required context,
        required occurredAt,
      }) async {
        sends += 1;
      },
    );

    telemetry.track('sandbox_opened');
    await Future<void>.delayed(Duration.zero);

    expect(sends, 0);
  });
}
