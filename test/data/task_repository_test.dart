import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = TaskRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insertTask creates task and history', () async {
    const week = '2024-10-28';
    final now = DateTime.utc(2024, 10, 28, 12).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'A',
        durationMinutes: const Value(30),
        notes: const Value('n1'),
        weekStart: week,
        plannedDate: const Value.absent(),
        originalPlannedDate: const Value.absent(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(id, greaterThan(0));

    final weekTasks = await repo.getTasksForWeek(week);
    expect(weekTasks.length, 1);
    expect(weekTasks.single.title, 'A');
    expect(weekTasks.single.plannedDate, isNull);

    final pool = await repo.getPoolTasks(week);
    expect(pool.length, 1);

    final histories = await db.select(db.taskHistories).get();
    expect(histories.length, 1);
    expect(histories.single.taskId, id);
    expect(histories.single.eventType, 'created');
  });

  test('insertTask stores startMinutes', () async {
    const week = '2024-10-28';
    final now = DateTime.utc(2024, 10, 28, 20).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'Alarm',
        weekStart: week,
        plannedDate: Value(week),
        originalPlannedDate: Value(week),
        startMinutes: const Value(570),
        createdAt: now,
        updatedAt: now,
      ),
    );
    final t = await repo.getTaskById(id);
    expect(t?.startMinutes, 570);
  });

  test('deleteTask removes task and history rows', () async {
    const week = '2024-10-28';
    final now = DateTime.utc(2024, 10, 28, 21).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'DelMe',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.markDone(id);
    await repo.deleteTask(id);
    expect(await repo.getTaskById(id), isNull);
    final hist = await (db.select(db.taskHistories)
          ..where((h) => h.taskId.equals(id)))
        .get();
    expect(hist, isEmpty);
  });

  test('getDayTasks filters by planned_date', () async {
    const week = '2024-10-28';
    final mon = week;
    final tue = '2024-10-29';
    final now = DateTime.utc(2024, 10, 28, 8).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Mon',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Tue',
        weekStart: week,
        plannedDate: Value(tue),
        originalPlannedDate: Value(tue),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final monTasks = await repo.getDayTasks(week, mon);
    expect(monTasks.map((e) => e.title).toList(), ['Mon']);

    final tueTasks = await repo.getDayTasks(week, tue);
    expect(tueTasks.map((e) => e.title).toList(), ['Tue']);
  });

  test('getDayTasks orders by start time then createdAt', () async {
    const week = '2024-10-28';
    final mon = week;
    final early = DateTime.utc(2024, 10, 28, 10).toIso8601String();
    final late = DateTime.utc(2024, 10, 28, 11).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'NinePm',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        startMinutes: const Value(21 * 60),
        createdAt: early,
        updatedAt: early,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'EightPm',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        startMinutes: const Value(20 * 60),
        createdAt: late,
        updatedAt: late,
      ),
    );
    final monTasks = await repo.getDayTasks(week, mon);
    expect(monTasks.map((e) => e.title).toList(), ['EightPm', 'NinePm']);
  });

  test('shiftPlannedDayTasksAfterAnchor shifts timed tasks from anchor', () async {
    const week = '2024-10-28';
    final mon = week;
    final t1 = DateTime.utc(2024, 10, 28, 8).toIso8601String();
    final t2 = DateTime.utc(2024, 10, 28, 9).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Eight',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        startMinutes: const Value(20 * 60),
        createdAt: t1,
        updatedAt: t1,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Nine',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        startMinutes: const Value(21 * 60),
        createdAt: t2,
        updatedAt: t2,
      ),
    );
    final n = await repo.shiftPlannedDayTasksAfterAnchor(
      weekStart: week,
      plannedDateIso: mon,
      anchorStartMinutes: 20 * 60 + 30,
      breakMinutes: 30,
    );
    expect(n, 1);
    final list = await repo.getDayTasks(week, mon);
    final eight = list.firstWhere((e) => e.title == 'Eight');
    final nine = list.firstWhere((e) => e.title == 'Nine');
    expect(eight.startMinutes, 20 * 60);
    expect(nine.startMinutes, 21 * 60 + 30);
  });

  test('updateTask persists changes', () async {
    const week = '2024-10-28';
    final now = DateTime.utc(2024, 10, 28, 9).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'Old',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final row = (await repo.getTasksForWeek(week)).single;
    final updated = row.copyWith(title: 'New', updatedAt: now);
    await repo.updateTask(updated);

    final again = await repo.getTasksForWeek(week);
    expect(again.single.title, 'New');
    expect(again.single.id, id);
  });

  test('moveTask updates planned_date, moved_count, and history', () async {
    const week = '2024-10-28';
    final mon = week;
    final wed = '2024-10-30';
    final now = DateTime.utc(2024, 10, 28, 10).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'M',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await repo.moveTask(id, wed);

    final t = (await repo.getDayTasks(week, wed)).single;
    expect(t.title, 'M');
    expect(t.movedCount, 0);
    expect(t.plannedDate, wed);

    final moved = await (db.select(db.taskHistories)
          ..where((h) => h.taskId.equals(id) & h.eventType.equals('moved')))
        .get();
    expect(moved.length, 1);
    expect(moved.single.fromDate, mon);
    expect(moved.single.toDate, wed);
  });

  test('moveTask to pool sets planned_date null', () async {
    const week = '2024-10-28';
    final mon = week;
    final now = DateTime.utc(2024, 10, 28, 11).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'P',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await repo.moveTask(id, null);

    final pool = await repo.getPoolTasks(week);
    expect(pool.single.id, id);
    expect(pool.single.plannedDate, isNull);
    expect(pool.single.movedCount, 0);
  });

  test('moveTask from pool to day increments moved_count', () async {
    const week = '2024-10-28';
    final mon = week;
    final now = DateTime.utc(2024, 10, 28, 11).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'FromPool',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect((await repo.getPoolTasks(week)).single.movedCount, 0);

    await repo.moveTask(id, mon);

    final t = (await repo.getDayTasks(week, mon)).single;
    expect(t.movedCount, 1);
    expect(t.plannedDate, mon);
  });

  test('markDone sets status, completedAt, and history', () async {
    const week = '2024-10-28';
    final now = DateTime.utc(2024, 10, 28, 12).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'D',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await repo.markDone(id);

    final t = (await repo.getTasksForWeek(week)).single;
    expect(t.status, 'done');
    expect(t.completedAt, isNotNull);

    final ev = await (db.select(db.taskHistories)
          ..where((h) => h.taskId.equals(id) & h.eventType.equals('completed')))
        .get();
    expect(ev.length, 1);

    await repo.markDone(id);
    final ev2 = await (db.select(db.taskHistories)
          ..where((h) => h.taskId.equals(id) & h.eventType.equals('completed')))
        .get();
    expect(ev2.length, 1);
  });

  test('unmarkDone restores planned and clears completedAt', () async {
    const week = '2024-10-28';
    final now = DateTime.utc(2024, 10, 28, 14).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'U',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await repo.markDone(id);
    await repo.unmarkDone(id);

    final t = (await repo.getTasksForWeek(week)).single;
    expect(t.status, 'planned');
    expect(t.completedAt, isNull);

    final reopened = await (db.select(db.taskHistories)
          ..where((h) => h.taskId.equals(id) & h.eventType.equals('reopened')))
        .get();
    expect(reopened.length, 1);

    await repo.unmarkDone(id);
    final reopened2 = await (db.select(db.taskHistories)
          ..where((h) => h.taskId.equals(id) & h.eventType.equals('reopened')))
        .get();
    expect(reopened2.length, 1);
  });

  test('copyLastWeekTasks copies planned-date tasks with weekday mapping', () async {
    const prev = '2025-01-06';
    const cur = '2025-01-13';
    final now = DateTime.utc(2025, 1, 1, 8).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'PoolOnly',
        weekStart: prev,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Mon',
        weekStart: prev,
        plannedDate: Value(prev),
        originalPlannedDate: Value(prev),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Wed',
        weekStart: prev,
        plannedDate: const Value('2025-01-08'),
        originalPlannedDate: const Value('2025-01-08'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await repo.copyLastWeekTasks(cur);

    final curWeek = await repo.getTasksForWeek(cur);
    expect(curWeek.where((t) => t.title == 'PoolOnly'), isEmpty);
    expect(curWeek.where((t) => t.title == 'Mon').single.plannedDate, cur);
    expect(curWeek.where((t) => t.title == 'Wed').single.plannedDate, '2025-01-15');

    final beforeSecond = curWeek.length;
    await repo.copyLastWeekTasks(cur);
    final afterSecond = await repo.getTasksForWeek(cur);
    expect(afterSecond.length, beforeSecond);
    expect(await repo.isCopyFromPreviousApplied(cur), isTrue);
  });

  test('copyLastWeekTasks does not set WeekMeta when previous week has no planned tasks', () async {
    const prev = '2025-02-03';
    const cur = '2025-02-10';
    final now = DateTime.utc(2025, 2, 1, 8).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'PoolOnly',
        weekStart: prev,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.copyLastWeekTasks(cur);
    expect(await repo.isCopyFromPreviousApplied(cur), isFalse);
    expect((await repo.getTasksForWeek(cur)), isEmpty);
  });

  test('getPastWeeks returns older weeks descending', () async {
    const w1 = '2024-10-07';
    const w2 = '2024-10-14';
    const current = '2024-10-21';
    final now = DateTime.utc(2024, 10, 1, 8).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(title: 'a', weekStart: w1, createdAt: now, updatedAt: now),
    );
    await repo.insertTask(
      TasksCompanion.insert(title: 'b', weekStart: w2, createdAt: now, updatedAt: now),
    );
    final past = await repo.getPastWeeks(current);
    expect(past, [w2, w1]);
  });

  test('resetAllData clears tasks task_history week_meta recurring_templates', () async {
    const week = '2024-10-28';
    final now = DateTime.utc(2024, 10, 28, 8).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Keep',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.into(db.weekMetas).insert(
      WeekMetasCompanion.insert(
        weekStart: week,
        copyFromPreviousApplied: const Value(1),
      ),
    );
    await db.into(db.recurringTemplates).insert(
      RecurringTemplatesCompanion.insert(
        title: 'Tpl',
        createdAt: now,
      ),
    );

    expect(await db.select(db.tasks).get(), isNotEmpty);
    expect(await db.select(db.taskHistories).get(), isNotEmpty);
    expect(await db.select(db.weekMetas).get(), isNotEmpty);
    expect(await db.select(db.recurringTemplates).get(), isNotEmpty);

    await repo.resetAllData();

    expect(await db.select(db.tasks).get(), isEmpty);
    expect(await db.select(db.taskHistories).get(), isEmpty);
    expect(await db.select(db.weekMetas).get(), isEmpty);
    expect(await db.select(db.recurringTemplates).get(), isEmpty);
  });
}
