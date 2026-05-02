import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/date/week_calendar.dart';

import '../test_support.dart';

void main() {
  testWidgets('weekly plan search filters pool by title', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    final week = mondayIsoContaining(DateTime.now());
    final repo = TaskRepository(db);
    final now = DateTime.now().toUtc().toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'AlphaSearchUnique',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'BetaOtherUnique',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    expect(find.text('AlphaSearchUnique'), findsOneWidget);
    expect(find.text('BetaOtherUnique'), findsOneWidget);

    await tester.tap(find.byKey(const Key('weekly_plan_search')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('weekly_plan_search_field')),
      'AlphaSearch',
    );
    await tester.pumpAndSettle();

    expect(find.text('AlphaSearchUnique'), findsOneWidget);
    expect(find.text('BetaOtherUnique'), findsNothing);

    await tester.tap(find.byKey(const Key('weekly_plan_search_clear')));
    await tester.pumpAndSettle();

    expect(find.text('BetaOtherUnique'), findsOneWidget);
  });
}
