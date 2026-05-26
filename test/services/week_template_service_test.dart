import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/data/repositories/week_template_repository.dart';
import 'package:weekly_planner/data/repositories/week_template_tasks_companion.dart';
import 'package:weekly_planner/plan_data_revision.dart';
import 'package:weekly_planner/services/week_template_service.dart';

class CountingPlanDataRevision extends PlanDataRevision {
  int bumps = 0;

  @override
  void bump() {
    bumps++;
    super.bump();
  }
}

void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;
  late WeekTemplateRepository weekTplRepo;
  late CountingPlanDataRevision revision;
  late WeekTemplateService svc;

  setUp(() {
    db = AppDatabase.memory();
    taskRepo = TaskRepository(db);
    weekTplRepo = WeekTemplateRepository(db);
    revision = CountingPlanDataRevision();
    svc = WeekTemplateService(taskRepo, weekTplRepo, revision);
  });

  tearDown(() async {
    await db.close();
  });

  test('applyTemplate with pool task creates task with plannedDate null', () async {
    const weekStart = '2025-01-13';
    final tplId = await weekTplRepo.insertTemplate('P');
    await weekTplRepo.insertTemplateTask(
      WeekTemplateTasksCompanion.insert(
        templateId: tplId,
        title: 'Havuz işi',
      ),
    );
    final n = await svc.applyTemplate(tplId, weekStart);
    expect(n, 1);
    final tasks = await taskRepo.getTasksForWeek(weekStart);
    expect(tasks.length, 1);
    expect(tasks.single.plannedDate, equals(null));
    expect(tasks.single.title, 'Havuz işi');
    expect(tasks.single.weekStart, weekStart);
  });

  test('applyTemplate with weekday 3 and weekStart 2025-01-13 creates plannedDate 2025-01-15',
      () async {
    const weekStart = '2025-01-13';
    final tplId = await weekTplRepo.insertTemplate('W');
    await weekTplRepo.insertTemplateTask(
      WeekTemplateTasksCompanion.insert(
        templateId: tplId,
        title: 'Çar',
        targetWeekday: const Value(3),
      ),
    );
    await svc.applyTemplate(tplId, weekStart);
    final tasks = await taskRepo.getTasksForWeek(weekStart);
    expect(tasks.single.plannedDate, '2025-01-15');
    expect(tasks.single.originalPlannedDate, '2025-01-15');
  });

  test('applyTemplate with 3 tasks inserts 3 tasks in DB', () async {
    const weekStart = '2025-02-03';
    final tplId = await weekTplRepo.insertTemplate('Three');
    for (var i = 0; i < 3; i++) {
      await weekTplRepo.insertTemplateTask(
        WeekTemplateTasksCompanion.insert(
          templateId: tplId,
          title: 't$i',
        ),
      );
    }
    final n = await svc.applyTemplate(tplId, weekStart);
    expect(n, 3);
    expect((await taskRepo.getTasksForWeek(weekStart)).length, 3);
  });

  test('applyTemplate twice doubles task count', () async {
    const weekStart = '2025-04-07';
    final tplId = await weekTplRepo.insertTemplate('Dup');
    await weekTplRepo.insertTemplateTask(
      WeekTemplateTasksCompanion.insert(templateId: tplId, title: 'A'),
    );
    await svc.applyTemplate(tplId, weekStart);
    await svc.applyTemplate(tplId, weekStart);
    expect((await taskRepo.getTasksForWeek(weekStart)).length, 2);
  });

  test('applyTemplate calls PlanDataRevision bump', () async {
    final tplId = await weekTplRepo.insertTemplate('B');
    await weekTplRepo.insertTemplateTask(
      WeekTemplateTasksCompanion.insert(templateId: tplId, title: 'x'),
    );
    expect(revision.bumps, 0);
    await svc.applyTemplate(tplId, '2025-03-10');
    expect(revision.bumps, 1);
  });
}
