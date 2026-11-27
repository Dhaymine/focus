import '../../../core/database/app_database.dart';

enum TaskView { today, week, all }

/// Pending: sorted by priority (high first), then deadline, then creation.
/// Completed: most recently completed first.
void sortTasks(List<TaskRow> list, {required bool completed}) {
  list.sort((a, b) {
    if (completed) {
      return (b.completedAt ?? b.updatedAt)
          .compareTo(a.completedAt ?? a.updatedAt);
    }
    final p = b.priority.compareTo(a.priority);
    if (p != 0) return p;
    final da = a.deadline;
    final dbl = b.deadline;
    if (da != null && dbl != null) {
      final c = da.compareTo(dbl);
      if (c != 0) return c;
    } else if (da != null) {
      return -1;
    } else if (dbl != null) {
      return 1;
    }
    return a.createdAt.compareTo(b.createdAt);
  });
}

List<TaskRow> filterTasks(
  List<TaskRow> tasks, {
  required TaskView view,
  required bool completed,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final weekEnd = DateTime(now.year, now.month, now.day + 7);
  final weekAgo = DateTime(now.year, now.month, now.day - 6);

  bool keep(TaskRow t) {
    if (t.isCompleted != completed) return false;
    switch (view) {
      case TaskView.all:
        return true;
      case TaskView.today:
        if (completed) {
          final c = t.completedAt;
          return c != null && !c.isBefore(today) && c.isBefore(tomorrow);
        }
        final d = t.deadline;
        return d != null && d.isBefore(tomorrow);
      case TaskView.week:
        if (completed) {
          final c = t.completedAt;
          return c != null && !c.isBefore(weekAgo);
        }
        final d = t.deadline;
        return d != null && d.isBefore(weekEnd);
    }
  }

  final out = tasks.where(keep).toList();
  sortTasks(out, completed: completed);
  return out;
}

int countCompletedToday(List<TaskRow> tasks, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  return tasks.where((t) {
    final c = t.completedAt;
    return t.isCompleted &&
        c != null &&
        !c.isBefore(today) &&
        c.isBefore(tomorrow);
  }).length;
}

/// Pending tasks due today or overdue.
int countDueToday(List<TaskRow> tasks, DateTime now) {
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  return tasks.where((t) {
    final d = t.deadline;
    return !t.isCompleted && d != null && d.isBefore(tomorrow);
  }).length;
}
