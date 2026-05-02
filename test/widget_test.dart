import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';

import 'package:weekly_planner/config/planner_feature_flags.dart';

import 'test_support.dart';

void main() {
  testWidgets('WeeklyPlannerApp shows plan tab and FAB', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weekly_plan_screen')), findsOneWidget);
    expect(find.byKey(const Key('fab_add_task')), findsOneWidget);
    expect(find.byKey(const Key('copy_last_week')), findsOneWidget);
  });

  testWidgets('copy last week hidden when feature disabled', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(
      plannerAppWithDb(
        db,
        featureFlags: const PlannerFeatureFlags(
          copyLastWeekEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('copy_last_week')), findsNothing);
  });

  testWidgets('bottom nav switches branch', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_summary')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('summary_screen')), findsOneWidget);
    expect(find.byKey(const Key('fab_add_task')), findsNothing);

    await tester.tap(find.byKey(const Key('nav_plan')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weekly_plan_screen')), findsOneWidget);
    expect(find.byKey(const Key('fab_add_task')), findsOneWidget);
  });
}
