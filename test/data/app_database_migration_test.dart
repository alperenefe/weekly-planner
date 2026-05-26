import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:weekly_planner/data/db/app_database.dart';

void _createLegacySchemaV1(Database sqliteDb) {
  sqliteDb.execute('''
    CREATE TABLE tasks (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      duration_minutes INTEGER,
      notes TEXT,
      status TEXT NOT NULL DEFAULT 'planned',
      week_start TEXT NOT NULL,
      planned_date TEXT,
      original_planned_date TEXT,
      moved_count INTEGER NOT NULL DEFAULT 0,
      recurrence_template_id INTEGER,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');
  sqliteDb.execute('''
    CREATE TABLE task_history (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      task_id INTEGER NOT NULL,
      event_type TEXT NOT NULL,
      from_date TEXT,
      to_date TEXT,
      timestamp TEXT NOT NULL,
      note TEXT
    )
  ''');
  sqliteDb.execute('''
    CREATE TABLE week_meta (
      week_start TEXT NOT NULL PRIMARY KEY,
      copy_from_previous_applied INTEGER NOT NULL DEFAULT 0
    )
  ''');
  sqliteDb.execute('PRAGMA user_version = 1');
}

Future<bool> _tableExists(GeneratedDatabase db, String name) async {
  final rows = await db.customSelect(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
    variables: [Variable.withString(name)],
  ).get();
  return rows.isNotEmpty;
}

Future<bool> _indexExists(GeneratedDatabase db, String name) async {
  final rows = await db.customSelect(
    "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
    variables: [Variable.withString(name)],
  ).get();
  return rows.isNotEmpty;
}

void main() {
  test('legacy v1 database migrates to schema v9 with data preserved', () async {
    final sqliteDb = sqlite3.openInMemory();
    _createLegacySchemaV1(sqliteDb);
    const weekStart = '2024-06-03';
    const now = '2024-06-01T12:00:00.000Z';
    sqliteDb.execute(
      "INSERT INTO tasks (title, week_start, status, moved_count, created_at, updated_at) "
      "VALUES ('Eski görev', '$weekStart', 'planned', 0, '$now', '$now')",
    );

    final migrated = AppDatabase(NativeDatabase.opened(sqliteDb));
    expect(migrated.schemaVersion, 9);

    final tasks = await migrated.select(migrated.tasks).get();
    expect(tasks, hasLength(1));
    expect(tasks.single.title, 'Eski görev');
    expect(tasks.single.weekStart, weekStart);
    expect(tasks.single.completedAt, isNull);
    expect(tasks.single.startMinutes, isNull);
    expect(tasks.single.accentColor, isNull);
    expect(tasks.single.reminderEnabled, 0);
    expect(tasks.single.reminderMinutes, isNull);

    expect(await _tableExists(migrated, 'recurring_templates'), isTrue);
    expect(await _tableExists(migrated, 'monthly_goals'), isTrue);
    expect(await _tableExists(migrated, 'week_templates'), isTrue);
    expect(await _tableExists(migrated, 'week_template_tasks'), isTrue);
    expect(await _indexExists(migrated, 'idx_tasks_week_start'), isTrue);
    expect(await _indexExists(migrated, 'idx_tasks_week_planned'), isTrue);

    await migrated.close();
  });

  test('fresh database has task indexes at v9', () async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    expect(db.schemaVersion, 9);
    expect(await _indexExists(db, 'idx_tasks_week_start'), isTrue);
    expect(await _indexExists(db, 'idx_tasks_week_planned'), isTrue);
  });
}
