import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _sampleRate = 22050;
const _channels = 2;
const _seconds = 24;

void main() {
  Directory('assets/sounds').createSync(recursive: true);
  _writeLoop('assets/sounds/menu_ambient.wav', battle: false);
  _writeLoop('assets/sounds/battle_ambient.wav', battle: true);
}

void _writeLoop(String path, {required bool battle}) {
  final samples = Int16List(_sampleRate * _seconds * _channels);
  final chords = battle
      ? const <List<double>>[
          [55.00, 82.41, 110.00],
          [58.27, 87.31, 116.54],
          [61.74, 92.50, 123.47],
          [49.00, 73.42, 98.00],
          [51.91, 77.78, 103.83],
          [46.25, 69.30, 92.50],
        ]
      : const <List<double>>[
          [65.41, 98.00, 130.81],
          [73.42, 110.00, 146.83],
          [82.41, 123.47, 164.81],
          [61.74, 92.50, 123.47],
          [69.30, 103.83, 138.59],
          [55.00, 82.41, 110.00],
        ];

  for (var frame = 0; frame < _sampleRate * _seconds; frame++) {
    final t = frame / _sampleRate;
    final chord = chords[(t ~/ 4) % chords.length];
    final edgeFade = math.min(1.0, math.min(t / 0.09, (_seconds - t) / 0.09));

    for (var channel = 0; channel < _channels; channel++) {
      final stereoSide = channel == 0 ? -1.0 : 1.0;
      var value = _pad(chord, t, stereoSide, battle: battle);
      value += _arpeggio(chord, t, stereoSide, battle: battle);
      value += _rhythm(t, stereoSide, battle: battle);
      value += _signalShimmer(t, stereoSide, battle: battle);
      samples[frame * _channels + channel] = (value * edgeFade * 23500)
          .clamp(-32767, 32767)
          .round();
    }
  }

  final bytes = BytesBuilder();
  void word(String value) => bytes.add(value.codeUnits);
  void u16(int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.little);
    bytes.add(data.buffer.asUint8List());
  }

  void u32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    bytes.add(data.buffer.asUint8List());
  }

  final dataSize = samples.lengthInBytes;
  word('RIFF');
  u32(36 + dataSize);
  word('WAVEfmt ');
  u32(16);
  u16(1);
  u16(_channels);
  u32(_sampleRate);
  u32(_sampleRate * _channels * 2);
  u16(_channels * 2);
  u16(16);
  word('data');
  u32(dataSize);
  bytes.add(samples.buffer.asUint8List());
  File(path).writeAsBytesSync(bytes.takeBytes());
}

double _pad(
  List<double> chord,
  double t,
  double stereoSide, {
  required bool battle,
}) {
  var value = 0.0;
  for (var tone = 0; tone < chord.length; tone++) {
    final frequency = chord[tone];
    final phase = stereoSide * (tone + 1) * 0.18;
    value += math.sin(2 * math.pi * frequency * t + phase) * 0.095;
    value +=
        math.sin(2 * math.pi * frequency * 2 * t - phase) *
        (battle ? 0.020 : 0.026);
    value += math.sin(2 * math.pi * frequency * 0.5 * t + phase * 0.5) * 0.032;
  }
  final breath =
      0.78 + math.sin(2 * math.pi * t / 8 + stereoSide * 0.35) * 0.22;
  return value * breath;
}

double _arpeggio(
  List<double> chord,
  double t,
  double stereoSide, {
  required bool battle,
}) {
  final stepDuration = battle ? 0.25 : 0.5;
  final step = (t / stepDuration).floor();
  final stepTime = t % stepDuration;
  final order = battle ? const [0, 2, 1, 2, 0, 1] : const [0, 1, 2, 1, 0, 2];
  final frequency = chord[order[step % order.length]] * (battle ? 4 : 2);
  final envelope = math.exp(-stepTime * (battle ? 10 : 6));
  final pan = 0.78 + stereoSide * (step.isEven ? 0.12 : -0.12);
  return math.sin(2 * math.pi * frequency * t + stereoSide * 0.1) *
      envelope *
      pan *
      (battle ? 0.052 : 0.038);
}

double _rhythm(double t, double stereoSide, {required bool battle}) {
  final beatDuration = battle ? 0.5 : 1.0;
  final beatTime = t % beatDuration;
  final kickFrequency = battle ? 48.0 : 36.0;
  final kick =
      math.exp(-beatTime * (battle ? 14 : 9)) *
      math.sin(2 * math.pi * kickFrequency * beatTime) *
      (battle ? 0.16 : 0.055);
  if (!battle) return kick;

  final subdivision = t % 0.25;
  final metallic =
      math.exp(-subdivision * 25) *
      math.sin(2 * math.pi * (680 + stereoSide * 36) * t) *
      0.026;
  return kick + metallic;
}

double _signalShimmer(double t, double stereoSide, {required bool battle}) {
  final cycle = battle ? 1.5 : 3.0;
  final phase = (t % cycle) / cycle;
  final gate = math.pow(math.sin(math.pi * phase), battle ? 10 : 7).toDouble();
  final frequency = (battle ? 329.63 : 261.63) + stereoSide * 2.4;
  return math.sin(2 * math.pi * frequency * t + stereoSide * 0.5) *
      gate *
      (battle ? 0.043 : 0.033);
}
