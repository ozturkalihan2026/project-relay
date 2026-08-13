import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import 'app_settings.dart';

final productTelemetryProvider = Provider<ProductTelemetry>((ref) {
  return ProductTelemetry(
    isEnabled: () => ref.read(appSettingsProvider).telemetryEnabled,
    send: ({
      required eventId,
      required eventName,
      required context,
      required occurredAt,
    }) async {
      await ref.read(guestSessionProvider.future);
      await ref.read(relayApiProvider).submitProductEvent(
            eventId: eventId,
            eventName: eventName,
            context: context,
            occurredAt: occurredAt,
          );
    },
  );
});

typedef ProductEventSender = Future<void> Function({
  required String eventId,
  required String eventName,
  required Map<String, Object?> context,
  required DateTime occurredAt,
});

class ProductTelemetry {
  ProductTelemetry({
    required bool Function() isEnabled,
    required ProductEventSender send,
  })  : _isEnabled = isEnabled,
        _send = send;

  final bool Function() _isEnabled;
  final ProductEventSender _send;
  int _sequence = 0;

  void track(
    String eventName, {
    Map<String, Object?> context = const {},
  }) {
    if (!_isEnabled()) return;
    final occurredAt = DateTime.now().toUtc();
    final eventId = 'evt:${occurredAt.microsecondsSinceEpoch.toRadixString(36)}:'
        '${_sequence++}';
    unawaited(
      _send(
        eventId: eventId,
        eventName: eventName,
        context: context,
        occurredAt: occurredAt,
      ).catchError((_) {
        // Ölçüm hattı hiçbir zaman oyuncu akışını engellemez.
      }),
    );
  }
}
