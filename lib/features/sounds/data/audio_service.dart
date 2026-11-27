import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sound_settings.dart';
import 'builtin_sounds.dart';

class AlarmActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    if (state != value) state = value;
  }
}

final alarmActiveProvider =
    NotifierProvider<AlarmActiveNotifier, bool>(AlarmActiveNotifier.new);

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(
    onAlarmChanged: (v) => ref.read(alarmActiveProvider.notifier).set(v),
  );
  ref.onDispose(service.dispose);
  return service;
});

class AudioService {
  AudioService({required this.onAlarmChanged});

  final void Function(bool active) onAlarmChanged;
  late final AudioPlayer _player = AudioPlayer();
  int _run = 0;
  bool _configured = false;

  Future<String?> _resolve(String soundId, SoundSettings s) async {
    if (soundId == SoundIds.none) return null;
    if (soundId.startsWith(SoundIds.customPrefix)) {
      final id = soundId.substring(SoundIds.customPrefix.length);
      for (final c in s.customSounds) {
        if (c.id == id) {
          return await File(c.path).exists() ? c.path : null;
        }
      }
      return null;
    }
    return BuiltInSounds.ensureFile(soundId);
  }

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    if (Platform.isIOS) {
      try {
        await _player.setAudioContext(AudioContext(
          iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
        ));
      } catch (_) {
        // Ignore: default audio context is used.
      }
    }
  }

  /// Plays an alert using the repeat/loop settings.
  Future<void> playAlarm(String soundId, SoundSettings s) =>
      _play(soundId, s, once: false);

  /// Plays a sound exactly once (start sounds and previews).
  Future<void> playOnce(String soundId, SoundSettings s) =>
      _play(soundId, s, once: true);

  Future<void> _play(String soundId, SoundSettings s,
      {required bool once}) async {
    final run = ++_run;
    try {
      await _player.stop();
      final path = await _resolve(soundId, s);
      if (path == null || run != _run) {
        if (run == _run) onAlarmChanged(false);
        return;
      }
      await _configure();
      await _player.setVolume(s.volume);

      if (!once && s.loop) {
        await _player.setReleaseMode(ReleaseMode.loop);
        onAlarmChanged(true);
        await _player.play(DeviceFileSource(path));
        return;
      }

      await _player.setReleaseMode(ReleaseMode.stop);
      final times = once ? 1 : s.repeatCount;
      if (!once) onAlarmChanged(true);
      for (var i = 0; i < times; i++) {
        if (run != _run) return;
        final done = _player.onPlayerComplete.first;
        await _player.play(DeviceFileSource(path));
        try {
          await done.timeout(const Duration(seconds: 120));
        } catch (_) {
          break;
        }
      }
      if (run == _run) onAlarmChanged(false);
    } catch (_) {
      if (run == _run) onAlarmChanged(false);
    }
  }

  Future<void> stopAlarm() async {
    _run++;
    try {
      await _player.stop();
    } catch (_) {
      // Nothing to stop.
    }
    onAlarmChanged(false);
  }

  void dispose() {
    _player.dispose();
  }
}
