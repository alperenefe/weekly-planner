import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/date/week_calendar.dart';
import 'package:weekly_planner/services/summary_service.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  late SummaryService summary;

  setUp(() {
    db = AppDatabase.memory();
    repo = TaskRepository(db);
    summary = SummaryService(repo);
  });

  tearDown(() async {
    await db.close();
  });

  test('weekSummary empty week has zeros and seven daily keys', () async {
    const week = '2025-01-06';
    final s = await summary.weekSummary(week);
    expect(s.plannedMinutes, 0);
    expect(s.completedMinutes, 0);
    expect(s.poolMinutes, 0);
    expect(s.completionPercent, 0.0);
    expect(s.dailyBreakdown.length, 7);
    final days = weekdayIsosFromMonday(week);
    for (final iso in days) {
      expect(s.dailyBreakdown[iso]!.plannedMinutes, 0);
      expect(s.dailyBreakdown[iso]!.completedMinutes, 0);
    }
    expect(s.totalTasks, 0);
    expect(s.completedTasks, 0);
    expect(s.skippedTasks, 0);
    expect(s.movedTasks, 0);
    expect(s.poolRemainingTasks, 0);
  });

  test('weekSummary counts pool planned done and null duration', () async {
    const week = '2025-01-06';
    final mon = week;
    final tue = addDaysIso(week, 1);
    final now = DateTime.utc(2025, 1, 1, 9).toIso8601String();

    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Pool',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
        durationMinutes: const Value(10),
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'NoDur',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Planned',
        weekStart: week,
        plannedDate: Value(tue),
        originalPlannedDate: Value(tue),
        durationMinutes: const Value(30),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Done',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        durationMinutes: const Value(20),
        status: const Value('done'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final s = await summary.weekSummary(week);

    expect(s.plannedMinutes, 10 + 0 + 30 + 20);
    expect(s.completedMinutes, 20);
    expect(s.poolMinutes, 10);
    expect(s.completionPercent, closeTo(20 / 60 * 100, 0.001));

    expect(s.dailyBreakdown[mon]!.plannedMinutes, 0 + 20);
    expect(s.dailyBreakdown[mon]!.completedMinutes, 20);
    expect(s.dailyBreakdown[tue]!.plannedMinutes, 30);
    expect(s.dailyBreakdown[tue]!.completedMinutes, 0);

    final wed = addDaysIso(week, 2);
    expect(s.dailyBreakdown[wed]!.plannedMinutes, 0);
    expect(s.dailyBreakdown[wed]!.completedMinutes, 0);

    expect(s.totalTasks, 4);
    expect(s.completedTasks, 1);
    expect(s.skippedTasks, 0);
    expect(s.movedTasks, 0);
    expect(s.poolRemainingTasks, 1);
  });

  test('weekSummary counts skipped moved poolRemaining and movedTasks', () async {
    const week = '2025-02-03';
    final mon = week;
    final now = DateTime.utc(2025, 2, 1, 9).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'SkipPool',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
        status: const Value('skipped'),
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Moved',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        durationMinutes: const Value(5),
        movedCount: const Value(2),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'DoneNoMove',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        status: const Value('done'),
        createdAt: now,
        updatedAt: now,
      ),
    );
    final s = await summary.weekSummary(week);
    expect(s.totalTasks, 3);
    expect(s.skippedTasks, 1);
    expect(s.movedTasks, 1);
    expect(s.completedTasks, 1);
    expect(s.poolRemainingTasks, 1);
  });

  test('weekTrend returns 4 items with correct labels', () async {
    const week = '2025-03-10';
    final trend = await summary.weekTrend(week);
    expect(trend.length, 4);
    expect(trend[0].weekLabel, 'Bu hafta');
    expect(trend[0].weekStart, week);
    expect(trend[1].weekLabel, 'Geçen hafta');
    expect(trend[1].weekStart, addDaysIso(week, -7));
    expect(trend[2].weekLabel, '2 hafta önce');
    expect(trend[3].weekLabel, '3 hafta önce');
  });

  test('weekTrend returns 0% for weeks with no tasks', () async {
    const week = '2025-04-07';
    final trend = await summary.weekTrend(week);
    for (final item in trend) {
      expect(item.completionPercent, 0.0);
    }
  });

  test('postponeAnalysis returns mostMovedTasks sorted by movedCount desc', () async {
    const week = '2025-05-05';
    final mon = week;
    final now = DateTime.utc(2025, 5, 1, 9).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'A',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        movedCount: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'B',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        movedCount: const Value(5),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'C',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        movedCount: const Value(3),
        createdAt: now,
        updatedAt: now,
      ),
    );
    final a = await summary.postponeAnalysis(week);
    expect(a.mostMovedTasks.length, 3);
    expect(a.mostMovedTasks.map((t) => t.title).toList(), ['B', 'C', 'A']);
  });

  test('postponeAnalysis neverMovedCompleted counts correctly', () async {
    const week = '2025-06-02';
    final mon = week;
    final now = DateTime.utc(2025, 6, 1, 9).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'D1',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        status: const Value('done'),
        movedCount: const Value(0),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'D2',
        weekStart: week,
        plannedDate: Value(mon),
        originalPlannedDate: Value(mon),
        status: const Value('done'),
        movedCount: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
    );
    final a = await summary.postponeAnalysis(week);
    expect(a.neverMovedCompleted, 1);
  });

  test('postponeAnalysis avgMovesPerMovedTask is 0.0 when no moved tasks', () async {
    const week = '2025-06-09';
    final now = DateTime.utc(2025, 6, 1, 9).toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Static',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final a = await summary.postponeAnalysis(week);
    expect(a.mostMovedTasks, isEmpty);
    expect(a.avgMovesPerMovedTask, 0.0);
  });
}
