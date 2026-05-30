import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/services/task_focus_timer_controller.dart';
import 'package:weekly_planner/theme/design_tokens.dart';
import 'package:weekly_planner/widgets/edit_task_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('Sil çağrıldığında onDeletePressed tetiklenir', (tester) async {
    var deleteCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: DesignTokens.slate950,
          body: EditTaskSheet(
            initialTitle: 'Deneme',
            initialDurationMinutes: 30,
            initialNotes: null,
            initialDayIndex: 1,
            initialStartMinutes: null,
            onSubmit: (title, durationMinutes, notes, dayIndex, startMinutes,
                accentColorArgb) async {
              Object.hash(title, durationMinutes, notes, dayIndex, startMinutes,
                  accentColorArgb);
            },
            onDeletePressed: () async {
              deleteCalls++;
            },
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('edit_task_delete')));
    await tester.tap(find.byKey(const Key('edit_task_delete')));
    await tester.pump();

    expect(deleteCalls, 1);
  });

  testWidgets('durdurduktan sonra Devam et ve kalan dk gösterilir', (tester) async {
    final task = Task(
      id: 99,
      title: 'Odak',
      durationMinutes: 10,
      status: 'planned',
      weekStart: '2025-01-06',
      movedCount: 0,
      createdAt: '2025-01-01T00:00:00.000Z',
      updatedAt: '2025-01-01T00:00:00.000Z',
      reminderEnabled: 0,
    );
    SharedPreferences.setMockInitialValues({
      'task_focus_remaining_seconds_map_v1': jsonEncode({'99': 9 * 60}),
    });
    final focus = TaskFocusTimerController();
    addTearDown(focus.dispose);
    await focus.preloadPartialGoals();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: ChangeNotifierProvider.value(
          value: focus,
          child: Scaffold(
            backgroundColor: DesignTokens.slate950,
            body: EditTaskSheet(
              initialTitle: task.title,
              initialDurationMinutes: task.durationMinutes,
              initialNotes: null,
              initialDayIndex: 0,
              initialStartMinutes: null,
              taskEntity: task,
              onSubmit: (a, b, c, d, e, f) async {
                Object.hash(a, b, c, d, e, f);
              },
              onStartFocus: (draft) async {
                await focus.start(draft);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('dk kaldı'), findsOneWidget);
    expect(find.textContaining('Devam et'), findsOneWidget);
  });
}
