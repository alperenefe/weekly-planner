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
  });
}
