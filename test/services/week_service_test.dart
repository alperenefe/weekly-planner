import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/recurring_template_repository.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/services/week_service.dart';

void main() {
  late AppDatabase db;
  late TaskRepository tasks;
  late RecurringTemplateRepository templates;
  late WeekService week;

  setUp(() {
    db = AppDatabase.memory();
    tasks = TaskRepository(db);
    templates = RecurringTemplateRepository(db);
    week = WeekService(
      taskRepository: tasks,
      templateRepository: templates,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('ensureWeekTasks inserts pool task once per template per week', () async {
    const weekStart = '2025-01-06';
    final now = DateTime.utc(2025, 1, 1, 10).toIso8601String();
    final tid = await templates.insertTemplate(
      RecurringTemplatesCompanion.insert(
        title: 'R1',
        durationMinutes: const Value(15),
        createdAt: now,
      ),
    );

    await week.ensureWeekTasks(weekStart);
    await week.ensureWeekTasks(weekStart);

    final weekTasks = await tasks.getTasksForWeek(weekStart);
    final linked = weekTasks.where((t) => t.recurrenceTemplateId == tid).toList();
    expect(linked.length, 1);
    expect(linked.single.title, 'R1');
    expect(linked.single.plannedDate, isNull);
  });
}
