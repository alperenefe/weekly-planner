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
    );
  }

  Future<List<MonthlyGoal>> getGoalsForMonth(String month) async {
    final rows = await _db.customSelect(
      'SELECT id, title, month, order_index, status, created_at, updated_at '
      'FROM monthly_goals WHERE month = ? ORDER BY order_index ASC',
      variables: [Variable<String>(month)],
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
      await _db.customStatement(
        'INSERT INTO monthly_goals (title, month, order_index, status, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [title, month, nextIdx, status, createdAt, updatedAt],
      );
      final idRow = await _db.customSelect(
        'SELECT last_insert_rowid() AS id',
        readsFrom: const {},
      ).getSingle();
      return idRow.read<int>('id');
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
