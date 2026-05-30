import 'package:drift/drift.dart';

import '../../date/periodic_reminder_dates.dart';
import '../../models/periodic_reminder.dart';
import '../db/app_database.dart';
import 'periodic_reminder_companion.dart';

class PeriodicReminderRepository {
  PeriodicReminderRepository(this._db);

  final AppDatabase _db;

  PeriodicReminder _fromRow(QueryRow r) {
    return PeriodicReminder(
      id: r.read<int>('id'),
      title: r.read<String>('title'),
      intervalDays: r.read<int>('interval_days'),
      nextDueDate: r.read<String>('next_due_date'),
      orderIndex: r.read<int>('order_index'),
      createdAt: r.read<String>('created_at'),
      updatedAt: r.read<String>('updated_at'),
      lastCompletedAt: r.readNullable<String>('last_completed_at'),
    );
  }

  Future<List<PeriodicReminder>> getAllSortedByDueDate() async {
    final rows = await _db.customSelect(
      'SELECT id, title, interval_days, next_due_date, order_index, '
      'created_at, updated_at, last_completed_at '
      'FROM periodic_reminders ORDER BY next_due_date ASC, order_index ASC',
      readsFrom: const {},
    ).get();
    return rows.map(_fromRow).toList();
  }

  Future<int> insertReminder(PeriodicReminderCompanion data) {
    return _db.transaction(() async {
      if (!data.title.present) throw ArgumentError('title is required');
      if (!data.intervalDays.present) {
        throw ArgumentError('intervalDays is required');
      }
      if (!data.nextDueDate.present) {
        throw ArgumentError('nextDueDate is required');
      }
      if (!data.createdAt.present) {
        throw ArgumentError('createdAt is required');
      }
      if (!data.updatedAt.present) {
        throw ArgumentError('updatedAt is required');
      }

      final row = await _db.customSelect(
        'SELECT COALESCE(MAX(order_index), 0) + 1 AS next_idx '
        'FROM periodic_reminders',
        readsFrom: const {},
      ).getSingle();
      final nextIdx = row.read<int>('next_idx');

      await _db.customStatement(
        'INSERT INTO periodic_reminders (title, interval_days, next_due_date, '
        'order_index, created_at, updated_at, last_completed_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          data.title.value,
          data.intervalDays.value,
          data.nextDueDate.value,
          nextIdx,
          data.createdAt.value,
          data.updatedAt.value,
          null,
        ],
      );
      final idRow = await _db.customSelect(
        'SELECT last_insert_rowid() AS id',
        readsFrom: const {},
      ).getSingle();
      return idRow.read<int>('id');
    });
  }

  Future<void> updateReminder(
    int id, {
    required String title,
    required int intervalDays,
    required String nextDueDate,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now().toUtc().toIso8601String();
      await _db.customStatement(
        'UPDATE periodic_reminders SET title = ?, interval_days = ?, '
        'next_due_date = ?, updated_at = ? WHERE id = ?',
        [title, intervalDays, nextDueDate, now, id],
      );
    });
  }

  Future<void> markCompleted(int id) {
    return _db.transaction(() async {
      final rows = await _db.customSelect(
        'SELECT interval_days FROM periodic_reminders WHERE id = ?',
        variables: [Variable<int>(id)],
        readsFrom: const {},
      ).get();
      if (rows.isEmpty) {
        throw StateError('periodic reminder not found: $id');
      }
      final intervalDays = rows.single.read<int>('interval_days');
      final now = DateTime.now().toUtc().toIso8601String();
      final nextDue = nextDueAfterInterval(intervalDays);
      await _db.customStatement(
        'UPDATE periodic_reminders SET next_due_date = ?, last_completed_at = ?, '
        'updated_at = ? WHERE id = ?',
        [nextDue, now, now, id],
      );
    });
  }

  Future<void> deleteReminder(int id) async {
    await _db.customStatement(
      'DELETE FROM periodic_reminders WHERE id = ?',
      [id],
    );
  }
}
