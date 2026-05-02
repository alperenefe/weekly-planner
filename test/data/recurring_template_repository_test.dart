import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/recurring_template_repository.dart';

void main() {
  late AppDatabase db;
  late RecurringTemplateRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = RecurringTemplateRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insertTemplate and getActiveTemplates', () async {
    final now = DateTime.utc(2025, 1, 1, 8).toIso8601String();
    final id = await repo.insertTemplate(
      RecurringTemplatesCompanion.insert(
        title: 'Weekly review',
        durationMinutes: const Value(45),
        notes: const Value.absent(),
        targetWeekday: const Value(3),
        createdAt: now,
      ),
    );
    expect(id, greaterThan(0));

    final active = await repo.getActiveTemplates();
    expect(active.length, 1);
    expect(active.single.title, 'Weekly review');
    expect(active.single.targetWeekday, 3);
    expect(active.single.isActive, 1);
  });

  test('deactivateTemplate hides from getActiveTemplates', () async {
    final now = DateTime.utc(2025, 1, 2, 8).toIso8601String();
    final id = await repo.insertTemplate(
      RecurringTemplatesCompanion.insert(
        title: 'X',
        createdAt: now,
      ),
    );
    await repo.deactivateTemplate(id);
    final active = await repo.getActiveTemplates();
    expect(active, isEmpty);
  });
}
