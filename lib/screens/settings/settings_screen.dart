import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/monthly_goal_repository.dart';
import '../../data/repositories/recurring_template_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../plan_data_revision.dart';
import '../../date/week_calendar.dart';
import '../../services/demo_data_seeder.dart';
import '../../services/planner_feature_flags_store.dart';
import '../../services/week_service.dart';
import '../../services/planner_local_notifications.dart';
import '../../services/reminder_scheduler_service.dart';
import '../../services/reminder_settings_store.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/app_brand_mark.dart';
import '../../widgets/app_update_card.dart';
import '../../widgets/planner_dialogs.dart';
import '../../widgets/planner_top_bar.dart';

part 'settings_screen_body.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _packageInfo = info);
    }
  }

  Future<void> _onRemindersMasterChanged(bool enabled) async {
    if (enabled) {
      await context.read<PlannerLocalNotifications>().ensureReminderPermissions();
    }
    await context.read<ReminderSettingsStore>().setRemindersEnabled(enabled);
    if (!mounted) return;
    await context.read<ReminderSchedulerService>().syncAll();
  }

  Future<void> _onDailySummaryChanged(bool enabled) async {
    await context.read<ReminderSettingsStore>().setDailySummaryEnabled(enabled);
    if (!mounted) return;
    await context.read<ReminderSchedulerService>().syncAll();
  }

  Future<void> _pickDailySummaryTime() async {
    final store = context.read<ReminderSettingsStore>();
    await store.ensureLoaded();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: store.dailySummaryMinutes ~/ 60,
        minute: store.dailySummaryMinutes % 60,
      ),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: DesignTokens.blue500,
              brightness: Brightness.dark,
            ).copyWith(surface: DesignTokens.slate900),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    final mins = snappedStartMinutesFromWallClock(
      hour: picked.hour,
      minute: picked.minute,
    );
    await store.setDailySummaryMinutes(mins);
    if (!mounted) return;
    await context.read<ReminderSchedulerService>().syncAll();
  }

  Future<void> _seedDemoData() async {
    final week = mondayIsoContaining(DateTime.now());
    final n = await DemoDataSeeder(
      taskRepo: context.read<TaskRepository>(),
      goalRepo: context.read<MonthlyGoalRepository>(),
      templateRepo: context.read<RecurringTemplateRepository>(),
    ).seedIfWeekEmpty(week);
    if (!mounted) return;
    await context.read<WeekService>().ensureWeekTasks(week);
    context.read<PlanDataRevision>().bump();
    showPlannerSnackBar(
      context,
      n == 0
          ? 'Bu haftada zaten veri var — demo eklenmedi'
          : 'Örnek veri yüklendi ($n görev)',
    );
  }

  Future<void> _onResetAllData() async {
    final confirmed = await PlannerDialogs.confirmDelete(
      context,
      title: 'Tüm veriyi sıfırla',
      message:
          'Tüm etkinlikler, geçmiş, kayıtlı hafta planları ve otomatik görev kuralları silinecek. Emin misin?',
      deleteLabel: 'Sıfırla',
    );
    if (confirmed != true || !mounted) return;
    final repo = context.read<TaskRepository>();
    await repo.resetAllData();
    if (!mounted) return;
    context.read<PlanDataRevision>().bump();
    await context.read<ReminderSchedulerService>().syncAll();
    showPlannerSnackBar(context, 'Tüm veriler silindi');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('settings_screen'),
      backgroundColor: DesignTokens.slate950,
      appBar: const PlannerTopBar(title: 'Ayarlar'),
      body: _SettingsScrollBody(this),
    );
  }
}
