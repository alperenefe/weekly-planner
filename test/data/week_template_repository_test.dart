import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/week_template_repository.dart';
import 'package:weekly_planner/data/repositories/week_template_tasks_companion.dart';

void main() {
  late AppDatabase db;
  late WeekTemplateRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = WeekTemplateRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insertTemplate creates template with given name', () async {
    final id = await repo.insertTemplate('Yoğun Hafta');
    expect(id, greaterThan(0));
    final list = await repo.getTemplates();
    expect(list.length, 1);
    expect(list.single.name, 'Yoğun Hafta');
    expect(list.single.taskCount, 0);
  });

  test('insertTemplateTask adds task to template', () async {
    final tid = await repo.insertTemplate('T');
    final taskId = await repo.insertTemplateTask(
      WeekTemplateTasksCompanion.insert(
        templateId: tid,
        title: 'Görev 1',
      ),
    );
    expect(taskId, greaterThan(0));
    final d = await repo.getTemplateWithTasks(tid);
    expect(d.tasks.length, 1);
    expect(d.tasks.single.title, 'Görev 1');
    expect(d.template.taskCount, 1);
  });

  test('getTemplateWithTasks returns template + all its tasks', () async {
    final tid = await repo.insertTemplate('A');
    await repo.insertTemplateTask(
      WeekTemplateTasksCompanion.insert(templateId: tid, title: 'x'),
    );
    await repo.insertTemplateTask(
      WeekTemplateTasksCompanion.insert(
        templateId: tid,
        title: 'y',
        targetWeekday: const Value(2),
      ),
    );
    final d = await repo.getTemplateWithTasks(tid);
    expect(d.template.name, 'A');
    expect(d.tasks.map((e) => e.title).toList(), ['x', 'y']);
    expect(d.tasks.last.targetWeekday, 2);
  });

  test('updateTemplateTaskTargetWeekday moves task between pool and day', () async {
    final tid = await repo.insertTemplate('T');
    final taskId = await repo.insertTemplateTask(
      WeekTemplateTasksCompanion.insert(
        templateId: tid,
        title: 'mv',
        targetWeekday: const Value(3),
      ),
    );
    await repo.updateTemplateTaskTargetWeekday(taskId, null);
    var d = await repo.getTemplateWithTasks(tid);
    expect(d.tasks.single.targetWeekday, equals(null));
    await repo.updateTemplateTaskTargetWeekday(taskId, 5);
    d = await repo.getTemplateWithTasks(tid);
    expect(d.tasks.single.targetWeekday, 5);
  });

  test('updateTemplateTask edits title duration notes and day', () async {
    final tid = await repo.insertTemplate('T');
    final taskId = await repo.insertTemplateTask(
      WeekTemplateTasksCompanion.insert(
        templateId: tid,
        title: 'Eski',
        targetWeekday: const Value(2),
      ),
    );
    await repo.updateTemplateTask(
      taskId,
      title: 'Yeni',
      durationMinutes: 45,
      notes: 'not',
      targetWeekday: 4,
    );
    final d = await repo.getTemplateWithTasks(tid);
    final task = d.tasks.single;
    expect(task.title, 'Yeni');
    expect(task.durationMinutes, 45);
    expect(task.notes, 'not');
    expect(task.targetWeekday, 4);
  });

  test('deleteTemplate removes template and all its tasks', () async {
    final tid = await repo.insertTemplate('Del');
    await repo.insertTemplateTask(
      WeekTemplateTasksCompanion.insert(templateId: tid, title: 'a'),
    );
    await repo.insertTemplateTask(
      WeekTemplateTasksCompanion.insert(templateId: tid, title: 'b'),
    );
    await repo.deleteTemplate(tid);
    expect(await repo.getTemplates(), isEmpty);
    expect(
      () => repo.getTemplateWithTasks(tid),
      throwsA(isA<StateError>()),
    );
  });
}
