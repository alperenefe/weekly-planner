import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/services/export_service.dart';
import 'package:weekly_planner/services/summary_service.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  late ExportService export;

  setUp(() {
    db = AppDatabase.memory();
    repo = TaskRepository(db);
    export = ExportService(repo, SummaryService(repo));
  });

  tearDown(() async {
    await db.close();
  });

  test('exportJson includes task fields and nested history', () async {
    const week = '2024-10-28';
    final now = DateTime.utc(2024, 10, 28, 8).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'Müşteri sunumu',
        weekStart: week,
        plannedDate: Value(week),
        originalPlannedDate: Value(week),
        durationMinutes: const Value(60),
        status: const Value('done'),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.moveTask(id, '2024-10-29');

    final jsonStr = await export.exportJson(week);
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    expect(map['weekStart'], week);
    expect(map['tasks'], isA<List<dynamic>>());
    final tasks = map['tasks'] as List<dynamic>;
    expect(tasks.length, 1);
    final t = tasks.single as Map<String, dynamic>;
    expect(t['id'], id);
    expect(t['title'], 'Müşteri sunumu');
    expect(t['status'], 'done');
    expect(t['plannedDate'], '2024-10-29');
    expect(t['durationMinutes'], 60);
    expect(t['startMinutes'], isNull);
    expect(t['movedCount'], 0);
    expect(t['notes'], isNull);
    final hist = t['history'] as List<dynamic>;
    expect(hist.length, greaterThanOrEqualTo(2));
    expect((hist.first as Map)['eventType'], 'created');
    final moved = hist.cast<Map<String, dynamic>>().where((h) => h['eventType'] == 'moved').toList();
    expect(moved.length, 1);
    expect(moved.single['fromDate'], week);
    expect(moved.single['toDate'], '2024-10-29');
  });

  test('exportJson pool task has null plannedDate', () async {
    const week = '2024-10-28';
    final now = DateTime.utc(2024, 10, 28, 9).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Havuz',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final jsonStr = await export.exportJson(week);
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final tasks = map['tasks'] as List<dynamic>;
    expect((tasks.single as Map)['plannedDate'], isNull);
    expect((tasks.single as Map)['durationMinutes'], isNull);
    expect((tasks.single as Map)['startMinutes'], isNull);
  });

  test('exportJson empty week', () async {
    const week = '2024-10-28';
    final jsonStr = await export.exportJson(week);
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    expect(map['tasks'], isEmpty);
  });

  test('exportLlmText has header completion pool days and task tags', () async {
    const week = '2024-10-28';
    final mon = week;
    final now = DateTime.utc(2024, 10, 28, 10).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Done etkinlik',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        durationMinutes: const Value(60),
        status: const Value('done'),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Havuz etkinlik',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final text = await export.exportLlmText(week);
    expect(text, contains('Hafta:'));
    expect(text, contains('Tamamlanan:'));
    expect(text, contains('%'));
    expect(text, contains('Havuz:'));
    expect(text, contains('Günler:'));
    expect(text, contains('Etkinlikler:'));
    expect(text, contains('[done]'));
    expect(text, contains('[pool]'));
  });

  test('exportLlmText empty week', () async {
    const week = '2024-10-28';
    final text = await export.exportLlmText(week);
    expect(text, contains('Hafta:'));
    expect(text, contains('Tamamlanan: 0 dk / 0 dk (%0)'));
  });
}
