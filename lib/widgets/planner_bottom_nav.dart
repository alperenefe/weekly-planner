import 'package:flutter/material.dart';

import '../nav/planner_nav_spec.dart';

class PlannerBottomNav extends StatelessWidget {
  const PlannerBottomNav({
    super.key,
    required this.spec,
    required this.shellBranchIndex,
    required this.onBranchSelected,
  });

  final PlannerNavSpec spec;
  final int shellBranchIndex;
  final ValueChanged<int> onBranchSelected;

  static const int branchPlan = 0;
  static const int branchSummary = 1;
  static const int branchHistory = 2;
  static const int branchGoals = 3;
  static const int branchReminders = 4;
  static const int branchSettings = 5;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      key: const Key('planner_bottom_nav'),
      selectedIndex: spec.visibleSelectedIndex(shellBranchIndex),
      onDestinationSelected: (visibleIndex) {
        onBranchSelected(spec.branchForVisible(visibleIndex));
      },
      destinations: spec.destinations,
    );
  }
}
