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

  TextColumn get notes => text().nullable()();

  TextColumn get status => text().withDefault(const Constant('planned'))();

  TextColumn get weekStart => text().named('week_start')();

  TextColumn get plannedDate => text().named('planned_date').nullable()();

  TextColumn get originalPlannedDate => text().named('original_planned_date').nullable()();

  IntColumn get movedCount => integer().named('moved_count').withDefault(const Constant(0))();

  IntColumn get recurrenceTemplateId =>
      integer().named('recurrence_template_id').nullable()();

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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
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
        },
      );
}

LazyDatabase _openLazyExecutor() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'weekly_planner.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
