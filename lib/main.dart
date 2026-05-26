import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'data/repositories/monthly_goal_repository.dart';
import 'data/repositories/recurring_template_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/week_template_repository.dart';
import 'dart:async';

import 'plan_data_revision.dart';
import 'services/export_service.dart';
import 'services/monthly_goal_service.dart';
import 'services/summary_service.dart';
import 'services/planner_feature_flags_store.dart';
import 'services/planner_local_notifications.dart';
import 'services/reminder_scheduler_service.dart';
import 'services/reminder_settings_store.dart';
import 'services/task_focus_timer_controller.dart';
import 'services/week_service.dart';
import 'services/week_template_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }
  final db = AppDatabase.open();
  final taskRepo = TaskRepository(db);
  final templateRepo = RecurringTemplateRepository(db);
  final localNotifications = PlannerLocalNotifications();
  await localNotifications.init();
  final reminderSettings = ReminderSettingsStore();
  await reminderSettings.ensureLoaded();
  final featureFlags = PlannerFeatureFlagsStore();
  final planRevision = PlanDataRevision();
  final weekService = WeekService(
    taskRepository: taskRepo,
    templateRepository: templateRepo,
    featureFlagsStore: featureFlags,
  );
  final summaryService = SummaryService(taskRepo);
  final exportService = ExportService(taskRepo, summaryService);
  final monthlyGoalRepo = MonthlyGoalRepository(db);
  final monthlyGoalService = MonthlyGoalService(taskRepo);
  final weekTemplateRepo = WeekTemplateRepository(db);
  final reminderScheduler = ReminderSchedulerService(
    notifications: localNotifications,
    settings: reminderSettings,
    taskRepo: taskRepo,
    goalRepo: monthlyGoalRepo,
    planRevision: planRevision,
  );
  unawaited(reminderScheduler.syncAll());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: planRevision),
        ChangeNotifierProvider.value(value: featureFlags),
        ChangeNotifierProvider.value(value: reminderSettings),
        Provider.value(value: reminderScheduler),
        Provider.value(value: db),
        Provider.value(value: taskRepo),
        Provider.value(value: templateRepo),
        Provider.value(value: monthlyGoalRepo),
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
        Provider.value(value: localNotifications),
        ChangeNotifierProvider(
          create: (c) => TaskFocusTimerController(
            notifications: c.read<PlannerLocalNotifications>(),
          ),
        ),
      ],
      child: const WeeklyPlannerApp(),
    ),
  );
}
