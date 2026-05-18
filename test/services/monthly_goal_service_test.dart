import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/models/monthly_goal.dart';
import 'package:weekly_planner/services/monthly_goal_service.dart';

void main() {
  group('MonthlyGoalService', () {
    late AppDatabase db;
    late TaskRepository taskRepo;
    late MonthlyGoalService svc;

    setUp(() {
      db = AppDatabase.memory();
      taskRepo = TaskRepository(db);
      svc = MonthlyGoalService(taskRepo);
    });

    tearDown(() async {
      await db.close();
    });

    test('addGoalToWeek creates a task with correct title and plannedDate',
        () async {
      const week = '2025-06-02';
      const day = '2025-06-04';
      final goal = MonthlyGoal(
        id: 1,
        title: 'Hedef başlık',
        month: '2025-06',
        orderIndex: 1,
        status: 'active',
        createdAt: 't',
        updatedAt: 't',
      );
      final taskId = await svc.addGoalToWeek(goal, week, day);
      final task = await taskRepo.getTaskById(taskId);
      expect(task, isNotNull);
      expect(task!.title, 'Hedef başlık');
      expect(task.plannedDate, day);
      expect(task.weekStart, week);
    });

    test('addGoalToWeek with null plannedDate creates pool task', () async {
      const week = '2025-06-09';
      final goal = MonthlyGoal(
        id: 2,
        title: 'Havuz hedef',
        month: '2025-06',
        orderIndex: 1,
        status: 'active',
        createdAt: 't',
        updatedAt: 't',
      );
      final taskId = await svc.addGoalToWeek(goal, week, null);
      final task = await taskRepo.getTaskById(taskId);
      expect(task, isNotNull);
      expect(task!.plannedDate, isNull);
      expect(task.weekStart, week);
    });
  });
}
