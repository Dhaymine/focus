import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/preferences_provider.dart';
import '../domain/segment_record.dart';
import '../domain/timer_plan.dart';

const _key = 'timer_history';
const _maxRecords = 1000;

/// Timer history stored in SharedPreferences for now.
/// It moves to the Drift database in a later phase.
class HistoryController extends Notifier<List<SegmentRecord>> {
  @override
  List<SegmentRecord> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list)
          if (SegmentRecord.tryFromJson(item) != null)
            SegmentRecord.tryFromJson(item)!,
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> addAll(List<SegmentRecord> records) async {
    if (records.isEmpty) return;
    var next = [...state, ...records];
    if (next.length > _maxRecords) {
      next = next.sublist(next.length - _maxRecords);
    }
    state = next;
    await ref.read(sharedPreferencesProvider).setString(
          _key,
          jsonEncode(next.map((r) => r.toJson()).toList()),
        );
  }

  Future<void> clear() async {
    state = const [];
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final historyProvider =
    NotifierProvider<HistoryController, List<SegmentRecord>>(
        HistoryController.new);

/// Milliseconds studied today (completed and partial study segments).
final todayStudyMsProvider = Provider<int>((ref) {
  final records = ref.watch(historyProvider);
  final now = DateTime.now();
  var total = 0;
  for (final r in records) {
    if (r.type != SegmentType.study) continue;
    final d = DateTime.fromMillisecondsSinceEpoch(r.endMs);
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      total += r.actualMs;
    }
  }
  return total;
});
