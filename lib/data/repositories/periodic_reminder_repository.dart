import 'package:drift/drift.dart';

import '../../date/periodic_reminder_dates.dart';
import '../../models/periodic_reminder.dart';
import '../../models/periodic_reminder_completion.dart';
import '../db/app_database.dart';
import 'periodic_reminder_companion.dart';

class PeriodicReminderRepository {
  PeriodicReminderRepository(this._db);

  final AppDatabase _db;

  PeriodicReminder _reminderFromRow(QueryRow r) {
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

  PeriodicReminderCompletion _completionFromRow(QueryRow r) {
    return PeriodicReminderCompletion(
      id: r.read<int>('id'),
      reminderId: r.read<int>('reminder_id'),
      completedAt: r.read<String>('completed_at'),
      previousNextDueDate: r.readNullable<String>('previous_next_due_date'),
    );
  }

  Future<List<PeriodicReminder>> getAllSortedByDueDate() async {
    final rows = await _db.customSelect(
      'SELECT id, title, interval_days, next_due_date, order_index, '
      'created_at, updated_at, last_completed_at '
      'FROM periodic_reminders ORDER BY next_due_date ASC, order_index ASC',
      readsFrom: const {},
    ).get();
    return rows.map(_reminderFromRow).toList();
  }

  Future<PeriodicReminder?> getReminderById(int id) async {
    final rows = await _db.customSelect(
      'SELECT id, title, interval_days, next_due_date, order_index, '
      'created_at, updated_at, last_completed_at '
      'FROM periodic_reminders WHERE id = ?',
      variables: [Variable<int>(id)],
      readsFrom: const {},
    ).get();
    if (rows.isEmpty) return null;
    return _reminderFromRow(rows.single);
  }

  Future<List<PeriodicReminderCompletion>> getCompletionsForReminder(
    int reminderId, {
    int limit = 50,
  }) async {
    final rows = await _db.customSelect(
      'SELECT id, reminder_id, completed_at, previous_next_due_date '
      'FROM periodic_reminder_completions '
      'WHERE reminder_id = ? '
      'ORDER BY completed_at DESC '
      'LIMIT ?',
      variables: [Variable<int>(reminderId), Variable<int>(limit)],
      readsFrom: const {},
    ).get();
    return rows.map(_completionFromRow).toList();
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
        'SELECT interval_days, next_due_date FROM periodic_reminders WHERE id = ?',
        variables: [Variable<int>(id)],
        readsFrom: const {},
      ).get();
      if (rows.isEmpty) {
        throw StateError('periodic reminder not found: $id');
      }
      final row = rows.single;
      final intervalDays = row.read<int>('interval_days');
      final previousNextDue = row.read<String>('next_due_date');
      final now = DateTime.now().toUtc().toIso8601String();
      final nextDue = nextDueAfterInterval(intervalDays);

      await _db.customStatement(
        'INSERT INTO periodic_reminder_completions '
        '(reminder_id, completed_at, previous_next_due_date) '
        'VALUES (?, ?, ?)',
        [id, now, previousNextDue],
      );
      await _db.customStatement(
        'UPDATE periodic_reminders SET next_due_date = ?, last_completed_at = ?, '
        'updated_at = ? WHERE id = ?',
        [nextDue, now, now, id],
      );
    });
  }

  /// Son «Yaptım» kaydını geri alır; önceki son tarih ve sıradaki gün yeniden hesaplanır.
  Future<bool> undoLastCompletion(int reminderId) {
    return _db.transaction(() async {
      final latest = await _db.customSelect(
        'SELECT id, completed_at, previous_next_due_date '
        'FROM periodic_reminder_completions '
        'WHERE reminder_id = ? '
        'ORDER BY completed_at DESC LIMIT 1',
        variables: [Variable<int>(reminderId)],
        readsFrom: const {},
      ).get();
      if (latest.isEmpty) return false;

      final completionId = latest.single.read<int>('id');
      final previousNextDue =
          latest.single.readNullable<String>('previous_next_due_date');

      await _db.customStatement(
        'DELETE FROM periodic_reminder_completions WHERE id = ?',
        [completionId],
      );

      final remaining = await getCompletionsForReminder(reminderId, limit: 1);
      final now = DateTime.now().toUtc().toIso8601String();

      if (remaining.isEmpty) {
        await _db.customStatement(
          'UPDATE periodic_reminders SET last_completed_at = NULL, '
          'next_due_date = ?, updated_at = ? WHERE id = ?',
          [
            previousNextDue ?? todayIsoDate(),
            now,
            reminderId,
          ],
        );
        return true;
      }

      final last = remaining.first;
      final intervalRow = await _db.customSelect(
        'SELECT interval_days FROM periodic_reminders WHERE id = ?',
        variables: [Variable<int>(reminderId)],
        readsFrom: const {},
      ).getSingle();
      final intervalDays = intervalRow.read<int>('interval_days');
      final completedLocal = parseCompletedAtLocal(last.completedAt);
      final nextDue = completedLocal != null
          ? nextDueAfterInterval(
              intervalDays,
              reference: completedLocal,
            )
          : nextDueAfterInterval(intervalDays);

      await _db.customStatement(
        'UPDATE periodic_reminders SET last_completed_at = ?, '
        'next_due_date = ?, updated_at = ? WHERE id = ?',
        [last.completedAt, nextDue, now, reminderId],
      );
      return true;
    });
  }

  Future<void> deleteCompletion(int completionId) async {
    final rows = await _db.customSelect(
      'SELECT reminder_id FROM periodic_reminder_completions WHERE id = ?',
      variables: [Variable<int>(completionId)],
      readsFrom: const {},
    ).get();
    if (rows.isEmpty) return;
    final reminderId = rows.single.read<int>('reminder_id');
    await _db.customStatement(
      'DELETE FROM periodic_reminder_completions WHERE id = ?',
      [completionId],
    );
    await _reconcileReminderAfterHistoryChange(reminderId);
  }

  Future<void> _reconcileReminderAfterHistoryChange(int reminderId) async {
    final remaining = await getCompletionsForReminder(reminderId, limit: 1);
    final now = DateTime.now().toUtc().toIso8601String();
    if (remaining.isEmpty) {
      final reminder = await getReminderById(reminderId);
      await _db.customStatement(
        'UPDATE periodic_reminders SET last_completed_at = NULL, updated_at = ? '
        'WHERE id = ?',
        [now, reminderId],
      );
      return;
    }

    final last = remaining.first;
    final intervalRow = await _db.customSelect(
      'SELECT interval_days FROM periodic_reminders WHERE id = ?',
      variables: [Variable<int>(reminderId)],
      readsFrom: const {},
    ).getSingle();
    final intervalDays = intervalRow.read<int>('interval_days');
    final completedLocal = parseCompletedAtLocal(last.completedAt);
    final nextDue = completedLocal != null
        ? nextDueAfterInterval(intervalDays, reference: completedLocal)
        : nextDueAfterInterval(intervalDays);

    await _db.customStatement(
      'UPDATE periodic_reminders SET last_completed_at = ?, next_due_date = ?, '
      'updated_at = ? WHERE id = ?',
      [last.completedAt, nextDue, now, reminderId],
    );
  }

  Future<void> deleteReminder(int id) async {
    await _db.customStatement(
      'DELETE FROM periodic_reminders WHERE id = ?',
      [id],
    );
  }
}
