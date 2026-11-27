import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/database/app_database.dart';
import 'package:focus/features/tasks/domain/task_filters.dart';

TaskRow _task(
  String id, {
  DateTime? deadline,
  bool done = false,
  DateTime? completedAt,
  int priority = 1,
}) {
  return TaskRow(
    id: id,
    title: id,
    description: '',
    priority: priority,
    categoryId: null,
    deadline: deadline,
    reminderAt: null,
    estimatedMinutes: null,
    actualSeconds: 0,
    isCompleted: done,
    completedAt: completedAt,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    deletedAt: null,
  );
}

List<String> _ids(List<TaskRow> l) => l.map((t) => t.id).toList();

void main() {
  final now = DateTime(2026, 11, 27, 12);

  final overdue = _task('overdue', deadline: DateTime(2026, 11, 20));
  final today = _task('today', deadline: DateTime(2026, 11, 27, 18));
  final tomorrow = _task('tomorrow', deadline: DateTime(2026, 11, 28, 9));
  final day6 = _task('day6', deadline: DateTime(2026, 12, 3, 23));
  final day7 = _task('day7', deadline: DateTime(2026, 12, 4, 9));
  final none = _task('none');
  final all = [overdue, today, tomorrow, day6, day7, none];

  test('today view keeps overdue and due today only', () {
    final r = filterTasks(all, view: TaskView.today, completed: false, now: now);
    expect(_ids(r), ['overdue', 'today']);
  });

  test('week view covers the next 7 days and overdue', () {
    final r = filterTasks(all, view: TaskView.week, completed: false, now: now);
    expect(_ids(r), ['overdue', 'today', 'tomorrow', 'day6']);
  });

  test('all view includes tasks without a deadline', () {
    final r = filterTasks(all, view: TaskView.all, completed: false, now: now);
    expect(r.length, 6);
    expect(r.last.id, 'none');
  });

  test('higher priority comes first', () {
    final high = _task('high', priority: 2, deadline: DateTime(2026, 12, 1));
    final low = _task('low', priority: 0, deadline: DateTime(2026, 11, 21));
    final r = filterTasks([low, high],
        view: TaskView.all, completed: false, now: now);
    expect(_ids(r), ['high', 'low']);
  });

  test('completed view and counters use completion time', () {
    final doneToday = _task('d1',
        done: true, completedAt: DateTime(2026, 11, 27, 9));
    final doneOld = _task('d2',
        done: true, completedAt: DateTime(2026, 11, 10, 9));
    final list = [doneToday, doneOld, today];

    final todayDone =
        filterTasks(list, view: TaskView.today, completed: true, now: now);
    expect(_ids(todayDone), ['d1']);

    final allDone =
        filterTasks(list, view: TaskView.all, completed: true, now: now);
    expect(_ids(allDone), ['d1', 'd2']);

    expect(countCompletedToday(list, now), 1);
    expect(countDueToday(list, now), 1);
  });
}
