import 'package:drift/drift.dart';

import '../data/db/app_database.dart';
import '../data/repositories/recurring_template_repository.dart';
import '../data/repositories/task_repository.dart';

class WeekService {
  WeekService({
    required this.taskRepository,
    required this.templateRepository,
  });

  final TaskRepository taskRepository;
  final RecurringTemplateRepository templateRepository;

  Future<void> ensureWeekTasks(String weekStart) async {
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
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }
}
