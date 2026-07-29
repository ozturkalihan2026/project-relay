import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/game/replay_timeline.dart';
import 'package:project_relay_client/src/models/relay_models.dart';

void main() {
  test('aynı tick olaylarını tek karede ve sıralı toplar', () {
    final cursor = ReplayPlaybackCursor([
      const BattleEvent(
        tick: 3,
        side: 'left',
        type: 'attack',
        actorId: 'L-1',
        amount: 8,
      ),
      const BattleEvent(
        tick: 1,
        side: 'right',
        type: 'shield',
        actorId: 'R-1',
        amount: 12,
      ),
      const BattleEvent(
        tick: 3,
        side: 'left',
        type: 'core_damage',
        actorId: 'L-1',
        amount: 8,
      ),
    ]);

    expect(cursor.frameCount, 2);
    expect(cursor.next()?.tick, 1);
    final second = cursor.next();
    expect(second?.tick, 3);
    expect(second?.events.length, 2);
    expect(cursor.isComplete, isTrue);
    expect(cursor.next(), isNull);
  });

  test('reset aynı olay akışını baştan oynatır', () {
    final cursor = ReplayPlaybackCursor([
      const BattleEvent(
        tick: 7,
        side: 'left',
        type: 'repair',
        actorId: 'L-REPAIR',
        amount: 11,
      ),
    ]);

    expect(cursor.next()?.tick, 7);
    expect(cursor.isComplete, isTrue);

    cursor.reset();

    expect(cursor.isComplete, isFalse);
    expect(cursor.next()?.tick, 7);
  });
}
