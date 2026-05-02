import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/widgets/week_navigation_bar.dart';

void main() {
  testWidgets('WeekNavigationBar callbacks', (tester) async {
    var prev = false;
    var next = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeekNavigationBar(
            label: 'Test week',
            onPrevious: () => prev = true,
            onNext: () => next = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('week_nav_prev')));
    await tester.tap(find.byKey(const Key('week_nav_next')));
    await tester.pumpAndSettle();

    expect(prev, isTrue);
    expect(next, isTrue);
    expect(find.text('Test week'), findsOneWidget);
  });
}
