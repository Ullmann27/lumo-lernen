import 'dart:math' as math;
import 'dart:typed_data';

/// Validated PCM speech and a mouth envelope derived from real samples.
/// RIFF chunks may include metadata; no fixed 44-byte-header assumption.
class LumoWavAudio {
  LumoWavAudio._(this.duration, this.envelope, this.framesPerSecond);

  final Duration duration;
  final List<double> envelope;
  final int framesPerSecond;

  static LumoWavAudio parse(Uint8List bytes, {int framesPerSecond = 20}) {
    if (bytes.length < 44 ||
        bytes.length > 8000000 ||
        _tag(bytes, 0) != 'RIFF' ||
        _tag(bytes, 8) != 'WAVE') {
      throw const FormatException('Ungültiges Lumo-WAV.');
    }
    final data = ByteData.sublistView(bytes);
    final declaredEnd = data.getUint32(4, Endian.little) + 8;
    if (declaredEnd > bytes.length || declaredEnd < 44) {
      throw const FormatException('Abgeschnittenes Lumo-WAV.');
    }
    int? sampleRate, channels, blockAlign, audioStart, audioSize;
    for (var offset = 12; offset + 8 <= declaredEnd;) {
      final tag = _tag(bytes, offset);
      final size = data.getUint32(offset + 4, Endian.little);
      final start = offset + 8;
      if (start + size > declaredEnd) {
        throw const FormatException('Ungültiger WAV-Abschnitt.');
      }
      if (tag == 'fmt ') {
        if (size < 16 ||
            data.getUint16(start, Endian.little) != 1 ||
            data.getUint16(start + 14, Endian.little) != 16) {
          throw const FormatException('Lumo benötigt 16-Bit-PCM.');
        }
        channels = data.getUint16(start + 2, Endian.little);
        sampleRate = data.getUint32(start + 4, Endian.little);
        blockAlign = data.getUint16(start + 12, Endian.little);
        if (channels < 1 ||
            channels > 2 ||
            sampleRate < 8000 ||
            sampleRate > 48000 ||
            blockAlign != channels * 2 ||
            data.getUint32(start + 8, Endian.little) !=
                sampleRate * blockAlign) {
          throw const FormatException('Ungültiges PCM-Format.');
        }
      } else if (tag == 'data') {
        audioStart = start;
        audioSize = size;
      }
      offset = start + size + (size.isOdd ? 1 : 0);
    }
    if (audioStart == null ||
        audioSize == null ||
        audioSize < 2 ||
        sampleRate == null ||
        channels == null ||
        blockAlign == null ||
        audioSize % blockAlign != 0 ||
        framesPerSecond < 1 ||
        framesPerSecond > 60) {
      throw const FormatException('PCM-Sprachdaten fehlen.');
    }
    final samplesPerWindow = math.max(1, sampleRate ~/ framesPerSecond);
    final step = samplesPerWindow * blockAlign;
    final rms = <double>[];
    for (var start = audioStart;
        start < audioStart + audioSize;
        start += step) {
      final end = math.min(start + step, audioStart + audioSize);
      var power = 0.0;
      var count = 0;
      for (var i = start; i + 1 < end; i += 2) {
        final value = data.getInt16(i, Endian.little) / 32768.0;
        power += value * value;
        count++;
      }
      rms.add(math.sqrt(power / math.max(count, 1)));
    }
    final peak = rms.fold<double>(0.01, math.max);
    return LumoWavAudio._(
      Duration(
          microseconds:
              (audioSize * 1000000 / (sampleRate * blockAlign)).round()),
      List<double>.unmodifiable(
        rms.map(
            (value) => value < 0.003 ? 0.0 : (value / peak).clamp(0.0, 1.0)),
      ),
      framesPerSecond,
    );
  }

  static String _tag(Uint8List data, int start) =>
      String.fromCharCodes(data.sublist(start, start + 4));

  double mouthAt(Duration mediaPosition) {
    final index = mediaPosition.inMicroseconds * framesPerSecond ~/ 1000000;
    return index >= 0 && index < envelope.length ? envelope[index] : 0;
  }
}
