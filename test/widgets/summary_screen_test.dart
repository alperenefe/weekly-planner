import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/date/week_calendar.dart';

import '../test_support.dart';

void main() {
  testWidgets('Stat grid shows correct completedTasks count', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    final week = mondayIsoContaining(DateTime.now());
    final now = DateTime.now().toUtc().toIso8601String();
    final repo = TaskRepository(db);
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Done1',
        weekStart: week,
        plannedDate: Value(week),
        originalPlannedDate: Value(week),
        status: const Value('done'),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Done2',
        weekStart: week,
        plannedDate: Value(week),
        originalPlannedDate: Value(week),
        status: const Value('done'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_summary')));
    await tester.pumpAndSettle();

    final w = tester.widget<Text>(find.byKey(const Key('summary_stat_completed')));
    expect(w.data, '2');
  });

  testWidgets('Erteleme Analizi shows hiç görev ertelenmedi when no moves', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    final week = mondayIsoContaining(DateTime.now());
    final now = DateTime.now().toUtc().toIso8601String();
    final repo = TaskRepository(db);
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'Static',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_summary')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('summary_postpone_empty')), findsOneWidget);
    expect(find.textContaining('ertelenmedi'), findsOneWidget);
  });

  testWidgets('Aylık Hedefler shows Bu ay henüz hedef yok when empty', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });

    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_summary')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('summary_monthly_empty')), findsOneWidget);
  });

  testWidgets('Son 4 Hafta section renders 4 rows', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });

    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_summary')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('summary_week_trend_card')), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      expect(find.byKey(Key('summary_trend_row_$i')), findsOneWidget);
    }
  });
}
