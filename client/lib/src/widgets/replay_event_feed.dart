import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/replay_event_formatter.dart';
import '../models/relay_models.dart';
import '../theme/relay_theme.dart';

class ReplayEventFeed extends StatefulWidget {
  const ReplayEventFeed({
    required this.events,
    required this.visibleTick,
    required this.formatter,
    required this.match,
    required this.replay,
    required this.complete,
    this.currentLeftHp,
    this.currentRightHp,
    this.compact = false,
    this.controls,
    super.key,
  });

  final List<BattleEvent> events;
  final int visibleTick;
  final ReplayEventFormatter formatter;
  final MatchResponse match;
  final ReplayResponse replay;
  final bool complete;
  final double? currentLeftHp;
  final double? currentRightHp;
  final bool compact;
  final Widget? controls;

  @override
  State<ReplayEventFeed> createState() => _ReplayEventFeedState();
}

class _ReplayEventFeedState extends State<ReplayEventFeed> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleEvents = widget.events
        .where((event) => event.tick <= widget.visibleTick)
        .toList(growable: false);
    final allVisible = visibleEvents.reversed.toList(growable: false);
    final eventList = Stack(
      children: [
        Positioned.fill(
          child: Scrollbar(
            key: const ValueKey('replay-event-scrollbar'),
            controller: _scrollController,
            thumbVisibility: true,
            interactive: true,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: ListView.separated(
                key: const ValueKey('replay-event-list'),
                controller: _scrollController,
                primary: false,
                itemCount: allVisible.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final event = allVisible[index];
                  return _EventRow(
                    event: event,
                    formatter: widget.formatter,
                    compact: widget.compact,
                  );
                },
              ),
            ),
          ),
        ),
        if (allVisible.isEmpty)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Text(
                  'İlk savaş olayı bekleniyor…',
                  style: TextStyle(color: RelayColors.muted),
                ),
              ),
            ),
          ),
      ],
    );
    final content = Padding(
      padding: EdgeInsets.all(widget.compact ? 11 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: RelayColors.cyan),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CANLI OLAY AKIŞI',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Tüm olaylar • en yeni üstte • kaydırarak okuyun',
                      style: const TextStyle(
                        color: RelayColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${allVisible.length}/${widget.events.length}',
                style: const TextStyle(
                  color: RelayColors.amber,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: widget.compact ? 8 : 12),
          if (widget.compact)
            Expanded(child: eventList)
          else
            SizedBox(height: 245, child: eventList),
          const SizedBox(height: 6),
          _FeedFooter(
            match: widget.match,
            replay: widget.replay,
            complete: widget.complete,
            visibleTick: widget.visibleTick,
            visibleEvents: visibleEvents,
            currentLeftHp:
                widget.currentLeftHp ?? widget.match.result.left.coreMaxHp,
            currentRightHp:
                widget.currentRightHp ?? widget.match.result.right.coreMaxHp,
            compact: widget.compact,
            controls: widget.controls,
          ),
        ],
      ),
    );
    if (widget.compact) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE6102028),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF28515E)),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 12),
          ],
        ),
        child: content,
      );
    }
    return Card(child: content);
  }
}

class _FeedFooter extends StatelessWidget {
  const _FeedFooter({
    required this.match,
    required this.replay,
    required this.complete,
    required this.visibleTick,
    required this.visibleEvents,
    required this.currentLeftHp,
    required this.currentRightHp,
    required this.compact,
    this.controls,
  });

  final MatchResponse match;
  final ReplayResponse replay;
  final bool complete;
  final int visibleTick;
  final List<BattleEvent> visibleEvents;
  final double currentLeftHp;
  final double currentRightHp;
  final bool compact;
  final Widget? controls;

  @override
  Widget build(BuildContext context) {
    final result = match.result;
    final resultLabel = switch (result.winner) {
      'left' => 'ZAFER',
      'right' => 'YENİLGİ',
      _ => 'BERABERE',
    };
    final resultColor = switch (result.winner) {
      'left' => RelayColors.mint,
      'right' => RelayColors.coral,
      _ => RelayColors.amber,
    };
    final detailStyle = TextStyle(
      color: RelayColors.muted,
      fontSize: compact ? 8.5 : 10,
      height: 1.35,
    );
    final decision = result.decision;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: compact ? 150 : 182,
          child: Container(
            key: const ValueKey('inline-server-result'),
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF28515E))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'SUNUCU SONUCU',
                        style: TextStyle(
                          color: RelayColors.cyan,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Text(
                      complete ? resultLabel : 'CANLI • SİNYAL AKIŞI',
                      key: const ValueKey('server-result-status'),
                      style: TextStyle(
                        color: complete ? resultColor : RelayColors.amber,
                        fontSize: compact ? 10.5 : 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (complete) ...[
                  Text(
                    _decisionExplanation(result),
                    style: detailStyle.copyWith(
                      color: resultColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _DecisionTable(
                    decision: decision,
                    compact: compact,
                    highlightColor: resultColor,
                  ),
                ] else ...[
                  Text(
                    'Sunucunun replay verileri oynatılıyor; '
                    'değerler akış boyunca güncelleniyor.',
                    style: detailStyle.copyWith(
                      color: RelayColors.amber,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _LiveBattleTable(
                    match: match,
                    events: visibleEvents,
                    leftCoreHp: currentLeftHp,
                    rightCoreHp: currentRightHp,
                    compact: compact,
                  ),
                ],
                const Spacer(),
                Text(
                  '${visibleEvents.length}/${replay.events.length} olay • '
                  'sunucu doğrulaması ${replay.checksum.substring(0, 8)}…',
                  style: detailStyle,
                ),
              ],
            ),
          ),
        ),
        if (controls != null) ...[const SizedBox(height: 6), controls!],
      ],
    );
  }

  String _decisionExplanation(MatchResult result) {
    if (result.reason == 'core_destroyed') {
      return result.winner == 'left'
          ? 'Karar: Rakip çekirdeği yok edildi.'
          : 'Karar: Senin çekirdeğin yok edildi.';
    }
    if (result.reason == 'mutual_core_destruction') {
      return 'Karar: İki çekirdek aynı adımda yok edildi.';
    }
    if (result.decision.criterion == 'exact_draw') {
      return 'Karar: Altı süre sonu ölçütünün tamamı eşit.';
    }

    DecisionMetric? decisive;
    for (final metric in result.decision.metrics) {
      if (metric.key == result.decision.criterion) {
        decisive = metric;
        break;
      }
    }
    if (decisive == null) {
      return 'Karar: Sunucu süre sonu ölçütlerini uyguladı.';
    }
    final preference = decisive.preferred == 'lower'
        ? 'daha düşük değer kazandırdı'
        : 'daha yüksek değer kazandırdı';
    return 'Karar: ${_metricLabel(decisive.key)}; $preference.';
  }
}

class _LiveBattleTable extends StatelessWidget {
  const _LiveBattleTable({
    required this.match,
    required this.events,
    required this.leftCoreHp,
    required this.rightCoreHp,
    required this.compact,
  });

  final MatchResponse match;
  final List<BattleEvent> events;
  final double leftCoreHp;
  final double rightCoreHp;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    var leftDamage = 0.0;
    var rightDamage = 0.0;
    var leftEvents = 0;
    var rightEvents = 0;
    final destroyedLeft = <String>{};
    final destroyedRight = <String>{};
    for (final event in events) {
      final fromLeft = event.side == 'left';
      if (fromLeft) {
        leftEvents += 1;
      } else {
        rightEvents += 1;
      }
      if (event.type == 'attack' || event.type == 'core_damage') {
        if (fromLeft) {
          leftDamage += event.amount;
        } else {
          rightDamage += event.amount;
        }
      }
      if (event.type == 'destroyed' && event.targetId != null) {
        if (fromLeft) {
          destroyedRight.add(event.targetId!);
        } else {
          destroyedLeft.add(event.targetId!);
        }
      }
    }
    final leftModules = math.max(
      0,
      match.playerBoard.modules.length - destroyedLeft.length,
    );
    final rightModules = math.max(
      0,
      match.opponentBoard.modules.length - destroyedRight.length,
    );
    final style = TextStyle(
      color: RelayColors.muted,
      fontSize: compact ? 7.8 : 9.5,
      height: 1.2,
      fontWeight: FontWeight.w700,
    );

    return Table(
      key: const ValueKey('live-server-metrics'),
      columnWidths: const {
        0: FlexColumnWidth(1.55),
        1: FlexColumnWidth(0.8),
        2: FlexColumnWidth(0.8),
      },
      children: [
        _row('ÖLÇÜT', 'SEN', 'RAKİP', style),
        _row(
          'Çekirdek canı',
          leftCoreHp.toStringAsFixed(0),
          rightCoreHp.toStringAsFixed(0),
          style,
        ),
        _row('Kalan modül', '$leftModules', '$rightModules', style),
        _row(
          'Oynatılan hasar',
          leftDamage.toStringAsFixed(0),
          rightDamage.toStringAsFixed(0),
          style,
        ),
        _row('Olay sayısı', '$leftEvents', '$rightEvents', style),
      ],
    );
  }

  TableRow _row(String label, String left, String right, TextStyle style) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Text(label, style: style),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Text(left, textAlign: TextAlign.right, style: style),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Text(right, textAlign: TextAlign.right, style: style),
        ),
      ],
    );
  }
}

class _DecisionTable extends StatelessWidget {
  const _DecisionTable({
    required this.decision,
    required this.compact,
    required this.highlightColor,
  });

  final BattleDecision decision;
  final bool compact;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 7.8 : 9.5;
    final baseStyle = TextStyle(
      color: RelayColors.muted,
      fontSize: fontSize,
      height: 1.2,
      fontWeight: FontWeight.w700,
    );
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.55),
        1: FlexColumnWidth(0.8),
        2: FlexColumnWidth(0.8),
      },
      children: [
        TableRow(
          children: [
            Text('ÖLÇÜT', style: baseStyle),
            Text('SEN', textAlign: TextAlign.right, style: baseStyle),
            Text('RAKİP', textAlign: TextAlign.right, style: baseStyle),
          ],
        ),
        for (final metric in decision.metrics) _metricRow(metric, baseStyle),
      ],
    );
  }

  TableRow _metricRow(DecisionMetric metric, TextStyle baseStyle) {
    final decisive = metric.key == decision.criterion;
    final style = decisive
        ? baseStyle.copyWith(color: highlightColor, fontWeight: FontWeight.w900)
        : baseStyle;
    final marker = decisive ? '  ← KARAR' : '';
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Text('${_metricLabel(metric.key)}$marker', style: style),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Text(
            _metricValue(metric.key, metric.leftValue),
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Text(
            _metricValue(metric.key, metric.rightValue),
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
      ],
    );
  }
}

String _metricLabel(String key) => switch (key) {
  'core_hp_ratio' => 'Çekirdek canı',
  'surviving_modules' => 'Kalan modül',
  'module_hp_ratio' => 'Modül canı',
  'total_damage' => 'Toplam hasar',
  'damage_efficiency' => 'Hasar/enerji',
  'total_heat' => 'Toplam ısı ↓',
  _ => key,
};

String _metricValue(String key, double value) => switch (key) {
  'core_hp_ratio' ||
  'module_hp_ratio' => '%${(value * 100).toStringAsFixed(1)}',
  'surviving_modules' => value.toStringAsFixed(0),
  'damage_efficiency' => value.toStringAsFixed(3),
  _ => value.toStringAsFixed(1),
};

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.formatter,
    required this.compact,
  });

  final BattleEvent event;
  final ReplayEventFormatter formatter;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.type);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 34 : 44,
            child: Text(
              '#${event.tick}',
              style: const TextStyle(
                color: RelayColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(_eventIcon(event.type), color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.type == 'overload'
                      ? 'SİSTEM'
                      : formatter.sideLabel(event.side),
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
                Text(
                  formatter.eventLabel(event),
                  maxLines: null,
                  overflow: TextOverflow.visible,
                  style: TextStyle(fontSize: compact ? 9.5 : 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _eventIcon(String type) => switch (type) {
    'attack' || 'core_damage' => Icons.flash_on,
    'shield' || 'shield_absorb' => Icons.shield_outlined,
    'cool' => Icons.ac_unit,
    'repair' || 'recovered' => Icons.build_outlined,
    'overheat' => Icons.device_thermostat,
    'destroyed' => Icons.close,
    'energy_starved' => Icons.battery_alert_outlined,
    _ => Icons.circle_outlined,
  };

  Color _eventColor(String type) => switch (type) {
    'attack' || 'core_damage' || 'destroyed' => RelayColors.coral,
    'shield' || 'shield_absorb' => const Color(0xFF74A7FF),
    'cool' => RelayColors.cyan,
    'repair' || 'recovered' => RelayColors.mint,
    'overheat' || 'energy_starved' => RelayColors.amber,
    _ => RelayColors.muted,
  };
}
