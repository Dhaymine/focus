import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/widgets/app_card.dart';
import '../../pomodoro/data/timer_controller.dart';
import '../../pomodoro/domain/timer_snapshot.dart';
import '../data/task_providers.dart';
import 'task_style.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.subtasks,
    required this.category,
  });

  final TaskRow task;
  final List<SubtaskRow> subtasks;
  final CategoryRow? category;

  Future<void> _start(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final snap = ref.read(timerControllerProvider);
    if (snap.status != TimerStatus.idle) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(l10n.replaceTimerQ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionReplace),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (!context.mounted) return;
    ref.read(timerControllerProvider.notifier).start(taskId: task.id);
    context.go('/focus');
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.deleteTaskQ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(taskRepositoryProvider).deleteTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    const red = Color(0xFFEF4444);

    final done = task.isCompleted;
    final deadline = task.deadline;
    final overdue = !done && deadline != null && deadline.isBefore(DateTime.now());
    final doneSubs = subtasks.where((s) => s.isCompleted).length;

    String? timeLabel;
    final actualMin = (task.actualSeconds / 60).round();
    final est = task.estimatedMinutes;
    if (est != null) {
      timeLabel =
          '${formatMinutes(l10n, actualMin)} / ${formatMinutes(l10n, est)}';
    } else if (task.actualSeconds >= 30) {
      timeLabel = formatMinutes(l10n, actualMin);
    }

    final pills = <Widget>[
      _Pill(
        label: priorityText(l10n, task.priority),
        color: priorityColor(task.priority),
        icon: Icons.flag_rounded,
      ),
      if (category != null)
        _Pill(
          label: category!.name,
          color: Color(category!.colorValue),
          icon: Icons.label_rounded,
        ),
      if (deadline != null)
        _Pill(
          label: overdue
              ? '${l10n.overdue} · ${formatDateTime(context, deadline)}'
              : formatDateTime(context, deadline),
          color: overdue ? red : muted,
          icon: Icons.event_rounded,
        ),
      if (timeLabel != null)
        _Pill(label: timeLabel, color: muted, icon: Icons.timer_outlined),
      if (subtasks.isNotEmpty)
        _Pill(
          label: l10n.subtasksProgress(doneSubs, subtasks.length),
          color: muted,
          icon: Icons.checklist_rounded,
        ),
    ];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(8, 12, 4, 12),
      onTap: () => context.push('/task-editor', extra: task.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: done,
            shape: const CircleBorder(),
            onChanged: (v) => ref
                .read(taskRepositoryProvider)
                .toggleComplete(task.id, v ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? muted : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: pills),
                ],
              ),
            ),
          ),
          if (!done)
            IconButton(
              tooltip: l10n.startTaskFocus,
              icon: const Icon(Icons.play_circle_fill_rounded),
              color: theme.colorScheme.primary,
              onPressed: () => _start(context, ref, l10n),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') {
                context.push('/task-editor', extra: task.id);
              } else {
                _confirmDelete(context, ref, l10n);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.editTask)),
              PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
