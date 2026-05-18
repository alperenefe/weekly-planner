import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/config/planner_feature_flags.dart';
import 'package:weekly_planner/nav/planner_nav_spec.dart';
import 'package:weekly_planner/widgets/planner_bottom_nav.dart';

void main() {
  testWidgets('PlannerBottomNav seçim branch index döner', (tester) async {
    var lastBranch = -1;
    const flags = PlannerFeatureFlags();
    final spec = buildPlannerNavSpec(flags);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlannerBottomNav(
            spec: spec,
            shellBranchIndex: 0,
            onBranchSelected: (b) => lastBranch = b,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('nav_summary')));
    await tester.pumpAndSettle();

    expect(lastBranch, PlannerBottomNav.branchSummary);
  });

  testWidgets('Özet kapalıyken nav_summary yok', (tester) async {
    var lastBranch = -1;
    const flags = PlannerFeatureFlags(weekSummaryTabEnabled: false);
    final spec = buildPlannerNavSpec(flags);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlannerBottomNav(
            spec: spec,
            shellBranchIndex: 0,
            onBranchSelected: (b) => lastBranch = b,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('nav_summary')), findsNothing);
    expect(find.byKey(const Key('nav_history')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_history')));
    await tester.pumpAndSettle();
    expect(lastBranch, PlannerBottomNav.branchHistory);
  });
}
