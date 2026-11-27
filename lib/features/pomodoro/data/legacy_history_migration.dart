import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../domain/segment_record.dart';
import 'history_repository.dart';

/// Moves the Phase 4 timer history (SharedPreferences) into the database.
/// Runs once; if it fails the old data is kept and it retries next launch.
Future<void> migrateLegacyHistory(
    SharedPreferences prefs, AppDatabase db) async {
  const flag = 'history_migrated_v1';
  if (prefs.getBool(flag) ?? false) return;

  final raw = prefs.getString('timer_history');
  if (raw != null) {
    try {
      final list = jsonDecode(raw) as List;
      final records = <SegmentRecord>[];
      for (final item in list) {
        final r = SegmentRecord.tryFromJson(item);
        if (r != null) records.add(r);
      }
      await HistoryRepository(db).addAll(records);
    } catch (_) {
      return;
    }
    await prefs.remove('timer_history');
  }
  await prefs.setBool(flag, true);
}
