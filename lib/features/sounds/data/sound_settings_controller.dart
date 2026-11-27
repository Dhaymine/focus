import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/preferences_provider.dart';
import '../domain/sound_settings.dart';

const _key = 'sound_settings';

class SoundSettingsController extends Notifier<SoundSettings> {
  @override
  SoundSettings build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return SoundSettings.defaults;
    try {
      return SoundSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return SoundSettings.defaults;
    }
  }

  Future<void> _save(SoundSettings s) async {
    state = s;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(s.toJson()));
  }

  Future<void> setEvent(SoundEvent e, String id) =>
      _save(state.withEvent(e, id));
  Future<void> setVolume(double v) => _save(state.copyWith(volume: v));
  Future<void> setVibrate(bool v) => _save(state.copyWith(vibrate: v));
  Future<void> setRepeatCount(int v) =>
      _save(state.copyWith(repeatCount: v.clamp(1, 10)));
  Future<void> setLoop(bool v) => _save(state.copyWith(loop: v));

  /// Returns null if cancelled, true on success, false on failure.
  Future<bool?> importSound() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
      );
      if (res == null || res.files.isEmpty) return null;
      final picked = res.files.first;
      final source = picked.path;
      if (source == null) return false;

      final dir = await getApplicationSupportDirectory();
      final target = Directory(p.join(dir.path, 'custom_sounds'));
      await target.create(recursive: true);
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final dest = p.join(target.path, '$id${p.extension(source)}');
      await File(source).copy(dest);

      final sound = CustomSound(
        id: id,
        name: p.basenameWithoutExtension(picked.name),
        path: dest,
      );
      await _save(state.copyWith(customSounds: [...state.customSounds, sound]));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> removeCustom(String id) async {
    final ref0 = '${SoundIds.customPrefix}$id';
    CustomSound? found;
    for (final c in state.customSounds) {
      if (c.id == id) found = c;
    }
    if (found != null) {
      try {
        await File(found.path).delete();
      } catch (_) {
        // File already gone.
      }
    }
    const d = SoundSettings.defaults;
    var s = state.copyWith(
      customSounds: state.customSounds.where((c) => c.id != id).toList(),
    );
    for (final e in SoundEvent.values) {
      if (s.idFor(e) == ref0) s = s.withEvent(e, d.idFor(e));
    }
    await _save(s);
  }
}

final soundSettingsProvider =
    NotifierProvider<SoundSettingsController, SoundSettings>(
        SoundSettingsController.new);
