import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_wav_audio.dart';

Uint8List wav({bool metadata = false, int format = 1, int dataSize = 4800}) {
  final prefix = metadata ? 56 : 44;
  final bytes = Uint8List(prefix + dataSize);
  final data = ByteData.sublistView(bytes);
  void tag(int at, String value) => bytes.setRange(at, at + 4, value.codeUnits);
  tag(0, 'RIFF');
  data.setUint32(4, bytes.length - 8, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, format, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 24000, Endian.little);
  data.setUint32(28, 48000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  if (metadata) {
    tag(36, 'JUNK');
    data.setUint32(40, 4, Endian.little);
  }
  tag(prefix - 8, 'data');
  data.setUint32(prefix - 4, dataSize, Endian.little);
  for (var i = prefix + dataSize ~/ 2; i + 1 < bytes.length; i += 2) {
    data.setInt16(i, 10000, Endian.little);
  }
  return bytes;
}

void main() {
  test('real silence and speech samples drive mouth, not a timer wave', () {
    final audio = LumoWavAudio.parse(wav());
    expect(audio.duration, const Duration(milliseconds: 100));
    expect(audio.mouthAt(Duration.zero), 0);
    expect(audio.mouthAt(const Duration(milliseconds: 50)), closeTo(1, .01));
    expect(audio.mouthAt(const Duration(milliseconds: 200)), 0);
  });
  test('valid RIFF metadata does not break duration or PCM parsing', () {
    expect(LumoWavAudio.parse(wav(metadata: true)).duration,
        const Duration(milliseconds: 100));
  });
  test('compressed and truncated bytes never become pretend PCM', () {
    expect(() => LumoWavAudio.parse(wav(format: 3)), throwsFormatException);
    expect(
        () => LumoWavAudio.parse(wav().sublist(0, 60)), throwsFormatException);
    expect(() => LumoWavAudio.parse(Uint8List(44)), throwsFormatException);
  });
}
