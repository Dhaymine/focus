import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/number_stepper.dart';
import '../../../shared/widgets/page_body.dart';
import '../data/task_providers.dart';
import '../domain/task_draft.dart';
import 'task_style.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen({super.key, this.taskId});

  /// null = create a new task.
  final String? taskId;

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _subtaskInput = TextEditingController();
  final List<SubtaskDraft> _subtasks = [];

  int _priority = 1;
  String? _categoryId;
  DateTime? _deadline;
  DateTime? _reminder;
  int _estimate = 0;
  int _actualSeconds = 0;
  bool _loading = false;

  bool get _editing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) {
      _loading = true;
      _load();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _subtaskInput.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(taskRepositoryProvider);
    final row = await repo.getTask(widget.taskId!);
    final subs = await repo.getSubtasks(widget.taskId!);
    if (!mounted) return;
    setState(() {
      if (row != null) {
        _title.text = row.title;
        _description.text = row.description;
        _priority = row.priority;
        _categoryId = row.categoryId;
        _deadline = row.deadline;
        _reminder = row.reminderAt;
        _estimate = row.estimatedMinutes ?? 0;
        _actualSeconds = row.actualSeconds;
      }
      _subtasks.addAll(subs.map(
        (s) => SubtaskDraft(id: s.id, title: s.title, done: s.isCompleted),
      ));
      _loading = false;
    });
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        initial ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _addSubtask() {
    final text = _subtaskInput.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(SubtaskDraft(title: text));
      _subtaskInput.clear();
    });
  }

  Future<void> _newCategory() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    var color = categoryColors.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.newCategory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.categoryName),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in categoryColors)
                    GestureDetector(
                      onTap: () => setLocal(() => color = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color == c
                                ? Theme.of(ctx).colorScheme.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
    final name = controller.text.trim();
    if (ok == true && name.isNotEmpty) {
      final id = await ref
          .read(taskRepositoryProvider)
          .addCategory(name, color.toARGB32());
      if (mounted) setState(() => _categoryId = id);
    }
  }

  Future<void> _deleteCategory(CategoryRow c) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c.name),
        content: Text(l10n.deleteCategoryQ),
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
      await ref.read(taskRepositoryProvider).deleteCategory(c.id);
      if (mounted && _categoryId == c.id) setState(() => _categoryId = null);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.titleRequired)));
      return;
    }
    final pending = _subtaskInput.text.trim();
    if (pending.isNotEmpty) _subtasks.add(SubtaskDraft(title: pending));

    final cats = ref.read(categoriesProvider).valueOrNull ?? const <CategoryRow>[];
    final category = cats.any((c) => c.id == _categoryId) ? _categoryId : null;

    final draft = TaskDraft(
      id: widget.taskId,
      title: title,
      description: _description.text.trim(),
      priority: _priority,
      categoryId: category,
      deadline: _deadline,
      reminderAt: _reminder,
      estimatedMinutes: _estimate > 0 ? _estimate : null,
      subtasks: List.of(_subtasks),
    );
    await ref.read(taskRepositoryProvider).saveTask(draft);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
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
      await ref.read(taskRepositoryProvider).deleteTask(widget.taskId!);
      if (mounted) context.pop();
    }
  }

  Widget _dateRow({
    required String label,
    required DateTime? value,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value == null ? l10n.notSet : formatDateTime(context, value)),
      onTap: onPick,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            IconButton(
              tooltip: l10n.clearLabel,
              icon: const Icon(Icons.close_rounded),
              onPressed: onClear,
            ),
          IconButton(
            icon: const Icon(Icons.edit_calendar_rounded),
            onPressed: onPick,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <CategoryRow>[];

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editTask)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            text,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? l10n.editTask : l10n.newTask),
        actions: [
          if (_editing)
            IconButton(
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
          IconButton(
            tooltip: l10n.actionSave,
            icon: const Icon(Icons.check_rounded),
            onPressed: _save,
          ),
        ],
      ),
      body: PageBody(
        children: [
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.taskTitleLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 5,
                  decoration:
                      InputDecoration(labelText: l10n.taskDescriptionLabel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading(l10n.priorityLabel),
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 0, label: Text(l10n.priorityLow)),
                    ButtonSegment(value: 1, label: Text(l10n.priorityMedium)),
                    ButtonSegment(value: 2, label: Text(l10n.priorityHigh)),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (s) =>
                      setState(() => _priority = s.first),
                ),
                const SizedBox(height: 20),
                heading(l10n.categoryLabel),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.categoryNone),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                    for (final c in cats)
                      GestureDetector(
                        onLongPress: () => _deleteCategory(c),
                        child: ChoiceChip(
                          avatar: CircleAvatar(
                            backgroundColor: Color(c.colorValue),
                            radius: 7,
                          ),
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          onSelected: (_) =>
                              setState(() => _categoryId = c.id),
                        ),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.newCategory),
                      onPressed: _newCategory,
                    ),
                  ],
                ),
                if (cats.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.deleteCategoryHint,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                _dateRow(
                  label: l10n.deadlineLabel,
                  value: _deadline,
                  onPick: () async {
                    final v = await _pickDateTime(_deadline);
                    if (v != null) setState(() => _deadline = v);
                  },
                  onClear: () => setState(() => _deadline = null),
                ),
                _dateRow(
                  label: l10n.reminderLabel,
                  value: _reminder,
                  onPick: () async {
                    final v = await _pickDateTime(_reminder);
                    if (v != null) setState(() => _reminder = v);
                  },
                  onClear: () => setState(() => _reminder = null),
                ),
                NumberStepper(
                  label: l10n.estimatedTime,
                  value: _estimate,
                  min: 0,
                  max: 600,
                  step: 5,
                  valueText:
                      _estimate == 0 ? l10n.notSet : l10n.minutesShort(_estimate),
                  onChanged: (v) => setState(() => _estimate = v),
                ),
                if (_editing && _actualSeconds >= 30)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.timeSpent(formatMinutes(
                            l10n, (_actualSeconds / 60).round())),
                        style:
                            theme.textTheme.bodyMedium?.copyWith(color: muted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading(l10n.subtasksLabel),
                for (var i = 0; i < _subtasks.length; i++)
                  Row(
                    children: [
                      Checkbox(
                        value: _subtasks[i].done,
                        onChanged: (v) =>
                            setState(() => _subtasks[i].done = v ?? false),
                      ),
                      Expanded(
                        child: Text(
                          _subtasks[i].title,
                          style: TextStyle(
                            decoration: _subtasks[i].done
                                ? TextDecoration.lineThrough
                                : null,
                            color: _subtasks[i].done ? muted : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () =>
                            setState(() => _subtasks.removeAt(i)),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskInput,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addSubtask(),
                        decoration: InputDecoration(
                          hintText: l10n.addSubtask,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.addSubtask,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: _addSubtask,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
