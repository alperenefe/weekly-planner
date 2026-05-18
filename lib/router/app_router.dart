import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/history_export/history_export_screen.dart';
import '../screens/monthly_goals/monthly_goals_screen.dart';
import '../screens/recurring_templates/recurring_templates_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/week_templates/week_templates_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/summary/summary_screen.dart';
import '../screens/weekly_plan/weekly_plan_screen.dart';
import '../services/planner_feature_flags_store.dart';

final class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

  static GoRouter createRouter(PlannerFeatureFlagsStore featureFlags) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/plan',
      refreshListenable: featureFlags,
      redirect: (context, state) {
        final f = featureFlags.flags;
        final path = state.uri.path;
        if (!f.weekSummaryTabEnabled && path == '/summary') {
          return '/plan';
        }
        if (!f.historyExportTabEnabled && path == '/history') {
          return '/plan';
        }
        if (!f.monthlyGoalsEnabled && path == '/goals') {
          return '/plan';
        }
        return null;
      },
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/plan',
                  builder: (context, state) => const WeeklyPlanScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/summary',
                  builder: (context, state) => const SummaryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (context, state) => const HistoryExportScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/goals',
                  builder: (context, state) => const MonthlyGoalsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => const SettingsScreen(),
                  routes: [
                    GoRoute(
                      path: 'recurring-templates',
                      builder: (context, state) =>
                          const RecurringTemplatesScreen(),
                    ),
                    GoRoute(
                      path: 'templates',
                      builder: (context, state) => const WeekTemplatesScreen(),
                      routes: [
                        GoRoute(
                          path: ':templateId',
                          builder: (context, state) {
                            final raw = state.pathParameters['templateId']!;
                            final id = int.parse(raw);
                            return WeekTemplateDetailScreen(templateId: id);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
