import '../models/relay_models.dart';

class ReplayFrame {
  const ReplayFrame({required this.tick, required this.events});

  final int tick;
  final List<BattleEvent> events;
}

class ReplayPlaybackCursor {
  ReplayPlaybackCursor(List<BattleEvent> events)
      : _frames = _groupByTick(events);

  final List<ReplayFrame> _frames;
  int _index = 0;

  int get frameCount => _frames.length;
  bool get isComplete => _index >= _frames.length;
  int get currentTick => _index == 0 ? 0 : _frames[_index - 1].tick;

  ReplayFrame? next() {
    if (isComplete) {
      return null;
    }
    final frame = _frames[_index];
    _index += 1;
    return frame;
  }

  void reset() {
    _index = 0;
  }

  static List<ReplayFrame> _groupByTick(List<BattleEvent> events) {
    final grouped = <int, List<BattleEvent>>{};
    for (final event in events) {
      grouped.putIfAbsent(event.tick, () => <BattleEvent>[]).add(event);
    }
    final ticks = grouped.keys.toList()..sort();
    return [
      for (final tick in ticks)
        ReplayFrame(
          tick: tick,
          events: List<BattleEvent>.unmodifiable(grouped[tick]!),
        ),
    ];
  }
}
