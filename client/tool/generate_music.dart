import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  Directory('assets/sounds').createSync(recursive: true);
  _writeLoop('assets/sounds/menu_ambient.wav', battle: false);
  _writeLoop('assets/sounds/battle_ambient.wav', battle: true);
}

void _writeLoop(String path, {required bool battle}) {
  const sampleRate = 22050;
  const seconds = 16;
  final samples = Int16List(sampleRate * seconds);
  final chords = battle
      ? const <List<double>>[
          [55.0, 82.41, 110.0],
          [61.74, 92.50, 123.47],
          [65.41, 98.0, 130.81],
          [49.0, 73.42, 98.0],
        ]
      : const <List<double>>[
          [65.41, 98.0, 130.81],
          [73.42, 110.0, 146.83],
          [82.41, 123.47, 164.81],
          [61.74, 92.50, 123.47],
        ];
  for (var i = 0; i < samples.length; i++) {
    final t = i / sampleRate;
    final chord = chords[(t ~/ 4) % chords.length];
    final edgeFade = math.min(1.0, math.min(t / 0.15, (seconds - t) / 0.15));
    var value = 0.0;
    for (var tone = 0; tone < chord.length; tone++) {
      final frequency = chord[tone];
      value += math.sin(2 * math.pi * frequency * t + tone * 0.7) * 0.14;
      value += math.sin(2 * math.pi * frequency * 2 * t) * 0.025;
    }
    final beat = t % (battle ? 0.5 : 1.0);
    final pulse =
        math.exp(-beat * (battle ? 13 : 8)) *
        math.sin(2 * math.pi * (battle ? 48 : 38) * t) *
        (battle ? 0.20 : 0.07);
    final shimmerFrequency = battle ? 329.63 : 261.63;
    final shimmerGate = math.pow(math.sin(math.pi * (t % 2) / 2), 8).toDouble();
    value +=
        pulse +
        math.sin(2 * math.pi * shimmerFrequency * t) *
            shimmerGate *
            (battle ? 0.045 : 0.035);
    samples[i] = (value * edgeFade * 24500).clamp(-32767, 32767).round();
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
  u16(1);
  u32(sampleRate);
  u32(sampleRate * 2);
  u16(2);
  u16(16);
  word('data');
  u32(dataSize);
  bytes.add(samples.buffer.asUint8List());
  File(path).writeAsBytesSync(bytes.takeBytes());
}
