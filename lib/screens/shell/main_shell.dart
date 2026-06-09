import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../nav/planner_nav_spec.dart';
import '../../services/planner_feature_flags_store.dart';
import '../../widgets/planner_bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  late final AnimationController _tabFade;

  @override
  void initState() {
    super.initState();
    _tabFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
  }

  @override
  void dispose() {
    _tabFade.dispose();
    super.dispose();
  }

  void _onBranchSelected(int index) {
    if (index != widget.navigationShell.currentIndex) {
      ScaffoldMessenger.of(context).clearSnackBars();
      _tabFade.forward(from: 0);
    }
    widget.navigationShell.goBranch(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerFeatureFlagsStore>(
      builder: (context, store, _) {
        final flags = store.flags;
        final spec = buildPlannerNavSpec(flags);
        return Scaffold(
          extendBody: true,
          body: FadeTransition(
            opacity: CurvedAnimation(
              parent: _tabFade,
              curve: Curves.easeOutCubic,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1).animate(
                CurvedAnimation(
                  parent: _tabFade,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: widget.navigationShell,
            ),
          ),
          bottomNavigationBar: PlannerBottomNav(
            spec: spec,
            shellBranchIndex: widget.navigationShell.currentIndex,
            onBranchSelected: _onBranchSelected,
          ),
        );
      },
    );
  }
}
