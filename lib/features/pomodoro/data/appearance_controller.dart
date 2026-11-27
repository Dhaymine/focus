import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/preferences_provider.dart';
import '../domain/timer_appearance.dart';

const _key = 'timer_appearance';

class AppearanceController extends Notifier<TimerAppearance> {
  @override
  TimerAppearance build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const TimerAppearance();
    try {
      return TimerAppearance.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TimerAppearance();
    }
  }

  Future<void> update(TimerAppearance a) async {
    state = a;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(a.toJson()));
  }

  /// Returns null if cancelled, true on success, false on failure.
  Future<bool?> pickPhoto() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (res == null || res.files.isEmpty) return null;
      final source = res.files.first.path;
      if (source == null) return false;

      final dir = await getApplicationSupportDirectory();
      final target = Directory(p.join(dir.path, 'backgrounds'));
      await target.create(recursive: true);
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final dest = p.join(target.path, '$id${p.extension(source)}');
      await File(source).copy(dest);

      final old = state.photoPath;
      if (old != null) {
        try {
          await File(old).delete();
        } catch (_) {
          // Old file already gone.
        }
      }
      await update(state.copyWith(
        photoPath: dest,
        background: TimerBackground.photo,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final appearanceProvider =
    NotifierProvider<AppearanceController, TimerAppearance>(
        AppearanceController.new);
