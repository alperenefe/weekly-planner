import 'dart:async';

import 'package:flutter/scheduler.dart';

import '../data/repositories/monthly_goal_repository.dart';
import '../data/repositories/task_repository.dart';
import '../date/week_calendar.dart';
import '../plan_data_revision.dart';
import 'planner_local_notifications.dart';
import 'reminder_settings_store.dart';

/// Zamanlanmış hatırlatıcıları DB + ayarlara göre senkronlar.
class ReminderSchedulerService {
  ReminderSchedulerService({
    required PlannerLocalNotifications notifications,
    required ReminderSettingsStore settings,
    required TaskRepository taskRepo,
    required MonthlyGoalRepository goalRepo,
    required PlanDataRevision planRevision,
  })  : _notifications = notifications,
        _settings = settings,
        _taskRepo = taskRepo,
        _goalRepo = goalRepo {
    planRevision.addListener(_onPlanRevision);
  }

  final PlannerLocalNotifications _notifications;
  final ReminderSettingsStore _settings;
  final TaskRepository _taskRepo;
  final MonthlyGoalRepository _goalRepo;

  Timer? _syncDebounce;
  Future<void>? _syncInFlight;

  bool get _inWidgetTest {
    final binding = SchedulerBinding.instance;
    return binding.runtimeType.toString().contains('Test');
  }

  void _onPlanRevision() {
    if (_inWidgetTest) {
      unawaited(syncAll());
      return;
    }
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(syncAll());
    });
  }

  Future<void> syncAll() async {
    if (_syncInFlight != null) {
      await _syncInFlight;
      return;
    }
    final run = _syncAllImpl();
    _syncInFlight = run;
    try {
      await run;
    } finally {
      if (identical(_syncInFlight, run)) {
        _syncInFlight = null;
      }
    }
  }

  Future<void> _syncAllImpl() async {
    await _settings.ensureLoaded();
    final goalIds = await _goalRepo.getGoalIdsWithReminderFlag();
    await _clearLegacyTaskReminders();
    if (!_settings.remindersEnabled) {
      await _notifications.cancelAllReminders(
        taskIds: const [],
        goalIds: goalIds,
      );
      return;
    }
    await _notifications.cancelAllReminders(
      taskIds: const [],
      goalIds: goalIds,
    );
    for (final id in goalIds) {
      await _notifications.cancelMonthlyGoalReminder(id);
    }
    await _syncDailySummary();
    await _syncMonthlyGoalReminders();
  }

  Future<void> _clearLegacyTaskReminders() async {
    final taskIds = await _taskRepo.clearAllTaskReminderFlags();
    for (final id in taskIds) {
      await _notifications.cancelTaskReminder(id);
    }
  }

  Future<void> _syncDailySummary() async {
    if (!_settings.dailySummaryEnabled) {
      await _notifications.cancelDailySummary();
      return;
    }
    final body = await _buildDailySummaryBody();
    await _notifications.scheduleDailySummary(
      minutesOfDay: _settings.dailySummaryMinutes,
      body: body,
    );
  }

  Future<String> _buildDailySummaryBody() async {
    final today = toIsoDate(DateTime.now());
    final monday = mondayIsoContaining(DateTime.now());
    final dayTasks = await _taskRepo.getDayTasks(monday, today);
    final pool = await _taskRepo.getPoolTasks(monday);
    final planned = [
      ...dayTasks.where((t) => t.status == 'planned'),
      ...pool.where((t) => t.status == 'planned'),
    ];
    if (planned.isEmpty) {
      return 'Bugün planlı etkinlik yok.';
    }
    final lines = <String>[];
    for (final t in planned.take(8)) {
      final time = t.startMinutes != null
          ? formatClockMinutes(t.startMinutes!)
          : null;
      final prefix = time != null ? '$time — ' : '';
      lines.add('$prefix${t.title}');
    }
    if (planned.length > 8) {
      lines.add('… ve ${planned.length - 8} etkinlik daha');
    }
    return lines.join('\n');
  }

  Future<void> _syncMonthlyGoalReminders() async {
    final goals = await _goalRepo.getGoalsWithActiveReminders();
    for (final g in goals) {
      if (!g.reminderEnabled) continue;
      final wd = g.reminderWeekday;
      final mins = g.reminderMinutes;
      if (wd == null || mins == null) continue;
      await _notifications.scheduleMonthlyGoalReminder(
        goalId: g.id,
        weekday: wd,
        minutesOfDay: mins,
        title: g.title,
      );
    }
  }

  void dispose() {
    _syncDebounce?.cancel();
  }
}
