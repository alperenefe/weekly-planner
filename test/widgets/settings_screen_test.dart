import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/date/week_calendar.dart';

import '../test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Haftalık Plan',
      packageName: 'test.pkg',
      version: '9.9.9',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  testWidgets('settings shows about with version', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_about_row')), findsOneWidget);
    expect(find.textContaining('9.9.9'), findsWidgets);
    expect(find.byKey(const Key('settings_feature_copy_last_week')), findsOneWidget);
    expect(find.byKey(const Key('settings_feature_plan_shift')), findsOneWidget);
    expect(find.byKey(const Key('settings_reset_all_row')), findsOneWidget);
  });

  testWidgets('reset all data clears database', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    final week = mondayIsoContaining(DateTime.now());
    final repo = TaskRepository(db);
    final now = DateTime.now().toUtc().toIso8601String();
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'WillDelete',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings_reset_all_row')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sıfırla'));
    await tester.pumpAndSettle();

    expect(await db.select(db.tasks).get(), isEmpty);
    expect(await db.select(db.taskHistories).get(), isEmpty);
  });
}
