import 'package:flutter/material.dart';

class PlannerBottomNav extends StatelessWidget {
  const PlannerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const int indexPlan = 0;
  static const int indexSummary = 1;
  static const int indexHistory = 2;
  static const int indexSettings = 3;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      key: const Key('planner_bottom_nav'),
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          key: Key('nav_plan'),
          icon: Icon(Icons.calendar_view_week_outlined),
          selectedIcon: Icon(Icons.calendar_view_week),
          label: 'Plan',
        ),
        NavigationDestination(
          key: Key('nav_summary'),
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: 'Özet',
        ),
        NavigationDestination(
          key: Key('nav_history'),
          icon: Icon(Icons.history),
          label: 'Geçmiş',
        ),
        NavigationDestination(
          key: Key('nav_settings'),
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Ayarlar',
        ),
      ],
    );
  }
}
