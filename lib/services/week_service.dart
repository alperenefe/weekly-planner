import 'package:drift/drift.dart';

import '../data/db/app_database.dart';
import '../data/repositories/recurring_template_repository.dart';
import '../data/repositories/task_repository.dart';
import '../date/week_calendar.dart';
import 'planner_feature_flags_store.dart';

class WeekService {
  WeekService({
    required this.taskRepository,
    required this.templateRepository,
    required this.featureFlagsStore,
  });

  final TaskRepository taskRepository;
  final RecurringTemplateRepository templateRepository;
  final PlannerFeatureFlagsStore featureFlagsStore;

  Future<void> ensureWeekTasks(String weekStart) async {
    if (!featureFlagsStore.flags.recurringTemplatesEnabled) {
      return;
    }
    final templates = await templateRepository.getActiveTemplates();
    final now = DateTime.now().toUtc().toIso8601String();
    for (final template in templates) {
      final exists = await taskRepository.hasTaskForRecurrenceInWeek(
        template.id,
        weekStart,
      );
      if (exists) {
        continue;
      }
      final tw = template.targetWeekday;
      String? plannedIso;
      if (tw != null && tw >= 1 && tw <= 7) {
        plannedIso = plannedDateForChipIndex(weekStart, tw);
      }
      await taskRepository.insertTask(
        TasksCompanion.insert(
          title: template.title,
          durationMinutes: template.durationMinutes == null
              ? const Value.absent()
              : Value(template.durationMinutes),
          notes: template.notes == null
              ? const Value.absent()
              : Value(template.notes),
          recurrenceTemplateId: Value(template.id),
          weekStart: weekStart,
          plannedDate: plannedIso == null
              ? const Value.absent()
              : Value(plannedIso),
          originalPlannedDate: plannedIso == null
              ? const Value.absent()
              : Value(plannedIso),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }
}
