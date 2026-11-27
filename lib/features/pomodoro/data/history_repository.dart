import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/segment_record.dart';
import '../domain/timer_plan.dart';

class HistoryRepository {
  HistoryRepository(this._db);

  final AppDatabase _db;

  /// Stores finished segments. Study time is also added to [taskId]'s total.
  Future<void> addAll(List<SegmentRecord> records, {String? taskId}) async {
    if (records.isEmpty) return;
    var studyMs = 0;
    await _db.transaction(() async {
      for (final r in records) {
        final isStudy = r.type == SegmentType.study;
        if (isStudy) studyMs += r.actualMs;
        await _db.into(_db.timerSessions).insert(
              TimerSessionsCompanion.insert(
                type: r.type.name,
                startMs: r.startMs,
                endMs: r.endMs,
                plannedMs: r.plannedMs,
                actualMs: r.actualMs,
                completed: r.completed,
                taskId: Value(isStudy ? taskId : null),
              ),
            );
      }
      final seconds = studyMs ~/ 1000;
      if (taskId != null && seconds > 0) {
        final row = await (_db.select(_db.tasks)
              ..where((t) => t.id.equals(taskId)))
            .getSingleOrNull();
        if (row != null) {
          await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId)))
              .write(TasksCompanion(
            actualSeconds: Value(row.actualSeconds + seconds),
            updatedAt: Value(DateTime.now()),
          ));
        }
      }
    });
  }

  /// Milliseconds studied today (completed and partial study segments).
  Stream<int> watchTodayStudyMs() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end =
        DateTime(now.year, now.month, now.day + 1).millisecondsSinceEpoch;
    final query = _db.select(_db.timerSessions)
      ..where((s) =>
          s.type.equals('study') &
          s.endMs.isBiggerOrEqualValue(start) &
          s.endMs.isSmallerThanValue(end));
    return query
        .watch()
        .map((rows) => rows.fold<int>(0, (sum, r) => sum + r.actualMs));
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>(
    (ref) => HistoryRepository(ref.watch(appDatabaseProvider)));

final todayStudyMsProvider = StreamProvider<int>(
    (ref) => ref.watch(historyRepositoryProvider).watchTodayStudyMs());
