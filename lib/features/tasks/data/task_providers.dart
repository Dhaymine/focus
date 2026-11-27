import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/localization/current_l10n.dart';
import '../../../core/services/notification_service.dart';
import '../domain/task_filters.dart';
import 'task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(notificationServiceProvider),
    () => currentL10n(ref).taskReminderBody,
  );
});

final tasksProvider = StreamProvider<List<TaskRow>>(
    (ref) => ref.watch(taskRepositoryProvider).watchTasks());

final subtasksProvider = StreamProvider<List<SubtaskRow>>(
    (ref) => ref.watch(taskRepositoryProvider).watchSubtasks());

final categoriesProvider = StreamProvider<List<CategoryRow>>(
    (ref) => ref.watch(taskRepositoryProvider).watchCategories());

final completedTodayCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const <TaskRow>[];
  return countCompletedToday(tasks, DateTime.now());
});

final dueTodayCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const <TaskRow>[];
  return countDueToday(tasks, DateTime.now());
});
