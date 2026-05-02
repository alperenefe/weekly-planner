import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/widgets/planner_bottom_nav.dart';

void main() {
  testWidgets('PlannerBottomNav reports selection', (tester) async {
    var lastIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlannerBottomNav(
            currentIndex: 0,
            onDestinationSelected: (i) => lastIndex = i,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('nav_summary')));
    await tester.pumpAndSettle();

    expect(lastIndex, PlannerBottomNav.indexSummary);
  });
}
