import 'package:flutter/material.dart';



import '../config/planner_feature_flags.dart';



class PlannerNavSpec {

  const PlannerNavSpec({

    required this.branchIndices,

    required this.destinations,

  });



  final List<int> branchIndices;

  final List<NavigationDestination> destinations;



  int visibleSelectedIndex(int shellBranchIndex) {

    final i = branchIndices.indexOf(shellBranchIndex);

    return i >= 0 ? i : 0;

  }



  int branchForVisible(int visibleIndex) {

    return branchIndices[visibleIndex.clamp(0, branchIndices.length - 1)];

  }

}



PlannerNavSpec buildPlannerNavSpec(PlannerFeatureFlags flags) {

  final items = <({int branch, NavigationDestination dest})>[

    (

      branch: 0,

      dest: const NavigationDestination(

        key: Key('nav_plan'),

        icon: Icon(Icons.calendar_view_week_outlined),

        selectedIcon: Icon(Icons.calendar_view_week),

        label: 'Plan',

      ),

    ),

  ];

  if (flags.weekSummaryTabEnabled) {

    items.add((

      branch: 1,

      dest: const NavigationDestination(

        key: Key('nav_summary'),

        icon: Icon(Icons.insights_outlined),

        selectedIcon: Icon(Icons.insights),

        label: 'Özet',

      ),

    ));

  }

  if (flags.historyExportTabEnabled) {

    items.add((

      branch: 2,

      dest: const NavigationDestination(

        key: Key('nav_history'),

        icon: Icon(Icons.history),

        label: 'Geçmiş',

      ),

    ));

  }

  if (flags.monthlyGoalsEnabled) {

    items.add((

      branch: 3,

      dest: const NavigationDestination(

        key: Key('nav_goals'),

        icon: Icon(Icons.flag_outlined),

        selectedIcon: Icon(Icons.flag),

        label: 'Hedefler',

      ),

    ));

  }

  if (flags.periodicRemindersTabEnabled) {

    items.add((

      branch: 4,

      dest: const NavigationDestination(

        key: Key('nav_reminders'),

        icon: Icon(Icons.event_repeat_outlined),

        selectedIcon: Icon(Icons.event_repeat),

        label: 'Hatırlat',

      ),

    ));

  }

  items.add((

    branch: 5,

    dest: const NavigationDestination(

      key: Key('nav_settings'),

      icon: Icon(Icons.settings_outlined),

      selectedIcon: Icon(Icons.settings),

      label: 'Ayarlar',

    ),

  ));

  return PlannerNavSpec(

    branchIndices: items.map((e) => e.branch).toList(),

    destinations: items.map((e) => e.dest).toList(),

  );

}

