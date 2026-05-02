import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'data/repositories/recurring_template_repository.dart';
import 'data/repositories/task_repository.dart';
import 'plan_data_revision.dart';
import 'services/export_service.dart';
import 'services/summary_service.dart';
import 'services/planner_feature_flags_store.dart';
import 'services/week_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }
  final db = AppDatabase.open();
  final taskRepo = TaskRepository(db);
  final templateRepo = RecurringTemplateRepository(db);
  final weekService = WeekService(
    taskRepository: taskRepo,
    templateRepository: templateRepo,
  );
  final summaryService = SummaryService(taskRepo);
  final exportService = ExportService(taskRepo, summaryService);
  final featureFlags = PlannerFeatureFlagsStore();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanDataRevision()),
        ChangeNotifierProvider.value(value: featureFlags),
        Provider.value(value: db),
        Provider.value(value: taskRepo),
        Provider.value(value: templateRepo),
        Provider.value(value: weekService),
        Provider.value(value: summaryService),
        Provider.value(value: exportService),
      ],
      child: const WeeklyPlannerApp(),
    ),
  );
}
