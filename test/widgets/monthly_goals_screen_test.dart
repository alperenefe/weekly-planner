import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/monthly_goal_repository.dart';
import 'package:weekly_planner/date/turkish_date.dart';

import '../test_support.dart';

void main() {
  testWidgets('empty month shows hint', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_goals')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('monthly_goals_empty_hint')), findsOneWidget);
    expect(find.text('Bu ay henüz hedef yok'), findsWidgets);
  });

  testWidgets('adding a goal shows it numbered in the list', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_goals')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('monthly_goals_fab')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('monthly_goals_new_title')),
      'İlk hedef',
    );
    await tester.tap(find.byKey(const Key('monthly_goals_new_submit')));
    await tester.pumpAndSettle();

    expect(find.text('İlk hedef'), findsOneWidget);
    final repo = MonthlyGoalRepository(db);
    final id = (await repo.getGoalsForMonth(yyyyMmFromDate(DateTime.now()))).single.id;
    expect(find.byKey(Key('monthly_goals_order_$id')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(Key('monthly_goals_order_$id'))).data,
      '1',
    );
  });

  testWidgets('done toggle marks goal done strikethrough', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_goals')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('monthly_goals_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('monthly_goals_new_title')),
      'ToggleMe',
    );
    await tester.tap(find.byKey(const Key('monthly_goals_new_submit')));
    await tester.pumpAndSettle();

    final repo = MonthlyGoalRepository(db);
    final id = (await repo.getGoalsForMonth(yyyyMmFromDate(DateTime.now()))).single.id;
    final titleKey = Key('monthly_goals_title_$id');
    final textBefore = tester.widget<Text>(find.byKey(titleKey));
    expect(textBefore.style?.decoration, isNot(TextDecoration.lineThrough));

    await tester.tap(find.byKey(Key('monthly_goals_done_$id')));
    await tester.pumpAndSettle();

    final textAfter = tester.widget<Text>(find.byKey(titleKey));
    expect(textAfter.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('Haftaya Ekle sheet opens on calendar icon tap', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_goals')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('monthly_goals_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('monthly_goals_new_title')),
      'SheetGoal',
    );
    await tester.tap(find.byKey(const Key('monthly_goals_new_submit')));
    await tester.pumpAndSettle();

    final repo = MonthlyGoalRepository(db);
    final id = (await repo.getGoalsForMonth(yyyyMmFromDate(DateTime.now()))).single.id;
    await tester.tap(find.byKey(Key('monthly_goals_add_week_$id')));
    await tester.pumpAndSettle();

    expect(find.text('Haftaya Ekle'), findsOneWidget);
    expect(find.byKey(const Key('monthly_goals_add_to_week_sheet')), findsOneWidget);
  });
}
