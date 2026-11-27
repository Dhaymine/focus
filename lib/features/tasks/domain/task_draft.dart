class SubtaskDraft {
  SubtaskDraft({this.id, required this.title, this.done = false});

  final String? id;
  String title;
  bool done;
}

class TaskDraft {
  const TaskDraft({
    this.id,
    required this.title,
    this.description = '',
    this.priority = 1,
    this.categoryId,
    this.deadline,
    this.reminderAt,
    this.estimatedMinutes,
    this.subtasks = const [],
  });

  /// null = new task.
  final String? id;
  final String title;
  final String description;
  final int priority;
  final String? categoryId;
  final DateTime? deadline;
  final DateTime? reminderAt;
  final int? estimatedMinutes;
  final List<SubtaskDraft> subtasks;
}
