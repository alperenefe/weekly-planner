import 'package:drift/drift.dart';

import '../data/db/app_database.dart';
import '../data/repositories/task_repository.dart';
import '../models/monthly_goal.dart';

class MonthlyGoalService {
  MonthlyGoalService(this._taskRepository);

  final TaskRepository _taskRepository;

  Future<int> addGoalToWeek(
    MonthlyGoal goal,
    String weekStart,
    String? plannedDate,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    return _taskRepository.insertTask(
      TasksCompanion.insert(
        title: goal.title,
        weekStart: weekStart,
        plannedDate: plannedDate == null
            ? const Value.absent()
            : Value(plannedDate),
        originalPlannedDate: plannedDate == null
            ? const Value.absent()
            : Value(plannedDate),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
