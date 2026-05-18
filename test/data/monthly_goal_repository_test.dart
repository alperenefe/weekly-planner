import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/monthly_goal_repository.dart';
import 'package:weekly_planner/data/repositories/monthly_goals_companion.dart';

void main() {
  group('MonthlyGoalRepository', () {
    late AppDatabase db;
    late MonthlyGoalRepository repo;

    setUp(() {
      db = AppDatabase.memory();
      repo = MonthlyGoalRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('insertGoal assigns order_index 1 for first goal in month', () async {
      final now = DateTime.now().toUtc().toIso8601String();
      final id = await repo.insertGoal(
        MonthlyGoalsCompanion.insert(
          title: 'A',
          month: '2025-01',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final goals = await repo.getGoalsForMonth('2025-01');
      expect(goals.single.id, id);
      expect(goals.single.orderIndex, 1);
    });

    test('insertGoal assigns order_index 2 for second goal same month', () async {
      final now = DateTime.now().toUtc().toIso8601String();
      await repo.insertGoal(
        MonthlyGoalsCompanion.insert(
          title: 'A',
          month: '2025-02',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.insertGoal(
        MonthlyGoalsCompanion.insert(
          title: 'B',
          month: '2025-02',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final goals = await repo.getGoalsForMonth('2025-02');
      expect(goals.map((e) => e.orderIndex).toList(), [1, 2]);
    });

    test('insertGoal assigns order_index 1 for goal in different month', () async {
      final now = DateTime.now().toUtc().toIso8601String();
      await repo.insertGoal(
        MonthlyGoalsCompanion.insert(
          title: 'A',
          month: '2025-03',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.insertGoal(
        MonthlyGoalsCompanion.insert(
          title: 'B',
          month: '2025-04',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final m3 = await repo.getGoalsForMonth('2025-03');
      final m4 = await repo.getGoalsForMonth('2025-04');
      expect(m3.single.orderIndex, 1);
      expect(m4.single.orderIndex, 1);
    });

    test('markGoalDone sets status done', () async {
      final now = DateTime.now().toUtc().toIso8601String();
      final id = await repo.insertGoal(
        MonthlyGoalsCompanion.insert(
          title: 'X',
          month: '2025-05',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.markGoalDone(id);
      final g = (await repo.getGoalsForMonth('2025-05')).single;
      expect(g.status, 'done');
    });

    test('markGoalActive sets status active', () async {
      final now = DateTime.now().toUtc().toIso8601String();
      final id = await repo.insertGoal(
        MonthlyGoalsCompanion.insert(
          title: 'X',
          month: '2025-06',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.markGoalDone(id);
      await repo.markGoalActive(id);
      final g = (await repo.getGoalsForMonth('2025-06')).single;
      expect(g.status, 'active');
    });

    test('getMonthSummary returns correct totalGoals and doneGoals', () async {
      final now = DateTime.now().toUtc().toIso8601String();
      final m = '2025-07';
      final id1 = await repo.insertGoal(
        MonthlyGoalsCompanion.insert(
          title: 'a',
          month: m,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.insertGoal(
        MonthlyGoalsCompanion.insert(
          title: 'b',
          month: m,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.markGoalDone(id1);
      final s = await repo.getMonthSummary(m);
      expect(s.totalGoals, 2);
      expect(s.doneGoals, 1);
    });
  });
}
