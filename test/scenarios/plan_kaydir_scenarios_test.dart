import 'package:drift/drift.dart' hide Column, isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/config/planner_feature_flags.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/date/week_calendar.dart';
import 'package:weekly_planner/widgets/plan_shift_sheet.dart';

import '../test_support.dart';

void main() {
  group('Plan kaydır senaryoları (docs/senaryolar_plan_kaydir.md)', () {
    testWidgets('S1 menüden sheet açılır gün chip’leri görünür', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      await tester.pumpWidget(plannerAppWithDb(db));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('top_bar_more')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Planı kaydır').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('plan_shift_sheet')), findsOneWidget);
      expect(find.text('Planı kaydır'), findsWidgets);
      expect(find.byKey(const Key('plan_shift_day_1')), findsOneWidget);
      expect(find.byKey(const Key('plan_shift_day_7')), findsOneWidget);
    });

    testWidgets(
      'S2 cumartesi öğleden sonra sabah başlangıçları çapa olarak kalır',
      (tester) async {
        const weekMonday = '2026-04-27';
        final saturdayIso = plannedDateForChipIndex(weekMonday, 6);
        expect(saturdayIso, isNotNull);

        Task t({
          required int id,
          required String title,
          required int startM,
        }) {
          const stamp = '2026-05-02T08:00:00.000Z';
          return Task(
            id: id,
            title: title,
            durationMinutes: null,
            startMinutes: startM,
            notes: null,
            status: 'planned',
            weekStart: weekMonday,
            plannedDate: saturdayIso,
            originalPlannedDate: saturdayIso,
            movedCount: 0,
            recurrenceTemplateId: null,
            createdAt: stamp,
            updatedAt: stamp,
            completedAt: null,
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: PlanShiftSheet(
                weekStart: weekMonday,
                clock: () => DateTime(2026, 5, 2, 16, 9),
                loadDayTasks: (iso) async {
                  if (iso != saturdayIso) return [];
                  return [
                    t(id: 1, title: 'a', startM: 9 * 60),
                    t(id: 2, title: 'b', startM: 10 * 60),
                    t(id: 3, title: 'c', startM: 11 * 60),
                  ];
                },
                onApply: (_, __, ___) async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(Key('plan_shift_anchor_${9 * 60}')), findsOneWidget);
        expect(
            find.byKey(Key('plan_shift_anchor_${10 * 60}')), findsOneWidget);
        expect(
            find.byKey(Key('plan_shift_anchor_${11 * 60}')), findsOneWidget);
        expect(
          find.text(
            'Bu gün için uygun çapa yok (saatli etkinlik yok veya hepsi geçmiş).',
          ),
          findsNothing,
        );
        final apply = tester.widget<FilledButton>(
          find.byKey(const Key('plan_shift_apply')),
        );
        expect(apply.onPressed, isNotNull);
      },
    );

    testWidgets('S3 Sal ve Per seçilince çapalar o güne göre değişir',
        (tester) async {
      const weekMonday = '2026-04-27';
      final tueIso = plannedDateForChipIndex(weekMonday, 2)!;
      final thuIso = plannedDateForChipIndex(weekMonday, 4)!;

      Task one(int id, String title, int startM, String iso) {
        const stamp = '2026-04-28T08:00:00.000Z';
        return Task(
          id: id,
          title: title,
          durationMinutes: null,
          startMinutes: startM,
          notes: null,
          status: 'planned',
          weekStart: weekMonday,
          plannedDate: iso,
          originalPlannedDate: iso,
          movedCount: 0,
          recurrenceTemplateId: null,
          createdAt: stamp,
          updatedAt: stamp,
          completedAt: null,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: PlanShiftSheet(
              weekStart: weekMonday,
              clock: () => DateTime(2026, 4, 28, 10, 0),
              loadDayTasks: (iso) async {
                if (iso == tueIso) return [one(1, 'sal', 9 * 60, tueIso)];
                if (iso == thuIso) return [one(2, 'per', 15 * 60, thuIso)];
                return [];
              },
              onApply: (_, __, ___) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('plan_shift_anchor_${9 * 60}')), findsOneWidget);
      expect(find.byKey(Key('plan_shift_anchor_${15 * 60}')), findsNothing);

      await tester.tap(find.byKey(const Key('plan_shift_day_4')));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('plan_shift_anchor_${9 * 60}')), findsNothing);
      expect(find.byKey(Key('plan_shift_anchor_${15 * 60}')), findsOneWidget);
    });

    testWidgets('S4 aynı başlangıç saatinde tek çapa', (tester) async {
      const weekMonday = '2026-04-27';
      final saturdayIso = plannedDateForChipIndex(weekMonday, 6);
      expect(saturdayIso, isNotNull);
      const stamp = '2026-05-02T08:00:00.000Z';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: PlanShiftSheet(
              weekStart: weekMonday,
              clock: () => DateTime(2026, 5, 2, 10, 0),
              loadDayTasks: (iso) async {
                if (iso != saturdayIso) return [];
                return [
                  Task(
                    id: 1,
                    title: 'a',
                    durationMinutes: null,
                    startMinutes: 9 * 60,
                    notes: null,
                    status: 'planned',
                    weekStart: weekMonday,
                    plannedDate: saturdayIso,
                    originalPlannedDate: saturdayIso,
                    movedCount: 0,
                    recurrenceTemplateId: null,
                    createdAt: stamp,
                    updatedAt: stamp,
                    completedAt: null,
                  ),
                  Task(
                    id: 2,
                    title: 'b',
                    durationMinutes: null,
                    startMinutes: 9 * 60,
                    notes: null,
                    status: 'planned',
                    weekStart: weekMonday,
                    plannedDate: saturdayIso,
                    originalPlannedDate: saturdayIso,
                    movedCount: 0,
                    recurrenceTemplateId: null,
                    createdAt: stamp,
                    updatedAt: stamp,
                    completedAt: null,
                  ),
                ];
              },
              onApply: (_, __, ___) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('plan_shift_anchor_${9 * 60}')), findsOneWidget);
    });

    testWidgets('S5 saatli görev yoksa uyarı ve Uygula kapalı', (tester) async {
      const weekMonday = '2026-04-27';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: PlanShiftSheet(
              weekStart: weekMonday,
              clock: () => DateTime(2026, 4, 28, 10, 0),
              loadDayTasks: (_) async => [],
              onApply: (_, __, ___) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Bu gün için uygun çapa yok (saatli etkinlik yok veya hepsi geçmiş).',
        ),
        findsOneWidget,
      );
      final apply = tester.widget<FilledButton>(
        find.byKey(const Key('plan_shift_apply')),
      );
      expect(apply.onPressed, isNull);
    });

    testWidgets('S6 geçmiş gün chip’i seçilemez', (tester) async {
      const weekMonday = '2026-04-27';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: PlanShiftSheet(
              weekStart: weekMonday,
              clock: () => DateTime(2026, 5, 2, 12, 0),
              loadDayTasks: (_) async => [],
              onApply: (_, __, ___) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mon = tester.widget<FilterChip>(
        find.byKey(const Key('plan_shift_day_1')),
      );
      expect(mon.onSelected, isNull);
    });

    testWidgets('S7 Uygula snackbar ve veritabanında kaydırma', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      final repo = TaskRepository(db);
      final weekStart = mondayIsoContaining(DateTime.now());
      final todayIso = toIsoDate(DateTime.now());
      final stamps = DateTime.now().toUtc().toIso8601String();

      await repo.insertTask(
        TasksCompanion.insert(
          title: 'SenaryoS7A',
          weekStart: weekStart,
          plannedDate: Value(todayIso),
          originalPlannedDate: Value(todayIso),
          startMinutes: const Value(10 * 60),
          createdAt: stamps,
          updatedAt: stamps,
        ),
      );
      await repo.insertTask(
        TasksCompanion.insert(
          title: 'SenaryoS7B',
          weekStart: weekStart,
          plannedDate: Value(todayIso),
          originalPlannedDate: Value(todayIso),
          startMinutes: const Value(11 * 60),
          createdAt: stamps,
          updatedAt: stamps,
        ),
      );

      await tester.pumpWidget(plannerAppWithDb(db));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('top_bar_more')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Planı kaydır').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('plan_shift_anchor_${10 * 60}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plan_shift_apply')));
      await tester.pumpAndSettle();

      expect(find.text('2 etkinlik kaydırıldı'), findsOneWidget);

      final day = await repo.getDayTasks(weekStart, todayIso);
      final a = day.firstWhere((t) => t.title == 'SenaryoS7A');
      final b = day.firstWhere((t) => t.title == 'SenaryoS7B');
      expect(a.startMinutes, 10 * 60 + 30);
      expect(b.startMinutes, 11 * 60 + 30);
    });

    testWidgets('S9 özellik kapalıyken menüde Planı kaydır yok', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      await tester.pumpWidget(
        plannerAppWithDb(
          db,
          featureFlags: const PlannerFeatureFlags(
            scheduledBreaksEnabled: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('top_bar_more')));
      await tester.pumpAndSettle();

      expect(find.text('Planı kaydır'), findsNothing);
      expect(find.text('Haftayı yenile'), findsOneWidget);
    });

    testWidgets('S10 Haftayı yenile dokunulunca ekran ayakta', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      await tester.pumpWidget(plannerAppWithDb(db));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('top_bar_more')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Haftayı yenile'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('weekly_plan_screen')), findsOneWidget);
    });
  });

  group('S8 (repo)', () {
    test('çapadan sonra başlayan saatli görev yoksa 0 kaydırır', () async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await db.close();
      });
      final repo = TaskRepository(db);
      const week = '2024-11-04';
      final mon = week;
      final stamp = DateTime.utc(2024, 11, 4, 8).toIso8601String();
      await repo.insertTask(
        TasksCompanion.insert(
          title: 'S8Only',
          weekStart: week,
          plannedDate: Value(mon),
          originalPlannedDate: Value(mon),
          startMinutes: const Value(10 * 60),
          createdAt: stamp,
          updatedAt: stamp,
        ),
      );

      final n = await repo.shiftPlannedDayTasksAfterAnchor(
        weekStart: week,
        plannedDateIso: mon,
        anchorStartMinutes: 12 * 60,
        breakMinutes: 30,
      );
      expect(n, 0);
      final list = await repo.getDayTasks(week, mon);
      expect(list.single.startMinutes, 10 * 60);
    });
  });
}
