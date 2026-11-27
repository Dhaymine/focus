import 'package:drift/drift.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();

  /// 0 = low, 1 = medium, 2 = high
  IntColumn get priority => integer().withDefault(const Constant(1))();
  TextColumn get categoryId => text().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  IntColumn get estimatedMinutes => integer().nullable()();
  IntColumn get actualSeconds => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SubtaskRow')
class Subtasks extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Finished or partial timer segments. Also serves as the task time log.
@DataClassName('SessionRow')
class TimerSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// study, shortBreak, longBreak
  TextColumn get type => text()();
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();
  IntColumn get plannedMs => integer()();
  IntColumn get actualMs => integer()();
  BoolColumn get completed => boolean()();
  TextColumn get taskId => text().nullable()();
}
