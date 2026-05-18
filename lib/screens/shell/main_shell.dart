import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../nav/planner_nav_spec.dart';
import '../../services/planner_feature_flags_store.dart';
import '../../widgets/planner_bottom_nav.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerFeatureFlagsStore>(
      builder: (context, store, _) {
        final flags = store.flags;
        final spec = buildPlannerNavSpec(flags);
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: PlannerBottomNav(
            spec: spec,
            shellBranchIndex: navigationShell.currentIndex,
            onBranchSelected: navigationShell.goBranch,
          ),
        );
      },
    );
  }
}
