import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/notification_service.dart';
import '../domain/task_draft.dart';

const _uuid = Uuid();

class TaskRepository {
  TaskRepository(this._db, this._notifications, this._reminderBody);

  final AppDatabase _db;
  final NotificationService _notifications;
  final String Function() _reminderBody;

  // ------------------------------------------------------------------ reads

  Stream<List<TaskRow>> watchTasks() =>
      (_db.select(_db.tasks)..where((t) => t.deletedAt.isNull())).watch();

  Stream<List<SubtaskRow>> watchSubtasks() => _db.select(_db.subtasks).watch();

  Stream<List<CategoryRow>> watchCategories() => (_db.select(_db.categories)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.name)]))
      .watch();

  Future<TaskRow?> getTask(String id) =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<SubtaskRow>> getSubtasks(String taskId) =>
      (_db.select(_db.subtasks)
            ..where((s) => s.taskId.equals(taskId))
            ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
          .get();

  // ----------------------------------------------------------------- writes

  /// Creates or updates a task and replaces its subtasks. Returns the task id.
  Future<String> saveTask(TaskDraft d) async {
    final now = DateTime.now();
    final id = d.id ?? _uuid.v4();

    await _db.transaction(() async {
      if (d.id == null) {
        await _db.into(_db.tasks).insert(TasksCompanion.insert(
              id: id,
              title: d.title,
              createdAt: now,
              updatedAt: now,
              description: Value(d.description),
              priority: Value(d.priority),
              categoryId: Value(d.categoryId),
              deadline: Value(d.deadline),
              reminderAt: Value(d.reminderAt),
              estimatedMinutes: Value(d.estimatedMinutes),
            ));
      } else {
        await (_db.update(_db.tasks)..where((t) => t.id.equals(id)))
            .write(TasksCompanion(
          title: Value(d.title),
          description: Value(d.description),
          priority: Value(d.priority),
          categoryId: Value(d.categoryId),
          deadline: Value(d.deadline),
          reminderAt: Value(d.reminderAt),
          estimatedMinutes: Value(d.estimatedMinutes),
          updatedAt: Value(now),
        ));
      }

      await (_db.delete(_db.subtasks)..where((s) => s.taskId.equals(id))).go();
      var order = 0;
      for (final s in d.subtasks) {
        await _db.into(_db.subtasks).insert(SubtasksCompanion.insert(
              id: s.id ?? _uuid.v4(),
              taskId: id,
              title: s.title,
              updatedAt: now,
              isCompleted: Value(s.done),
              sortOrder: Value(order),
            ));
        order++;
      }
    });

    final row = await getTask(id);
    if (row != null) {
      await _syncReminder(row, askPermission: d.reminderAt != null);
    }
    return id;
  }

  Future<void> toggleComplete(String id, bool done) async {
    final now = DateTime.now();
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id)))
        .write(TasksCompanion(
      isCompleted: Value(done),
      completedAt: Value(done ? now : null),
      updatedAt: Value(now),
    ));
    final row = await getTask(id);
    if (row != null) await _syncReminder(row);
  }

  /// Soft delete (kept as a tombstone for future synchronization).
  Future<void> deleteTask(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id)))
        .write(TasksCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    await _notifications.cancelTaskReminder(id);
  }

  Future<String> addCategory(String name, int colorValue) async {
    final id = _uuid.v4();
    await _db.into(_db.categories).insert(CategoriesCompanion.insert(
          id: id,
          name: name,
          colorValue: colorValue,
          updatedAt: DateTime.now(),
        ));
    return id;
  }

  Future<void> deleteCategory(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.categories)..where((c) => c.id.equals(id)))
          .write(CategoriesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ));
      await (_db.update(_db.tasks)..where((t) => t.categoryId.equals(id)))
          .write(TasksCompanion(
        categoryId: const Value<String?>(null),
        updatedAt: Value(now),
      ));
    });
  }

  // -------------------------------------------------------------- reminders

  Future<void> _syncReminder(TaskRow row, {bool askPermission = false}) async {
    final at = row.reminderAt;
    if (row.deletedAt != null ||
        row.isCompleted ||
        at == null ||
        !at.isAfter(DateTime.now())) {
      await _notifications.cancelTaskReminder(row.id);
      return;
    }
    if (askPermission) {
      await _notifications.requestPermissions(askExact: false);
    }
    await _notifications.scheduleTaskReminder(
      taskId: row.id,
      title: row.title,
      body: _reminderBody(),
      at: at,
    );
  }
}
