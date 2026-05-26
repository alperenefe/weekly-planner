import 'package:drift/drift.dart';

import '../../date/week_calendar.dart';
import '../db/app_database.dart';

class MoveTaskOutcome {
  const MoveTaskOutcome({
    required this.didChange,
    required this.movedCountAfter,
    required this.scheduledFromPool,
  });

  final bool didChange;
  final int movedCountAfter;
  final bool scheduledFromPool;
}

int compareTasksPlannedDayOrder(Task a, Task b) {
  final am = a.startMinutes;
  final bm = b.startMinutes;
  if (am != null && bm != null) {
    final c = am.compareTo(bm);
    if (c != 0) return c;
  } else if (am != null && bm == null) {
    return -1;
  } else if (am == null && bm != null) {
    return 1;
  }
  return a.createdAt.compareTo(b.createdAt);
}

class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  Future<List<Task>> getTasksForWeek(String weekStart) {
    return (_db.select(_db.tasks)
          ..where((t) => t.weekStart.equals(weekStart))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<Task>> getPoolTasks(String weekStart) {
    return (_db.select(_db.tasks)
          ..where((t) => t.weekStart.equals(weekStart) & t.plannedDate.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// `week_start` bu hafta ama `planned_date` bu haftanın günlerinde değil (görünmez kalmasın diye havuzda gösterilir).
  Future<List<Task>> getTasksWithActiveReminders() {
    return (_db.select(_db.tasks)
          ..where(
            (t) =>
                t.reminderEnabled.equals(1) & t.status.equals('planned'),
          ))
        .get();
  }

  Future<List<int>> getTaskIdsWithReminderFlag() async {
    final rows = await (_db.select(_db.tasks)
          ..where((t) => t.reminderEnabled.equals(1)))
        .get();
    return rows.map((t) => t.id).toList();
  }

  Future<List<Task>> getOrphanPlannedTasks(String weekStart) async {
    final allowed = weekdayIsosFromMonday(weekStart).toSet();
    final rows = await (_db.select(_db.tasks)
          ..where(
            (t) => t.weekStart.equals(weekStart) & t.plannedDate.isNotNull(),
          ))
        .get();
    final orphans =
        rows.where((t) => !allowed.contains(t.plannedDate)).toList();
    orphans.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return orphans;
  }

  Future<List<Task>> getDayTasks(String weekStart, String date) async {
    final rows = await (_db.select(_db.tasks)
          ..where((t) => t.weekStart.equals(weekStart) & t.plannedDate.equals(date)))
        .get();
    rows.sort(compareTasksPlannedDayOrder);
    return rows;
  }

  Future<bool> hasTaskForRecurrenceInWeek(int recurrenceTemplateId, String weekStart) async {
    final rows = await (_db.select(_db.tasks)
          ..where(
            (t) =>
                t.recurrenceTemplateId.equals(recurrenceTemplateId) &
                t.weekStart.equals(weekStart),
          ))
        .get();
    return rows.isNotEmpty;
  }

  Future<int> insertTask(TasksCompanion data) {
    return _db.transaction(() async => _insertTaskWithHistory(data));
  }

  Future<int> _insertTaskWithHistory(TasksCompanion data) async {
    final id = await _db.into(_db.tasks).insert(data);
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.into(_db.taskHistories).insert(
          TaskHistoriesCompanion.insert(
            taskId: id,
            eventType: 'created',
            timestamp: now,
          ),
        );
    return id;
  }

  Future<bool> isCopyFromPreviousApplied(String weekStart) async {
    final row = await (_db.select(_db.weekMetas)
          ..where((m) => m.weekStart.equals(weekStart)))
        .getSingleOrNull();
    return row?.copyFromPreviousApplied == 1;
  }

  Future<void> copyLastWeekTasks(String weekStart) async {
    await _db.transaction(() async {
      final meta = await (_db.select(_db.weekMetas)
            ..where((m) => m.weekStart.equals(weekStart)))
          .getSingleOrNull();
      if (meta != null && meta.copyFromPreviousApplied == 1) {
        return;
      }

      final prevWeekStart = addDaysIso(weekStart, -7);
      final prevTasks = await (_db.select(_db.tasks)
            ..where(
              (t) =>
                  t.weekStart.equals(prevWeekStart) & t.plannedDate.isNotNull(),
            ))
          .get();

      if (prevTasks.isEmpty) {
        return;
      }

      final now = DateTime.now().toUtc().toIso8601String();
      for (final t in prevTasks) {
        final oldPlanned = t.plannedDate!;
        final newPlanned =
            mapPlannedDateToNewWeek(oldPlanned, prevWeekStart, weekStart);
        await _insertTaskWithHistory(
          TasksCompanion.insert(
            title: t.title,
            durationMinutes: t.durationMinutes == null
                ? const Value.absent()
                : Value(t.durationMinutes),
            startMinutes: t.startMinutes == null
                ? const Value.absent()
                : Value(t.startMinutes),
            notes: t.notes == null ? const Value.absent() : Value(t.notes),
            status: const Value('planned'),
            weekStart: weekStart,
            plannedDate: Value(newPlanned),
            originalPlannedDate: Value(newPlanned),
            movedCount: const Value(0),
            recurrenceTemplateId: t.recurrenceTemplateId == null
                ? const Value.absent()
                : Value(t.recurrenceTemplateId),
            accentColor: t.accentColor == null
                ? const Value.absent()
                : Value(t.accentColor),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await _db.into(_db.weekMetas).insert(
            WeekMetasCompanion.insert(
              weekStart: weekStart,
              copyFromPreviousApplied: const Value(1),
            ),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  Future<List<TaskHistory>> getTaskHistoriesForTask(int taskId) {
    return (_db.select(_db.taskHistories)
          ..where((h) => h.taskId.equals(taskId))
          ..orderBy([(h) => OrderingTerm.asc(h.timestamp)]))
        .get();
  }

  Future<List<String>> getPastWeeks(String currentWeekStart) async {
    final rows = await _db.customSelect(
      'SELECT DISTINCT week_start AS w FROM tasks WHERE week_start < ? ORDER BY week_start DESC',
      variables: [Variable<String>(currentWeekStart)],
      readsFrom: {_db.tasks},
    ).get();
    return rows.map((r) => r.read<String>('w')).toList();
  }

  Future<Task?> getTaskById(int id) {
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateTask(Task task) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(task.id)))
        .write(task.toCompanion(false));
  }

  Future<int> shiftPlannedDayTasksAfterAnchor({
    required String weekStart,
    required String plannedDateIso,
    required int anchorStartMinutes,
    required int breakMinutes,
  }) async {
    if (breakMinutes <= 0) return 0;
    return _db.transaction(() async {
      final rows = await getDayTasks(weekStart, plannedDateIso);
      final now = DateTime.now().toUtc().toIso8601String();
      var count = 0;
      for (final t in rows) {
        final sm = t.startMinutes;
        if (sm == null || sm < anchorStartMinutes) continue;
        final newSm = (sm + breakMinutes).clamp(0, 1439);
        await (_db.update(_db.tasks)..where((r) => r.id.equals(t.id))).write(
              TasksCompanion(
                startMinutes: Value(newSm),
                updatedAt: Value(now),
              ),
            );
        count++;
      }
      return count;
    });
  }

  Future<MoveTaskOutcome> moveTask(int taskId, String? newPlannedDate) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.tasks)..where((t) => t.id.equals(taskId)))
          .getSingleOrNull();
      if (row == null) {
        throw StateError('task not found: $taskId');
      }
      final fromDate = row.plannedDate;
      if (fromDate == newPlannedDate) {
        return MoveTaskOutcome(
          didChange: false,
          movedCountAfter: row.movedCount,
          scheduledFromPool: false,
        );
      }
      final now = DateTime.now().toUtc().toIso8601String();
      final newCount = row.movedCount + 1;
      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
            TasksCompanion(
              plannedDate: newPlannedDate == null
                  ? const Value(null)
                  : Value(newPlannedDate),
              movedCount: Value(newCount),
              updatedAt: Value(now),
            ),
          );
      await _db.into(_db.taskHistories).insert(
            TaskHistoriesCompanion.insert(
              taskId: taskId,
              eventType: 'moved',
              fromDate: Value(fromDate),
              toDate: Value(newPlannedDate),
              timestamp: now,
            ),
          );
      return MoveTaskOutcome(
        didChange: true,
        movedCountAfter: newCount,
        scheduledFromPool: fromDate == null && newPlannedDate != null,
      );
    });
  }

  Future<void> markDone(int taskId) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.tasks)..where((t) => t.id.equals(taskId)))
          .getSingleOrNull();
      if (row == null) {
        throw StateError('task not found: $taskId');
      }
      if (row.status != 'planned') {
        return;
      }
      final now = DateTime.now().toUtc().toIso8601String();
      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
            TasksCompanion(
              status: const Value('done'),
              completedAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await _db.into(_db.taskHistories).insert(
            TaskHistoriesCompanion.insert(
              taskId: taskId,
              eventType: 'completed',
              timestamp: now,
            ),
          );
    });
  }

  Future<int> insertTasksInTransaction(List<TasksCompanion> items) {
    return _db.transaction(() async {
      var n = 0;
      for (final c in items) {
        await _insertTaskWithHistory(c);
        n++;
      }
      return n;
    });
  }

  Future<List<Task>> getMostMovedTasks(String weekStart, {int limit = 5}) {
    return (_db.select(_db.tasks)
          ..where(
            (t) =>
                t.weekStart.equals(weekStart) &
                t.movedCount.isBiggerThanValue(0),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.movedCount),
            (t) => OrderingTerm.asc(t.title),
          ])
          ..limit(limit))
        .get();
  }

  Future<void> resetAllData() {
    return _db.transaction(() async {
      await _db.delete(_db.taskHistories).go();
      await _db.delete(_db.tasks).go();
      await _db.delete(_db.weekMetas).go();
      await _db.delete(_db.recurringTemplates).go();
      await _db.customStatement('DELETE FROM monthly_goals');
      await _db.customStatement('DELETE FROM week_template_tasks');
      await _db.customStatement('DELETE FROM week_templates');
    });
  }

  Future<void> markSkipped(int taskId) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.tasks)..where((t) => t.id.equals(taskId)))
          .getSingleOrNull();
      if (row == null) {
        throw StateError('task not found: $taskId');
      }
      if (row.status != 'planned') {
        return;
      }
      final now = DateTime.now().toUtc().toIso8601String();
      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
            TasksCompanion(
              status: const Value('skipped'),
              updatedAt: Value(now),
            ),
          );
      await _db.into(_db.taskHistories).insert(
            TaskHistoriesCompanion.insert(
              taskId: taskId,
              eventType: 'skipped',
              timestamp: now,
            ),
          );
    });
  }

  Future<void> unmarkSkipped(int taskId) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.tasks)..where((t) => t.id.equals(taskId)))
          .getSingleOrNull();
      if (row == null) {
        throw StateError('task not found: $taskId');
      }
      if (row.status != 'skipped') {
        return;
      }
      final now = DateTime.now().toUtc().toIso8601String();
      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
            TasksCompanion(
              status: const Value('planned'),
              updatedAt: Value(now),
            ),
          );
      await _db.into(_db.taskHistories).insert(
            TaskHistoriesCompanion.insert(
              taskId: taskId,
              eventType: 'reopened',
              timestamp: now,
            ),
          );
    });
  }

  Future<void> unmarkDone(int taskId) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.tasks)..where((t) => t.id.equals(taskId)))
          .getSingleOrNull();
      if (row == null) {
        throw StateError('task not found: $taskId');
      }
      if (row.status != 'done') {
        return;
      }
      final now = DateTime.now().toUtc().toIso8601String();
      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
            TasksCompanion(
              status: const Value('planned'),
              completedAt: const Value(null),
              updatedAt: Value(now),
            ),
          );
      await _db.into(_db.taskHistories).insert(
            TaskHistoriesCompanion.insert(
              taskId: taskId,
              eventType: 'reopened',
              timestamp: now,
            ),
          );
    });
  }

  Future<void> deleteTask(int taskId) {
    return _db.transaction(() async {
      await (_db.delete(_db.taskHistories)
            ..where((h) => h.taskId.equals(taskId)))
          .go();
      await (_db.delete(_db.tasks)..where((t) => t.id.equals(taskId))).go();
    });
  }
}
