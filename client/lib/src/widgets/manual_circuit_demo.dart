import 'dart:async';

import 'package:flutter/material.dart';

import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import 'module_visuals.dart';

class ManualCircuitDemo extends StatefulWidget {
  const ManualCircuitDemo({super.key});

  @override
  State<ManualCircuitDemo> createState() => _ManualCircuitDemoState();
}

class _ManualCircuitDemoState extends State<ManualCircuitDemo> {
  static const _steps = [
    _DemoStep(
      title: 'Jeneratör enerji üretti',
      detail: 'Savaş adımı başında devreye 8 enerji girdi.',
    ),
    _DemoStep(
      title: 'Pasif çekirdek dağıttı',
      detail:
          'Enerji üretmeyen çekirdek, gücü portu açık diğer kapılara '
          'iletti.',
    ),
    _DemoStep(
      title: 'Lazer ateşledi',
      detail: 'Lazer 4 enerji harcadı, 8 hasar üretti ve beklemeye geçti.',
    ),
    _DemoStep(
      title: 'Rakip baskı altına girdi',
      detail: 'Hasar önce rakip modüle, modül kalmadığında çekirdeğe gider.',
    ),
  ];

  Timer? _timer;
  int _step = -1;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    _timer?.cancel();
    setState(() {
      _step = 0;
      _running = true;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 950), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_step >= _steps.length - 1) {
        timer.cancel();
        setState(() => _running = false);
        return;
      }
      setState(() => _step += 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _step < 0
        ? const _DemoStep(
            title: 'Örnek devre hazır',
            detail: 'Enerjinin üretimden hasara kadar ilerleyişini izleyin.',
          )
        : _steps[_step];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x99101E25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF28515E)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ÖRNEK OYNANIŞ DEVRESİ',
              style: TextStyle(
                color: RelayColors.amber,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Jeneratör → pasif çekirdek → diğer kapı → Lazer',
              style: TextStyle(color: RelayColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 560) {
                  return Column(
                    children: [
                      _DemoNode(
                        kind: ModuleKind.generator,
                        title: 'Jeneratör',
                        active: _step >= 0,
                        caption: '+8 enerji',
                      ),
                      _VerticalFlow(active: _step >= 1),
                      _CoreDemoNode(active: _step >= 1),
                      _VerticalFlow(active: _step >= 2),
                      _DemoNode(
                        kind: ModuleKind.laser,
                        title: 'Lazer',
                        active: _step >= 2,
                        caption: '−4 enerji / 8 hasar',
                      ),
                      _VerticalFlow(active: _step >= 3),
                      _TargetNode(active: _step >= 3),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _DemoNode(
                        kind: ModuleKind.generator,
                        title: 'Jeneratör',
                        active: _step >= 0,
                        caption: '+8 enerji',
                      ),
                    ),
                    _HorizontalFlow(active: _step >= 1),
                    Expanded(child: _CoreDemoNode(active: _step >= 1)),
                    _HorizontalFlow(active: _step >= 2),
                    Expanded(
                      child: _DemoNode(
                        kind: ModuleKind.laser,
                        title: 'Lazer',
                        active: _step >= 2,
                        caption: '−4 enerji / 8 hasar',
                      ),
                    ),
                    _HorizontalFlow(active: _step >= 3),
                    Expanded(child: _TargetNode(active: _step >= 3)),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Column(
                key: ValueKey(current.title),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    current.detail,
                    style: const TextStyle(
                      color: RelayColors.muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _running ? null : _play,
              icon: Icon(
                _step == _steps.length - 1 ? Icons.replay : Icons.play_arrow,
              ),
              label: Text(
                _step == _steps.length - 1
                    ? 'ÖRNEĞİ YENİDEN OYNAT'
                    : 'ÖRNEK AKIŞI OYNAT',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoNode extends StatelessWidget {
  const _DemoNode({
    required this.kind,
    required this.title,
    required this.active,
    required this.caption,
  });

  final ModuleKind kind;
  final String title;
  final bool active;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final color = moduleColor(kind);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.16) : const Color(0xFF10242D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? color : const Color(0xFF31515C),
          width: active ? 2 : 1,
        ),
        boxShadow: active
            ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 12)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ModuleHardware(kind: kind, color: color, size: 30),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(color: RelayColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _TargetNode extends StatelessWidget {
  const _TargetNode({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active
            ? RelayColors.coral.withValues(alpha: 0.16)
            : const Color(0xFF10242D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? RelayColors.coral : const Color(0xFF31515C),
          width: active ? 2 : 1,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gps_fixed, color: RelayColors.coral),
          SizedBox(height: 6),
          Text(
            'Rakip Hedef',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          Text(
            '−8 can',
            style: TextStyle(color: RelayColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _CoreDemoNode extends StatelessWidget {
  const _CoreDemoNode({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active
            ? RelayColors.cyan.withValues(alpha: 0.16)
            : const Color(0xFF10242D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? RelayColors.cyan : const Color(0xFF31515C),
          width: active ? 2 : 1,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_outlined, color: RelayColors.cyan),
          SizedBox(height: 6),
          Text(
            'Pasif Çekirdek',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          Text(
            '0 üretim / 4 kapı',
            style: TextStyle(color: RelayColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _HorizontalFlow extends StatelessWidget {
  const _HorizontalFlow({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Icon(
        Icons.arrow_forward,
        color: active ? RelayColors.cyan : const Color(0xFF31515C),
      ),
    );
  }
}

class _VerticalFlow extends StatelessWidget {
  const _VerticalFlow({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Icon(
        Icons.arrow_downward,
        color: active ? RelayColors.cyan : const Color(0xFF31515C),
      ),
    );
  }
}

class _DemoStep {
  const _DemoStep({required this.title, required this.detail});

  final String title;
  final String detail;
}
