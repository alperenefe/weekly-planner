import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/date/week_calendar.dart';
import 'package:weekly_planner/plan_day_labels.dart';

import '../test_support.dart';

void main() {
  testWidgets('boş havuzda boş yer tutucu ve ikon', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weekly_plan_empty_Havuz')), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsWidgets);
  });

  testWidgets('hafta ileri sonraki haftanın görevleri görünür', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    final thisMonday = mondayIsoContaining(DateTime.now());
    final nextMonday = addDaysIso(thisMonday, 7);
    final now = DateTime.now().toUtc().toIso8601String();
    final repo = TaskRepository(db);

    await repo.insertTask(
      TasksCompanion.insert(
        title: 'SadeceBuHaftaXyz',
        weekStart: thisMonday,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.insertTask(
      TasksCompanion.insert(
        title: 'SadeceSonrakiHaftaXyz',
        weekStart: nextMonday,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    expect(find.text('SadeceBuHaftaXyz'), findsOneWidget);
    expect(find.text('SadeceSonrakiHaftaXyz'), findsNothing);

    await tester.tap(find.byKey(const Key('week_nav_next')));
    await tester.pumpAndSettle();

    expect(find.text('SadeceSonrakiHaftaXyz'), findsOneWidget);
    expect(find.text('SadeceBuHaftaXyz'), findsNothing);

    final label = tester.widget<Text>(find.byKey(const Key('week_nav_label')));
    expect(label.data, contains(nextMonday));
  });

  testWidgets('hafta geri önceki haftaya döner', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    final thisMonday = mondayIsoContaining(DateTime.now());
    final prevMonday = addDaysIso(thisMonday, -7);
    final now = DateTime.now().toUtc().toIso8601String();
    final repo = TaskRepository(db);

    await repo.insertTask(
      TasksCompanion.insert(
        title: 'OncekiHaftaGorevXyz',
        weekStart: prevMonday,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    expect(find.text('OncekiHaftaGorevXyz'), findsNothing);

    await tester.tap(find.byKey(const Key('week_nav_prev')));
    await tester.pumpAndSettle();

    expect(find.text('OncekiHaftaGorevXyz'), findsOneWidget);

    final label = tester.widget<Text>(find.byKey(const Key('week_nav_label')));
    expect(label.data, contains(prevMonday));
  });

  testWidgets('gün özeti satırı görünür', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weekly_plan_day_hint')), findsOneWidget);
  });

  testWidgets('üçüncü taşımada sık taşınıyor snackbar', (tester) async {
    tester.view.physicalSize = const Size(2400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    final monday = mondayIsoContaining(DateTime.now());
    final tue = addDaysIso(monday, 1);
    final wed = addDaysIso(monday, 2);
    final now = DateTime.now().toUtc().toIso8601String();
    final repo = TaskRepository(db);
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'CokTasinanXyz',
        weekStart: monday,
        plannedDate: Value(monday),
        originalPlannedDate: Value(monday),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    Future<void> dragToPlanned(String targetDayIso) async {
      final dragFinder = find.byKey(Key('task_drag_$id'));
      final start = tester.getCenter(dragFinder);
      final colTitle = find.byKey(
        Key('board_col_title_${_boardTitleForPlanned(monday, targetDayIso)}'),
      );
      final colCenter = tester.getCenter(colTitle);
      final target = Offset(colCenter.dx, start.dy + 80);
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 900));
      await gesture.moveTo(target);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await dragToPlanned(tue);
    expect(find.text('Etkinlik taşındı'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));

    await dragToPlanned(wed);
    expect(find.text('Etkinlik taşındı'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));

    await dragToPlanned(monday);
    expect(
      find.textContaining('Etkinlik taşındı — sık taşınıyor'),
      findsOneWidget,
    );

    final row = await repo.getTaskById(id);
    expect(row!.movedCount, 3);
  });
}

String _boardTitleForPlanned(String weekMonday, String plannedIso) {
  final isos = weekdayIsosFromMonday(weekMonday);
  final i = isos.indexOf(plannedIso);
  if (i < 0 || i + 1 >= kPlanDayLabels.length) {
    return kPlanDayLabels[1];
  }
  return kPlanDayLabels[i + 1];
}
