import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/widgets/add_task_sheet.dart';

void main() {
  testWidgets('empty title shows error and keeps sheet open', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTaskSheet(
            onSubmit: (_, __, ___, ____, _____, ______) async {},
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('add_task_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_task_save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('add_task_sheet')), findsOneWidget);
    expect(find.text('Başlık girmelisin'), findsWidgets);
  });
}
