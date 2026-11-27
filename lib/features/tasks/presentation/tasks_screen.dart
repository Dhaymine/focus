import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../data/task_providers.dart';
import '../domain/task_filters.dart';
import 'task_card.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskView _view = TaskView.all;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final tasks = ref.watch(tasksProvider).valueOrNull ?? const <TaskRow>[];
    final subs = ref.watch(subtasksProvider).valueOrNull ?? const <SubtaskRow>[];
    final cats =
        ref.watch(categoriesProvider).valueOrNull ?? const <CategoryRow>[];

    final subsByTask = <String, List<SubtaskRow>>{};
    for (final s in subs) {
      subsByTask.putIfAbsent(s.taskId, () => []).add(s);
    }
    final catById = {for (final c in cats) c.id: c};
    final visible = filterTasks(
      tasks,
      view: _view,
      completed: _completed,
      now: DateTime.now(),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/task-editor'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addTask),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              SegmentedButton<TaskView>(
                segments: [
                  ButtonSegment(
                      value: TaskView.today, label: Text(l10n.viewToday)),
                  ButtonSegment(
                      value: TaskView.week, label: Text(l10n.viewWeek)),
                  ButtonSegment(value: TaskView.all, label: Text(l10n.viewAll)),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                      value: false, label: Text(l10n.filterPending)),
                  ButtonSegment(
                      value: true, label: Text(l10n.filterCompleted)),
                ],
                selected: {_completed},
                onSelectionChanged: (s) =>
                    setState(() => _completed = s.first),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(Icons.task_alt_rounded, size: 48, color: muted),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noTasks,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.noTasksHint,
                        textAlign: TextAlign.center,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              for (final t in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskCard(
                    key: ValueKey(t.id),
                    task: t,
                    subtasks: subsByTask[t.id] ?? const <SubtaskRow>[],
                    category: catById[t.categoryId],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
