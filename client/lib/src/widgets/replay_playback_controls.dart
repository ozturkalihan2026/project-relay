import 'package:flutter/material.dart';

import '../theme/relay_theme.dart';

class ReplayPlaybackControls extends StatelessWidget {
  const ReplayPlaybackControls({
    required this.playing,
    required this.soundEnabled,
    required this.speed,
    required this.onTogglePlayback,
    required this.onRestart,
    required this.onToggleSound,
    required this.onSpeedChanged,
    required this.onNewGame,
    this.primaryActionLabel = 'YENİ OYUN',
    this.primaryActionKey = 'replay-new-game-button',
    this.primaryActionEnabled = true,
    super.key,
  });

  final bool playing;
  final bool soundEnabled;
  final double speed;
  final VoidCallback onTogglePlayback;
  final VoidCallback onRestart;
  final VoidCallback onToggleSound;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onNewGame;
  final String primaryActionLabel;
  final String primaryActionKey;
  final bool primaryActionEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('replay-playback-controls'),
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF28515E))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final controls = <Widget>[
                _ControlButton(
                  key: const ValueKey('replay-playback-button'),
                  icon: playing ? Icons.pause : Icons.play_arrow,
                  label: playing ? 'Duraklat' : 'Devam Et',
                  onPressed: onTogglePlayback,
                ),
                _ControlButton(
                  key: const ValueKey('replay-restart-button'),
                  icon: Icons.replay,
                  label: 'Yeniden Oynat',
                  onPressed: onRestart,
                ),
                _ControlButton(
                  key: const ValueKey('replay-sound-button'),
                  icon: soundEnabled ? Icons.volume_up : Icons.volume_off,
                  label: soundEnabled ? 'Ses Açık' : 'Ses Kapalı',
                  onPressed: onToggleSound,
                ),
                PopupMenuButton<double>(
                  key: const ValueKey('replay-speed-button'),
                  tooltip: 'Oynatma hızını seç',
                  initialValue: speed,
                  padding: EdgeInsets.zero,
                  onSelected: onSpeedChanged,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 0.75, child: Text('0.75×')),
                    PopupMenuItem(value: 1, child: Text('1×')),
                    PopupMenuItem(value: 1.25, child: Text('1.25×')),
                    PopupMenuItem(value: 1.5, child: Text('1.5×')),
                    PopupMenuItem(value: 2, child: Text('2×')),
                  ],
                  child: _ControlSurface(
                    icon: Icons.speed,
                    label: 'Hız ${_speedLabel(speed)}',
                  ),
                ),
              ];

              if (constraints.maxWidth >= 500) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0;
                          index < controls.length;
                          index++) ...[
                        if (index > 0) const SizedBox(width: 6),
                        controls[index],
                      ],
                    ],
                  ),
                );
              }

              return Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: controls,
              );
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 220,
            height: 40,
            child: FilledButton(
              key: ValueKey(primaryActionKey),
              onPressed: primaryActionEnabled ? onNewGame : null,
              style: FilledButton.styleFrom(
                backgroundColor: RelayColors.cyan,
                foregroundColor: const Color(0xFF07161C),
                disabledBackgroundColor: const Color(0xFF24434C),
                disabledForegroundColor: RelayColors.muted,
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 9),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(primaryActionLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: RelayColors.cyan,
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
        side: const BorderSide(color: Color(0xFF315E6B)),
      ),
    );
  }
}

class _ControlSurface extends StatelessWidget {
  const _ControlSurface({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF132832),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF315E6B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: RelayColors.cyan),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: RelayColors.cyan,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: RelayColors.muted,
          ),
        ],
      ),
    );
  }
}

String _speedLabel(double speed) => switch (speed) {
      0.75 => '0.75×',
      1.25 => '1.25×',
      1.5 => '1.5×',
      2 => '2×',
      _ => '1×',
    };
