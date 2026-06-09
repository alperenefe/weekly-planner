import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weekly_planner/app.dart';
import 'package:weekly_planner/config/planner_feature_flags.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/monthly_goal_repository.dart';
import 'package:weekly_planner/data/repositories/periodic_reminder_repository.dart';
import 'package:weekly_planner/data/repositories/recurring_template_repository.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/data/repositories/week_template_repository.dart';
import 'package:weekly_planner/plan_data_revision.dart';
import 'package:weekly_planner/services/export_service.dart';
import 'package:weekly_planner/services/monthly_goal_service.dart';
import 'package:weekly_planner/services/planner_feature_flags_store.dart';
import 'package:weekly_planner/services/planner_local_notifications.dart';
import 'package:weekly_planner/services/reminder_scheduler_service.dart';
import 'package:weekly_planner/services/reminder_settings_store.dart';
import 'package:weekly_planner/services/summary_service.dart';
import 'package:weekly_planner/services/task_focus_timer_controller.dart';
import 'package:weekly_planner/services/week_service.dart';
import 'package:weekly_planner/services/week_template_service.dart';

MultiProvider plannerAppWithDb(
  AppDatabase db, {
  PlannerFeatureFlags featureFlags = const PlannerFeatureFlags(),
}) {
  SharedPreferences.setMockInitialValues({
    'planner_onboarding_completed_v1': true,
  });
  final taskRepo = TaskRepository(db);
  final templateRepo = RecurringTemplateRepository(db);
  final flagsStore = PlannerFeatureFlagsStore(initial: featureFlags);
  final weekService = WeekService(
    taskRepository: taskRepo,
    templateRepository: templateRepo,
    featureFlagsStore: flagsStore,
  );
  final summaryService = SummaryService(taskRepo);
  final exportService = ExportService(taskRepo, summaryService);
  final monthlyGoalRepo = MonthlyGoalRepository(db);
  final periodicReminderRepo = PeriodicReminderRepository(db);
  final monthlyGoalService = MonthlyGoalService(taskRepo);
  final weekTemplateRepo = WeekTemplateRepository(db);
  final planRevision = PlanDataRevision();
  final reminderSettings = ReminderSettingsStore();
  final localNotifications = PlannerLocalNotifications();
  final reminderScheduler = ReminderSchedulerService(
    notifications: localNotifications,
    settings: reminderSettings,
    taskRepo: taskRepo,
    goalRepo: monthlyGoalRepo,
    planRevision: planRevision,
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: planRevision),
      ChangeNotifierProvider.value(value: flagsStore),
      ChangeNotifierProvider.value(value: reminderSettings),
      Provider.value(value: reminderScheduler),
      Provider.value(value: localNotifications),
      Provider.value(value: db),
      Provider.value(value: taskRepo),
      Provider.value(value: templateRepo),
      Provider.value(value: monthlyGoalRepo),
      Provider.value(value: periodicReminderRepo),
      Provider.value(value: monthlyGoalService),
      Provider.value(value: weekTemplateRepo),
      Provider(
        create: (c) => WeekTemplateService(
          c.read<TaskRepository>(),
          c.read<WeekTemplateRepository>(),
          c.read<PlanDataRevision>(),
        ),
      ),
      Provider.value(value: weekService),
      Provider.value(value: summaryService),
      Provider.value(value: exportService),
      ChangeNotifierProvider(create: (_) => TaskFocusTimerController()),
    ],
    child: const WeeklyPlannerApp(themeMode: ThemeMode.dark),
  );
}
