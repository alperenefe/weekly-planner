import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Tasks extends Table {
  @override
  String get tableName => 'tasks';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text()();

  IntColumn get durationMinutes => integer().named('duration_minutes').nullable()();

  IntColumn get startMinutes => integer().named('start_minutes').nullable()();

  IntColumn get reminderEnabled =>
      integer().named('reminder_enabled').withDefault(const Constant(0))();

  IntColumn get reminderMinutes =>
      integer().named('reminder_minutes').nullable()();

  TextColumn get notes => text().nullable()();

  TextColumn get status => text().withDefault(const Constant('planned'))();

  TextColumn get weekStart => text().named('week_start')();

  TextColumn get plannedDate => text().named('planned_date').nullable()();

  TextColumn get originalPlannedDate => text().named('original_planned_date').nullable()();

  IntColumn get movedCount => integer().named('moved_count').withDefault(const Constant(0))();

  IntColumn get recurrenceTemplateId =>
      integer().named('recurrence_template_id').nullable()();

  IntColumn get accentColor => integer().named('accent_color').nullable()();

  TextColumn get createdAt => text().named('created_at')();

  TextColumn get updatedAt => text().named('updated_at')();

  TextColumn get completedAt => text().named('completed_at').nullable()();
}

class TaskHistories extends Table {
  @override
  String get tableName => 'task_history';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get taskId => integer().named('task_id')();

  TextColumn get eventType => text().named('event_type')();

  TextColumn get fromDate => text().named('from_date').nullable()();

  TextColumn get toDate => text().named('to_date').nullable()();

  TextColumn get timestamp => text().named('timestamp')();

  TextColumn get note => text().nullable()();
}

class WeekMetas extends Table {
  @override
  String get tableName => 'week_meta';

  TextColumn get weekStart => text().named('week_start')();

  IntColumn get copyFromPreviousApplied =>
      integer().named('copy_from_previous_applied').withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {weekStart};
}

class RecurringTemplates extends Table {
  @override
  String get tableName => 'recurring_templates';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text()();

  IntColumn get durationMinutes => integer().named('duration_minutes').nullable()();

  TextColumn get notes => text().nullable()();

  IntColumn get targetWeekday => integer().named('target_weekday').nullable()();

  IntColumn get isActive => integer().named('is_active').withDefault(const Constant(1))();

  TextColumn get createdAt => text().named('created_at')();
}

@DriftDatabase(tables: [Tasks, TaskHistories, WeekMetas, RecurringTemplates])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.open() {
    return AppDatabase(_openLazyExecutor());
  }

  factory AppDatabase.memory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await m.database.customStatement(
            'CREATE TABLE IF NOT EXISTS monthly_goals ('
            'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
            'title TEXT NOT NULL, '
            'month TEXT NOT NULL, '
            'order_index INTEGER NOT NULL, '
            'status TEXT NOT NULL DEFAULT \'active\', '
            'created_at TEXT NOT NULL, '
            'updated_at TEXT NOT NULL, '
            'reminder_enabled INTEGER NOT NULL DEFAULT 0, '
            'reminder_weekday INTEGER, '
            'reminder_minutes INTEGER'
            ')',
          );
          await m.database.customStatement(
            'CREATE TABLE IF NOT EXISTS week_templates ('
            'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
            'name TEXT NOT NULL, '
            'created_at TEXT NOT NULL'
            ')',
          );
          await m.database.customStatement(
            'CREATE TABLE IF NOT EXISTS week_template_tasks ('
            'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
            'template_id INTEGER NOT NULL, '
            'title TEXT NOT NULL, '
            'duration_minutes INTEGER, '
            'notes TEXT, '
            'target_weekday INTEGER, '
            'order_index INTEGER NOT NULL'
            ')',
          );
          await _createTaskIndexes(m);
          await _createPeriodicRemindersTable(m);
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(tasks, tasks.completedAt);
          }
          if (from < 3) {
            await m.createTable(recurringTemplates);
          }
          if (from < 4) {
            await m.addColumn(tasks, tasks.startMinutes);
          }
          if (from < 5) {
            await m.database.customStatement(
              'CREATE TABLE IF NOT EXISTS monthly_goals ('
              'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
              'title TEXT NOT NULL, '
              'month TEXT NOT NULL, '
              'order_index INTEGER NOT NULL, '
              'status TEXT NOT NULL DEFAULT \'active\', '
              'created_at TEXT NOT NULL, '
              'updated_at TEXT NOT NULL'
              ')',
            );
          }
          if (from < 6) {
            await m.database.customStatement(
              'CREATE TABLE IF NOT EXISTS week_templates ('
              'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
              'name TEXT NOT NULL, '
              'created_at TEXT NOT NULL'
              ')',
            );
            await m.database.customStatement(
              'CREATE TABLE IF NOT EXISTS week_template_tasks ('
              'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
              'template_id INTEGER NOT NULL, '
              'title TEXT NOT NULL, '
              'duration_minutes INTEGER, '
              'notes TEXT, '
              'target_weekday INTEGER, '
              'order_index INTEGER NOT NULL'
              ')',
            );
          }
          if (from < 7) {
            await m.addColumn(tasks, tasks.accentColor);
          }
          if (from < 8) {
            await _createTaskIndexes(m);
          }
          if (from < 9) {
            await m.addColumn(tasks, tasks.reminderEnabled);
            await m.addColumn(tasks, tasks.reminderMinutes);
            await m.database.customStatement(
              'ALTER TABLE monthly_goals ADD COLUMN reminder_enabled '
              'INTEGER NOT NULL DEFAULT 0',
            );
            await m.database.customStatement(
              'ALTER TABLE monthly_goals ADD COLUMN reminder_weekday INTEGER',
            );
            await m.database.customStatement(
              'ALTER TABLE monthly_goals ADD COLUMN reminder_minutes INTEGER',
            );
          }
          if (from < 10) {
            await _createPeriodicRemindersTable(m);
          }
        },
      );

  static Future<void> _createPeriodicRemindersTable(Migrator m) async {
    await m.database.customStatement(
      'CREATE TABLE IF NOT EXISTS periodic_reminders ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'title TEXT NOT NULL, '
      'interval_days INTEGER NOT NULL, '
      'next_due_date TEXT NOT NULL, '
      'last_completed_at TEXT, '
      'order_index INTEGER NOT NULL, '
      'created_at TEXT NOT NULL, '
      'updated_at TEXT NOT NULL'
      ')',
    );
  }

  static Future<void> _createTaskIndexes(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tasks_week_start ON tasks(week_start)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tasks_week_planned ON tasks(week_start, planned_date)',
    );
  }
}

LazyDatabase _openLazyExecutor() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'weekly_planner.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
