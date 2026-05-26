import 'package:drift/drift.dart';

import '../data/db/app_database.dart';
import '../data/repositories/monthly_goal_repository.dart';
import '../data/repositories/monthly_goals_companion.dart';
import '../data/repositories/recurring_template_repository.dart';
import '../data/repositories/task_repository.dart';
import '../date/week_calendar.dart';

/// Ayarlardan isteğe bağlı örnek veri (ilk kurulumda otomatik değil).
class DemoDataSeeder {
  DemoDataSeeder({
    required TaskRepository taskRepo,
    required MonthlyGoalRepository goalRepo,
    required RecurringTemplateRepository templateRepo,
  })  : _taskRepo = taskRepo,
        _goalRepo = goalRepo,
        _templateRepo = templateRepo;

  final TaskRepository _taskRepo;
  final MonthlyGoalRepository _goalRepo;
  final RecurringTemplateRepository _templateRepo;

  Future<int> seedIfWeekEmpty(String weekStart) async {
    final existing = await _taskRepo.getTasksForWeek(weekStart);
    if (existing.isNotEmpty) return 0;

    final now = DateTime.now().toUtc().toIso8601String();
    final monday = weekStart;
    final wed = addDaysIso(monday, 2);

    await _taskRepo.insertTask(
      TasksCompanion.insert(
        title: 'Proje planlama',
        durationMinutes: const Value(45),
        startMinutes: const Value(10 * 60),
        weekStart: monday,
        plannedDate: Value(monday),
        originalPlannedDate: Value(monday),
        status: const Value('done'),
        completedAt: Value(now),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _taskRepo.insertTask(
      TasksCompanion.insert(
        title: 'Blog taslağı',
        durationMinutes: const Value(90),
        weekStart: monday,
        plannedDate: Value(wed),
        originalPlannedDate: Value(wed),
        movedCount: const Value(1),
        accentColor: const Value(0xFF8B5CF6),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _taskRepo.insertTask(
      TasksCompanion.insert(
        title: 'Havuz: alışveriş listesi',
        weekStart: monday,
        accentColor: const Value(0xFFF59E0B),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final month = '${DateTime.now().year.toString().padLeft(4, '0')}-'
        '${DateTime.now().month.toString().padLeft(2, '0')}';
    final goals = await _goalRepo.getGoalsForMonth(month);
    if (goals.isEmpty) {
      await _goalRepo.insertGoal(
        MonthlyGoalsCompanion.insert(
          title: 'Haftada 3 spor seansı',
          month: month,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    final templates = await _templateRepo.getActiveTemplates();
    if (templates.isEmpty) {
      await _templateRepo.insertTemplate(
        RecurringTemplatesCompanion.insert(
          title: 'Sabah planlama',
          durationMinutes: const Value(15),
          targetWeekday: const Value(1),
          isActive: const Value(1),
          createdAt: now,
        ),
      );
    }

    return 3;
  }
}
