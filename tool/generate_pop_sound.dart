import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

Uint8List generateOrganicPopWav({
  required double baseFreq,
  required double formantFreq,
  required double durationSec,
  required double popPitchBend,
  required double clickIntensity,
}) {
  final sampleRate = 44100;
  final numSamples = (sampleRate * durationSec).toInt();
  final byteRate = sampleRate * 2;
  final dataSize = numSamples * 2;
  final chunkSize = 36 + dataSize;

  final buffer = ByteData(44 + dataSize);

  // RIFF header
  buffer.setUint8(0, 0x52); buffer.setUint8(1, 0x49); buffer.setUint8(2, 0x46); buffer.setUint8(3, 0x46);
  buffer.setUint32(4, chunkSize, Endian.little);
  buffer.setUint8(8, 0x57); buffer.setUint8(9, 0x41); buffer.setUint8(10, 0x56); buffer.setUint8(11, 0x45);

  // fmt subchunk
  buffer.setUint8(12, 0x66); buffer.setUint8(13, 0x6D); buffer.setUint8(14, 0x74); buffer.setUint8(15, 0x20);
  buffer.setUint32(16, 16, Endian.little);
  buffer.setUint16(20, 1, Endian.little);
  buffer.setUint16(22, 1, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, byteRate, Endian.little);
  buffer.setUint16(32, 2, Endian.little);
  buffer.setUint16(34, 16, Endian.little);

  // data subchunk
  buffer.setUint8(36, 0x64); buffer.setUint8(37, 0x61); buffer.setUint8(38, 0x74); buffer.setUint8(39, 0x61);
  buffer.setUint32(40, dataSize, Endian.little);

  double phase1 = 0.0;
  double phase2 = 0.0;
  final random = Random(42);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;

    // Organic cavity pop frequency sweep (exponential drop from initial pop to resonant cavity)
    final freqSweep = baseFreq * (1.0 + popPitchBend * exp(-t * 90.0));
    final f2Sweep = formantFreq * (1.0 + (popPitchBend * 0.5) * exp(-t * 120.0));

    phase1 += 2 * pi * freqSweep / sampleRate;
    phase2 += 2 * pi * f2Sweep / sampleRate;

    // Amplitude envelope: 1.5ms attack, fast organic body decay
    double env;
    if (t < 0.0015) {
      env = t / 0.0015;
    } else {
      env = exp(-(t - 0.0015) * 55.0);
    }

    // Initial suction release click / snap
    double click = 0.0;
    if (t < 0.004) {
      click = (random.nextDouble() * 2.0 - 1.0) * exp(-t * 1200.0) * clickIntensity;
    }

    // Body sound (fundamental + 2nd formant + 3rd subtle harmonic)
    final body = sin(phase1) * 0.7 + sin(phase2) * 0.35 + sin(phase1 * 3.0) * 0.08;

    final sample = (body * env + click).clamp(-1.0, 1.0);
    final pcm16 = (sample * 32000.0).toInt().clamp(-32768, 32767);

    buffer.setInt16(44 + (i * 2), pcm16, Endian.little);
  }

  return buffer.buffer.asUint8List();
}

void main() {
  final soundsDir = Directory('assets/sounds');
  if (!soundsDir.existsSync()) {
    soundsDir.createSync(recursive: true);
  }

  // 1. Cute Sweet Pop (Increment / Tap) - Very satisfying bubble/mouth pop
  final popWav = generateOrganicPopWav(
    baseFreq: 540.0,
    formantFreq: 1180.0,
    durationSec: 0.075,
    popPitchBend: 0.8,
    clickIntensity: 0.45,
  );
  File('assets/sounds/pop.wav').writeAsBytesSync(popWav);

  // 2. Cute Soft Pop (Decrement) - Slightly deeper, warm soft pop
  final popDownWav = generateOrganicPopWav(
    baseFreq: 420.0,
    formantFreq: 920.0,
    durationSec: 0.075,
    popPitchBend: 0.7,
    clickIntensity: 0.35,
  );
  File('assets/sounds/pop_down.wav').writeAsBytesSync(popDownWav);

  // 3. Cute Bell / Pop Combo (for Batch +5 / +10 / Full Day)
  final popSpecialWav = generateOrganicPopWav(
    baseFreq: 680.0,
    formantFreq: 1450.0,
    durationSec: 0.09,
    popPitchBend: 0.9,
    clickIntensity: 0.5,
  );
  File('assets/sounds/pop_special.wav').writeAsBytesSync(popSpecialWav);

  print('New organic cute pop sounds created successfully!');
}
