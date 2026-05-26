import 'package:drift/drift.dart';

import '../../models/monthly_goal.dart';
import '../db/app_database.dart';
import 'monthly_goals_companion.dart';

class MonthlyGoalRepository {
  MonthlyGoalRepository(this._db);

  final AppDatabase _db;

  MonthlyGoal _fromRow(QueryRow r) {
    return MonthlyGoal(
      id: r.read<int>('id'),
      title: r.read<String>('title'),
      month: r.read<String>('month'),
      orderIndex: r.read<int>('order_index'),
      status: r.read<String>('status'),
      createdAt: r.read<String>('created_at'),
      updatedAt: r.read<String>('updated_at'),
      reminderEnabled: (r.read<int>('reminder_enabled')) != 0,
      reminderWeekday: r.readNullable<int>('reminder_weekday'),
      reminderMinutes: r.readNullable<int>('reminder_minutes'),
    );
  }

  Future<List<MonthlyGoal>> getGoalsForMonth(String month) async {
    final rows = await _db.customSelect(
      'SELECT id, title, month, order_index, status, created_at, updated_at, '
      'reminder_enabled, reminder_weekday, reminder_minutes '
      'FROM monthly_goals WHERE month = ? ORDER BY order_index ASC',
      variables: [Variable<String>(month)],
      readsFrom: const {},
    ).get();
    return rows.map(_fromRow).toList();
  }

  Future<List<int>> getGoalIdsWithReminderFlag() async {
    final rows = await _db.customSelect(
      'SELECT id FROM monthly_goals WHERE reminder_enabled = 1',
      readsFrom: const {},
    ).get();
    return rows.map((r) => r.read<int>('id')).toList();
  }

  Future<List<MonthlyGoal>> getGoalsWithActiveReminders() async {
    final rows = await _db.customSelect(
      'SELECT id, title, month, order_index, status, created_at, updated_at, '
      'reminder_enabled, reminder_weekday, reminder_minutes '
      'FROM monthly_goals WHERE reminder_enabled = 1 AND status = ?',
      variables: [Variable<String>('active')],
      readsFrom: const {},
    ).get();
    return rows.map(_fromRow).toList();
  }

  Future<int> insertGoal(MonthlyGoalsCompanion data) {
    return _db.transaction(() async {
      if (!data.month.present) {
        throw ArgumentError('month is required');
      }
      if (!data.title.present) {
        throw ArgumentError('title is required');
      }
      if (!data.createdAt.present) {
        throw ArgumentError('createdAt is required');
      }
      if (!data.updatedAt.present) {
        throw ArgumentError('updatedAt is required');
      }
      final month = data.month.value;
      final title = data.title.value;
      final createdAt = data.createdAt.value;
      final updatedAt = data.updatedAt.value;
      final row = await _db.customSelect(
        'SELECT COALESCE(MAX(order_index), 0) + 1 AS next_idx '
        'FROM monthly_goals WHERE month = ?',
        variables: [Variable<String>(month)],
        readsFrom: const {},
      ).getSingle();
      final nextIdx = row.read<int>('next_idx');
      final status = data.status.present ? data.status.value : 'active';
      final remOn = data.reminderEnabled.present && data.reminderEnabled.value
          ? 1
          : 0;
      final remWd =
          data.reminderWeekday.present ? data.reminderWeekday.value : null;
      final remMin =
          data.reminderMinutes.present ? data.reminderMinutes.value : null;
      await _db.customStatement(
        'INSERT INTO monthly_goals (title, month, order_index, status, '
        'created_at, updated_at, reminder_enabled, reminder_weekday, '
        'reminder_minutes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          title,
          month,
          nextIdx,
          status,
          createdAt,
          updatedAt,
          remOn,
          remWd,
          remMin,
        ],
      );
      final idRow = await _db.customSelect(
        'SELECT last_insert_rowid() AS id',
        readsFrom: const {},
      ).getSingle();
      return idRow.read<int>('id');
    });
  }

  Future<void> updateGoalReminder(
    int id, {
    required bool enabled,
    int? weekday,
    int? minutes,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now().toUtc().toIso8601String();
      await _db.customStatement(
        'UPDATE monthly_goals SET reminder_enabled = ?, reminder_weekday = ?, '
        'reminder_minutes = ?, updated_at = ? WHERE id = ?',
        [
          enabled ? 1 : 0,
          enabled ? weekday : null,
          enabled ? minutes : null,
          now,
          id,
        ],
      );
    });
  }

  Future<void> markGoalDone(int id) {
    return _db.transaction(() async {
      final now = DateTime.now().toUtc().toIso8601String();
      await _db.customStatement(
        'UPDATE monthly_goals SET status = ?, updated_at = ? WHERE id = ?',
        ['done', now, id],
      );
    });
  }

  Future<void> markGoalActive(int id) {
    return _db.transaction(() async {
      final now = DateTime.now().toUtc().toIso8601String();
      await _db.customStatement(
        'UPDATE monthly_goals SET status = ?, updated_at = ? WHERE id = ?',
        ['active', now, id],
      );
    });
  }

  Future<void> deleteGoal(int id) async {
    await _db.customStatement('DELETE FROM monthly_goals WHERE id = ?', [id]);
  }

  Future<MonthSummary> getMonthSummary(String month) async {
    final goals = await getGoalsForMonth(month);
    final done = goals.where((g) => g.status == 'done').length;
    return MonthSummary(totalGoals: goals.length, doneGoals: done);
  }
}
