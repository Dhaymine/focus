import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class _Note {
  const _Note(this.freq, this.ms, {this.decay = 0});

  /// 0 means silence.
  final double freq;
  final int ms;

  /// Exponential decay rate. 0 = flat.
  final double decay;
}

/// Built-in alert sounds are synthesized into WAV files on first use,
/// so the app needs no bundled audio assets.
class BuiltInSounds {
  BuiltInSounds._();

  static const ids = ['bell', 'chime', 'beep', 'soft', 'digital'];

  static final Map<String, List<_Note>> _defs = {
    'bell': [const _Note(880, 1400, decay: 3.5)],
    'chime': [
      const _Note(659.25, 400, decay: 5),
      const _Note(783.99, 400, decay: 5),
      const _Note(987.77, 900, decay: 4),
    ],
    'beep': [
      const _Note(1000, 180),
      const _Note(0, 100),
      const _Note(1000, 180),
    ],
    'soft': [
      const _Note(523.25, 700, decay: 4),
      const _Note(659.25, 1000, decay: 3.5),
    ],
    'digital': [
      const _Note(1318.5, 90),
      const _Note(0, 60),
      const _Note(1318.5, 90),
      const _Note(0, 60),
      const _Note(1318.5, 220),
    ],
  };

  static Future<String?> ensureFile(String id) async {
    final notes = _defs[id];
    if (notes == null) return null;
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'builtin_v1_$id.wav'));
    if (!await file.exists()) {
      await file.writeAsBytes(_render(notes), flush: true);
    }
    return file.path;
  }

  static Uint8List _render(List<_Note> notes) {
    const rate = 22050;
    final pcm = <int>[];
    for (final n in notes) {
      final count = (rate * n.ms / 1000).round();
      final edge = rate * 0.005;
      for (var i = 0; i < count; i++) {
        if (n.freq <= 0) {
          pcm.add(0);
          continue;
        }
        final t = i / rate;
        var env = n.decay > 0 ? math.exp(-n.decay * t) : 1.0;
        if (i < edge) env *= i / edge;
        if (i > count - edge) env *= (count - i) / edge;
        final v = math.sin(2 * math.pi * n.freq * t) +
            0.35 * math.sin(2 * math.pi * 2 * n.freq * t) +
            0.15 * math.sin(2 * math.pi * 3 * n.freq * t);
        final sample = (v / 1.5 * env * 0.7 * 32767).round();
        pcm.add(math.max(-32768, math.min(32767, sample)));
      }
    }

    final dataLen = pcm.length * 2;
    final bytes = ByteData(44 + dataLen);
    void writeStr(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        bytes.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLen, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, rate, Endian.little);
    bytes.setUint32(28, rate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    bytes.setUint32(40, dataLen, Endian.little);
    for (var i = 0; i < pcm.length; i++) {
      bytes.setInt16(44 + i * 2, pcm[i], Endian.little);
    }
    return bytes.buffer.asUint8List();
  }
}
