import 'package:drift/drift.dart' hide Column, isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/date/week_calendar.dart';

import '../test_support.dart';

void main() {
  group('Görev akışları (docs/senaryolar_gorev_akislari.md)', () {
    testWidgets('T1 FAB ile etkinlik ekleme', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      await tester.pumpWidget(plannerAppWithDb(db));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fab_add_task')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_task_sheet')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('add_task_title')),
        'SenaryoT1Etkinlik',
      );
      final scrollable = find.descendant(
        of: find.byKey(const Key('add_task_sheet')),
        matching: find.byType(Scrollable),
      );
      await tester.drag(scrollable.first, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('add_task_save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_task_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_task_sheet')), findsNothing);
      expect(find.text('Etkinlik eklendi'), findsOneWidget);
      expect(find.text('SenaryoT1Etkinlik'), findsOneWidget);
    });

    testWidgets('T2 planlı etkinliği Havuza sürükleyerek taşıma', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      final repo = TaskRepository(db);
      final monday = mondayIsoContaining(DateTime.now());
      final now = DateTime.now().toUtc().toIso8601String();
      final id = await repo.insertTask(
        TasksCompanion.insert(
          title: 'SenaryoT2Tasinir',
          weekStart: monday,
          plannedDate: Value(monday),
          originalPlannedDate: Value(monday),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(plannerAppWithDb(db));
      await tester.pumpAndSettle();

      final dragFinder = find.byKey(Key('task_drag_$id'));
      expect(dragFinder, findsOneWidget);
      final start = tester.getCenter(dragFinder);
      final havuzTitle = find.byKey(const Key('board_col_title_Havuz'));
      final havuzCenter = tester.getCenter(havuzTitle);
      final target = Offset(havuzCenter.dx, start.dy + 100);

      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 900));
      await gesture.moveTo(target);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Etkinlik taşındı'), findsOneWidget);

      final pool = await repo.getPoolTasks(monday);
      expect(pool.length, 1);
      expect(pool.single.title, 'SenaryoT2Tasinir');
      expect(pool.single.plannedDate, isNull);
    });

    testWidgets('T3 planlı etkinlikte tamamlandı işareti', (tester) async {
      tester.view.physicalSize = const Size(1080, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      final repo = TaskRepository(db);
      final week = mondayIsoContaining(DateTime.now());
      final mon = week;
      final now = DateTime.now().toUtc().toIso8601String();
      final id = await repo.insertTask(
        TasksCompanion.insert(
          title: 'SenaryoT3Tick',
          weekStart: week,
          plannedDate: Value(mon),
          originalPlannedDate: Value(mon),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(plannerAppWithDb(db));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('task_card_checkbox_$id')));
      await tester.pumpAndSettle();

      final row = await repo.getTaskById(id);
      expect(row?.status, 'done');
      expect(find.byKey(Key('task_card_unmark_done_$id')), findsOneWidget);
    });

    testWidgets('T4 tamamlandı geri alınır', (tester) async {
      tester.view.physicalSize = const Size(1080, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      final repo = TaskRepository(db);
      final week = mondayIsoContaining(DateTime.now());
      final mon = week;
      final now = DateTime.now().toUtc().toIso8601String();
      final id = await repo.insertTask(
        TasksCompanion.insert(
          title: 'SenaryoT4Unmark',
          weekStart: week,
          plannedDate: Value(mon),
          originalPlannedDate: Value(mon),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(plannerAppWithDb(db));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('task_card_checkbox_$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('task_card_unmark_done_$id')));
      await tester.pumpAndSettle();

      final row = await repo.getTaskById(id);
      expect(row?.status, 'planned');
      expect(find.byKey(Key('task_card_checkbox_$id')), findsOneWidget);
    });

    testWidgets('T5 tamamlandı sonra düzenlemeden silme', (tester) async {
      tester.view.physicalSize = const Size(1080, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      final repo = TaskRepository(db);
      final week = mondayIsoContaining(DateTime.now());
      final mon = week;
      final now = DateTime.now().toUtc().toIso8601String();
      final id = await repo.insertTask(
        TasksCompanion.insert(
          title: 'SenaryoT5DoneSil',
          weekStart: week,
          plannedDate: Value(mon),
          originalPlannedDate: Value(mon),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(plannerAppWithDb(db));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('task_card_checkbox_$id')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('task_title_$id')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_task_sheet')), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit_task_delete')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_task_delete_dialog')));
      await tester.pumpAndSettle();

      expect(await repo.getTaskById(id), isNull);
      expect(find.text('SenaryoT5DoneSil'), findsNothing);
      expect(find.text('Etkinlik silindi'), findsOneWidget);
    });

    testWidgets('T6 havuz etkinliği düzenlemeden silme', (tester) async {
      tester.view.physicalSize = const Size(1080, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      final week = mondayIsoContaining(DateTime.now());
      final repo = TaskRepository(db);
      final now = DateTime.now().toUtc().toIso8601String();
      final id = await repo.insertTask(
        TasksCompanion.insert(
          title: 'SenaryoT6HavuzSil',
          weekStart: week,
          plannedDate: const Value.absent(),
          originalPlannedDate: const Value.absent(),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(plannerAppWithDb(db));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('task_title_$id')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_task_sheet')), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit_task_delete')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_task_delete_dialog')));
      await tester.pumpAndSettle();

      expect(await repo.getTaskById(id), isNull);
      expect(find.text('SenaryoT6HavuzSil'), findsNothing);
    });
  });
}
