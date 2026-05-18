import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/theme/design_tokens.dart';
import 'package:weekly_planner/widgets/edit_task_sheet.dart';

void main() {
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
}
