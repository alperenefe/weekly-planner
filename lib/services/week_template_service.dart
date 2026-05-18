import 'package:drift/drift.dart';

import '../data/db/app_database.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/week_template_repository.dart';
import '../date/week_calendar.dart';
import '../plan_data_revision.dart';

class WeekTemplateService {
  WeekTemplateService(
    this._taskRepository,
    this._weekTemplateRepository,
    this._planDataRevision,
  );

  final TaskRepository _taskRepository;
  final WeekTemplateRepository _weekTemplateRepository;
  final PlanDataRevision _planDataRevision;

  Future<int> applyTemplate(int templateId, String weekStart) async {
    final detail = await _weekTemplateRepository.getTemplateWithTasks(templateId);
    final now = DateTime.now().toUtc().toIso8601String();
    final companions = <TasksCompanion>[];
    for (final t in detail.tasks) {
      final String? plannedIso = t.targetWeekday == null
          ? null
          : addDaysIso(weekStart, t.targetWeekday! - 1);
      companions.add(
        TasksCompanion.insert(
          title: t.title,
          durationMinutes: t.durationMinutes == null
              ? const Value.absent()
              : Value(t.durationMinutes!),
          notes: t.notes == null ? const Value.absent() : Value(t.notes!),
          status: const Value('planned'),
          weekStart: weekStart,
          plannedDate: plannedIso == null
              ? const Value.absent()
              : Value(plannedIso),
          originalPlannedDate: plannedIso == null
              ? const Value.absent()
              : Value(plannedIso),
          movedCount: const Value(0),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    final n = await _taskRepository.insertTasksInTransaction(companions);
    _planDataRevision.bump();
    return n;
  }
}
