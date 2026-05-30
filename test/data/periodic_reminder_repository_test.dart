import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/periodic_reminder_companion.dart';
import 'package:weekly_planner/data/repositories/periodic_reminder_repository.dart';
import 'package:weekly_planner/date/periodic_reminder_dates.dart';

void main() {
  group('PeriodicReminderRepository', () {
    late AppDatabase db;
    late PeriodicReminderRepository repo;

    setUp(() {
      db = AppDatabase.memory();
      repo = PeriodicReminderRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('insert and list sorted by due date', () async {
      final now = DateTime.now().toUtc().toIso8601String();
      await repo.insertReminder(
        PeriodicReminderCompanion.insert(
          title: 'Perde yıka',
          intervalDays: 180,
          nextDueDate: '2026-12-01',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.insertReminder(
        PeriodicReminderCompanion.insert(
          title: 'Havlular',
          intervalDays: 14,
          nextDueDate: '2026-06-01',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final items = await repo.getAllSortedByDueDate();
      expect(items.map((e) => e.title).toList(), ['Havlular', 'Perde yıka']);
    });

    test('markCompleted resets next due by interval', () async {
      final ref = DateTime(2026, 5, 30);
      final now = ref.toUtc().toIso8601String();
      final id = await repo.insertReminder(
        PeriodicReminderCompanion.insert(
          title: 'Havlular',
          intervalDays: 14,
          nextDueDate: '2026-05-30',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.markCompleted(id);
      final item = (await repo.getAllSortedByDueDate()).single;
      expect(item.nextDueDate, nextDueAfterInterval(14, reference: ref));
      expect(item.lastCompletedAt, isNotNull);
      final history = await repo.getCompletionsForReminder(id);
      expect(history, hasLength(1));
      expect(history.single.previousNextDueDate, '2026-05-30');
    });

    test('undoLastCompletion restores previous next due', () async {
      final now = DateTime.now().toUtc().toIso8601String();
      final id = await repo.insertReminder(
        PeriodicReminderCompanion.insert(
          title: 'Havlular',
          intervalDays: 14,
          nextDueDate: '2026-08-01',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.markCompleted(id);
      final undone = await repo.undoLastCompletion(id);
      expect(undone, isTrue);
      final item = (await repo.getAllSortedByDueDate()).single;
      expect(item.nextDueDate, '2026-08-01');
      expect(item.lastCompletedAt, isNull);
      expect(await repo.getCompletionsForReminder(id), isEmpty);
    });

    test('deleteReminder removes row', () async {
      final now = DateTime.now().toUtc().toIso8601String();
      final id = await repo.insertReminder(
        PeriodicReminderCompanion.insert(
          title: 'Test',
          intervalDays: 7,
          nextDueDate: nextDueAfterInterval(7),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.deleteReminder(id);
      expect(await repo.getAllSortedByDueDate(), isEmpty);
    });
  });
}
