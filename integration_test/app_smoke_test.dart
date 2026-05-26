import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/config/planner_feature_flags.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/recurring_template_repository.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/data/repositories/week_template_repository.dart';
import 'package:weekly_planner/data/repositories/week_template_tasks_companion.dart';
import 'package:weekly_planner/date/week_calendar.dart';
import '../test/test_support.dart';
import 'support/integration_binding.dart';

void main() {
  ensurePlannerIntegrationBinding();

  group('E2E smoke (bellek DB)', () {
    testWidgets('1 soğuk açılış plan ekranı', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      await tester.pumpWidget(plannerAppWithDb(db));
      await integrationPumpSettle(tester);

      expect(find.byKey(const Key('weekly_plan_screen')), findsOneWidget);
      expect(find.byKey(const Key('fab_add_task')), findsOneWidget);
    });

    testWidgets('2 FAB ile etkinlik ekleme', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      await tester.pumpWidget(plannerAppWithDb(db));
      await integrationPumpSettle(tester);

      await tester.tap(find.byKey(const Key('fab_add_task')));
      await integrationPumpSettle(tester);
      await tester.enterText(
        find.byKey(const Key('add_task_title')),
        'E2E_Gorev',
      );
      final scrollable = find.descendant(
        of: find.byKey(const Key('add_task_sheet')),
        matching: find.byType(Scrollable),
      );
      await tester.drag(scrollable.first, const Offset(0, -500));
      await integrationPumpSettle(tester);
      await tester.ensureVisible(find.byKey(const Key('add_task_save')));
      await tester.tap(find.byKey(const Key('add_task_save')));
      await integrationPumpSettle(tester);

      expect(find.text('E2E_Gorev'), findsOneWidget);
    });

    testWidgets('3 özellik bayrakları kapalıyken UI gizlenir', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      await tester.pumpWidget(
        plannerAppWithDb(
          db,
          featureFlags: const PlannerFeatureFlags(
            recurringTemplatesEnabled: false,
            weekTemplatesEnabled: false,
          ),
        ),
      );
      await integrationPumpSettle(tester);

      expect(
        find.byKey(const Key('weekly_plan_apply_template')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('nav_settings')));
      await integrationPumpSettle(tester);
      expect(
        find.byKey(const Key('settings_recurring_templates_row')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('settings_week_templates_row')),
        findsNothing,
      );
    });

    testWidgets('3b recurring switch kapatınca planlama satırı gizlenir', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      await tester.pumpWidget(plannerAppWithDb(db));
      await integrationPumpSettle(tester);

      await tester.tap(find.byKey(const Key('nav_settings')));
      await integrationPumpSettle(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_feature_recurring_templates')),
        400,
      );
      await integrationPumpSettle(tester);
      await tester.tap(
        find.byKey(const Key('settings_feature_recurring_templates')),
      );
      await integrationPumpSettle(tester);

      expect(
        find.byKey(const Key('settings_recurring_templates_row')),
        findsNothing,
      );
    });

    testWidgets('4 yeni haftada tekrarlayan şablon görevi', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      final templates = RecurringTemplateRepository(db);
      final now = DateTime.utc(2025, 1, 1, 10).toIso8601String();
      await templates.insertTemplate(
        RecurringTemplatesCompanion.insert(
          title: 'E2E_Recurring',
          durationMinutes: const Value(10),
          createdAt: now,
        ),
      );

      await tester.pumpWidget(plannerAppWithDb(db));
      await integrationPumpSettle(tester);

      await tester.tap(find.byKey(const Key('week_nav_next')));
      await integrationPumpSettle(tester);

      expect(find.text('E2E_Recurring'), findsOneWidget);
    });

    testWidgets('5 kayıtlı hafta planı uygula', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      final wrepo = WeekTemplateRepository(db);
      final tid = await wrepo.insertTemplate('E2E Plan');
      await wrepo.insertTemplateTask(
        WeekTemplateTasksCompanion.insert(
          templateId: tid,
          title: 'E2E_TplTask',
        ),
      );

      await tester.pumpWidget(plannerAppWithDb(db));
      await integrationPumpSettle(tester);

      await tester.tap(find.byKey(const Key('weekly_plan_apply_template')));
      await integrationPumpSettle(tester);
      await tester.tap(find.text('E2E Plan'));
      await integrationPumpSettle(tester);
      await tester.tap(find.text('Devam'));
      await integrationPumpSettle(tester);

      expect(find.text('E2E_TplTask'), findsOneWidget);
    });

    testWidgets('6 geçmiş sekmesi açılır', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      await tester.pumpWidget(plannerAppWithDb(db));
      await integrationPumpSettle(tester);

      await tester.tap(find.byKey(const Key('nav_history')));
      await integrationPumpSettle(tester);

      expect(find.byKey(const Key('history_export_screen')), findsOneWidget);
    });

    testWidgets('7 odak süresi duraklatınca kalan süre gösterilir ve devam eder', (
      tester,
    ) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      final week = mondayIsoContaining(DateTime.now());
      final repo = TaskRepository(db);
      final now = DateTime.now().toUtc().toIso8601String();
      final id = await repo.insertTask(
        TasksCompanion.insert(
          title: 'E2E_Focus',
          weekStart: week,
          durationMinutes: const Value(25),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(plannerAppWithDb(db));
      await integrationPumpSettle(tester);

      await tester.tap(find.byKey(Key('task_title_$id')));
      await integrationPumpSettle(tester);
      await tester.tap(find.byKey(const Key('edit_task_start_focus')));
      await integrationPumpSettle(tester);

      expect(find.textContaining('Kalan'), findsOneWidget);

      await tester.tap(find.text('Durdur'));
      await integrationPumpSettle(tester);

      await tester.tap(find.byKey(Key('task_title_$id')));
      await integrationPumpSettle(tester);

      expect(find.textContaining('dk kaldı'), findsWidgets);
      expect(find.byKey(Key('task_focus_remaining_$id')), findsOneWidget);
    });
  });
}
