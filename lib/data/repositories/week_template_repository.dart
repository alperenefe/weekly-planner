import 'package:drift/drift.dart';

import '../../models/week_template.dart';
import '../db/app_database.dart';
import 'week_template_tasks_companion.dart';

class WeekTemplateRepository {
  WeekTemplateRepository(this._db);

  final AppDatabase _db;

  WeekTemplate _templateFromRow(QueryRow r) {
    return WeekTemplate(
      id: r.read<int>('id'),
      name: r.read<String>('name'),
      createdAt: r.read<String>('created_at'),
      taskCount: r.read<int>('task_count'),
    );
  }

  WeekTemplateTask _taskFromRow(QueryRow r) {
    return WeekTemplateTask(
      id: r.read<int>('id'),
      templateId: r.read<int>('template_id'),
      title: r.read<String>('title'),
      durationMinutes: r.data['duration_minutes'] as int?,
      notes: r.data['notes'] as String?,
      targetWeekday: r.data['target_weekday'] as int?,
      orderIndex: r.read<int>('order_index'),
    );
  }

  Future<List<WeekTemplate>> getTemplates() async {
    final rows = await _db.customSelect(
      'SELECT w.id, w.name, w.created_at, '
      '(SELECT COUNT(*) FROM week_template_tasks t WHERE t.template_id = w.id) AS task_count '
      'FROM week_templates w ORDER BY w.created_at DESC',
      readsFrom: const {},
    ).get();
    return rows.map(_templateFromRow).toList();
  }

  Future<WeekTemplateDetail> getTemplateWithTasks(int templateId) async {
    final templates = await _db.customSelect(
      'SELECT id, name, created_at FROM week_templates WHERE id = ?',
      variables: [Variable<int>(templateId)],
      readsFrom: const {},
    ).get();
    if (templates.isEmpty) {
      throw StateError('week template not found: $templateId');
    }
    final tr = templates.single;
    final cnt = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM week_template_tasks WHERE template_id = ?',
      variables: [Variable<int>(templateId)],
      readsFrom: const {},
    ).getSingle();
    final template = WeekTemplate(
      id: tr.read<int>('id'),
      name: tr.read<String>('name'),
      createdAt: tr.read<String>('created_at'),
      taskCount: cnt.read<int>('c'),
    );
    final tasks = await _db.customSelect(
      'SELECT id, template_id, title, duration_minutes, notes, target_weekday, order_index '
      'FROM week_template_tasks WHERE template_id = ? ORDER BY order_index ASC',
      variables: [Variable<int>(templateId)],
      readsFrom: const {},
    ).get();
    return WeekTemplateDetail(
      template: template,
      tasks: tasks.map(_taskFromRow).toList(),
    );
  }

  Future<int> insertTemplate(String name) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.customStatement(
      'INSERT INTO week_templates (name, created_at) VALUES (?, ?)',
      [name, now],
    );
    final idRow = await _db.customSelect(
      'SELECT last_insert_rowid() AS id',
      readsFrom: const {},
    ).getSingle();
    return idRow.read<int>('id');
  }

  Future<int> insertTemplateTask(WeekTemplateTasksCompanion data) {
    return _db.transaction(() async {
      if (!data.templateId.present) {
        throw ArgumentError('templateId is required');
      }
      if (!data.title.present) {
        throw ArgumentError('title is required');
      }
      final templateId = data.templateId.value;
      final title = data.title.value;
      int nextIdx;
      if (data.orderIndex.present) {
        nextIdx = data.orderIndex.value;
      } else {
        final row = await _db.customSelect(
          'SELECT COALESCE(MAX(order_index), 0) + 1 AS next_idx '
          'FROM week_template_tasks WHERE template_id = ?',
          variables: [Variable<int>(templateId)],
          readsFrom: const {},
        ).getSingle();
        nextIdx = row.read<int>('next_idx');
      }
      final dur = data.durationMinutes.present ? data.durationMinutes.value : null;
      final notes = data.notes.present ? data.notes.value : null;
      final tw = data.targetWeekday.present ? data.targetWeekday.value : null;
      await _db.customStatement(
        'INSERT INTO week_template_tasks '
        '(template_id, title, duration_minutes, notes, target_weekday, order_index) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [templateId, title, dur, notes, tw, nextIdx],
      );
      final idRow = await _db.customSelect(
        'SELECT last_insert_rowid() AS id',
        readsFrom: const {},
      ).getSingle();
      return idRow.read<int>('id');
    });
  }

  Future<void> deleteTemplate(int id) async {
    await _db.transaction(() async {
      await _db.customStatement(
        'DELETE FROM week_template_tasks WHERE template_id = ?',
        [id],
      );
      await _db.customStatement(
        'DELETE FROM week_templates WHERE id = ?',
        [id],
      );
    });
  }

  Future<void> deleteTemplateTask(int taskRowId) async {
    await _db.customStatement(
      'DELETE FROM week_template_tasks WHERE id = ?',
      [taskRowId],
    );
  }

  Future<void> updateTemplateName(int id, String name) async {
    await _db.customStatement(
      'UPDATE week_templates SET name = ? WHERE id = ?',
      [name, id],
    );
  }

  Future<void> updateTemplateTaskTargetWeekday(int taskId, int? targetWeekday) async {
    if (targetWeekday == null) {
      await _db.customStatement(
        'UPDATE week_template_tasks SET target_weekday = NULL WHERE id = ?',
        [taskId],
      );
    } else {
      await _db.customStatement(
        'UPDATE week_template_tasks SET target_weekday = ? WHERE id = ?',
        [targetWeekday, taskId],
      );
    }
  }
}
