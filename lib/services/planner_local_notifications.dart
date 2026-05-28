import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'focus_timer_notification_bridge.dart';

class PlannerLocalNotifications {
  PlannerLocalNotifications();

  static const _focusChannelId = 'focus_timer';
  static const _focusChannelName = 'Odak süresi';
  static const _focusAlarmChannelId = 'focus_timer_alarm';
  static const _focusAlarmChannelName = 'Odak süresi bitti';
  static const _reminderChannelId = 'reminders';
  static const _reminderChannelName = 'Hatırlatıcılar';

  static Int64List get _alarmVibrationPattern =>
      Int64List.fromList([0, 420, 180, 420, 180, 420, 180, 420]);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init({
    void Function(NotificationResponse)? onNotificationResponse,
    void Function(NotificationResponse)? onBackgroundNotificationResponse,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    try {
      tzdata.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      } on Object {
        tz.setLocalLocation(tz.UTC);
      }
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
        onDidReceiveNotificationResponse: onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            onBackgroundNotificationResponse,
      );
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _focusChannelId,
          _focusChannelName,
          description: 'Odak süresi geri sayımı',
          importance: Importance.low,
          showBadge: false,
        ),
      );
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          _focusAlarmChannelId,
          _focusAlarmChannelName,
          description: 'Süre dolduğunda titreşim ve uyarı',
          importance: Importance.max,
          enableVibration: true,
          vibrationPattern: _alarmVibrationPattern,
          playSound: true,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _reminderChannelId,
          _reminderChannelName,
          description: 'Günlük özet ve etkinlik hatırlatmaları',
          importance: Importance.defaultImportance,
        ),
      );
      await android?.requestNotificationsPermission();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
      _ready = true;
    } on Object {
      _ready = false;
    }
  }

  int _notifIdFocusScheduled(int taskId) => 5_000_000 + (taskId % 100_000);

  int _notifIdFocusOngoing(int taskId) => 5_100_000 + (taskId % 100_000);

  int _notifIdTask(int taskId) => 6_000_000 + (taskId % 100_000);

  static const int _notifIdDailySummary = 6_200_000;

  int _notifIdGoal(int goalId) => 6_300_000 + (goalId % 100_000);

  int _notifIdFocusAlarm(int taskId) => 5_200_000 + (taskId % 100_000);

  static String formatFocusRemaining(Duration remaining) {
    final t = remaining.inSeconds.clamp(0, 86400);
    final m = t ~/ 60;
    final s = t % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} kaldı';
  }

  NotificationDetails _focusRunningDetails({
    required DateTime end,
    required Duration remaining,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _focusChannelId,
        _focusChannelName,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: false,
        when: end.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: true,
        category: AndroidNotificationCategory.progress,
        visibility: NotificationVisibility.public,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  NotificationDetails _focusAlarmDetails({
    required int taskId,
    bool vibrate = true,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _focusAlarmChannelId,
        _focusAlarmChannelName,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        enableVibration: vibrate,
        vibrationPattern: vibrate ? _alarmVibrationPattern : null,
        playSound: true,
        ongoing: true,
        autoCancel: false,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            FocusTimerNotifActions.ack,
            'Sustur',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            FocusTimerNotifActions.done,
            'Tamamlandı',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
  }

  NotificationDetails get _reminderDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          _reminderChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  tz.TZDateTime _nextInstanceOfMinutes(int minutesOfDay) {
    final h = minutesOfDay ~/ 60;
    final m = minutesOfDay % 60;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      h,
      m,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int minutesOfDay) {
    final targetDart = weekday.clamp(1, 7);
    final h = minutesOfDay ~/ 60;
    final m = minutesOfDay % 60;
    var scheduled = _nextInstanceOfMinutes(minutesOfDay);
    while (scheduled.weekday != targetDart) {
      scheduled = scheduled.add(const Duration(days: 1));
      scheduled = tz.TZDateTime(
        tz.local,
        scheduled.year,
        scheduled.month,
        scheduled.day,
        h,
        m,
      );
    }
    return scheduled;
  }

  Future<void> scheduleDailySummary({
    required int minutesOfDay,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: _notifIdDailySummary,
        scheduledDate: _nextInstanceOfMinutes(minutesOfDay),
        matchDateTimeComponents: DateTimeComponents.time,
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Bugünün planı',
        body: body,
      );
    } on Object {
      return;
    }
  }

  Future<void> cancelDailySummary() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _notifIdDailySummary);
    } on Object {
      return;
    }
  }

  Future<void> scheduleTaskReminder({
    required int taskId,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (!_ready || taskId <= 0) return;
    try {
      final tzWhen = tz.TZDateTime.from(when, tz.local);
      if (!tzWhen.isAfter(tz.TZDateTime.now(tz.local))) return;
      await _plugin.zonedSchedule(
        id: _notifIdTask(taskId),
        scheduledDate: tzWhen,
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title.isEmpty ? 'Hatırlatma' : title,
        body: body,
      );
    } on Object {
      return;
    }
  }

  Future<void> cancelTaskReminder(int taskId) async {
    if (!_ready || taskId <= 0) return;
    try {
      await _plugin.cancel(id: _notifIdTask(taskId));
    } on Object {
      return;
    }
  }

  Future<void> scheduleMonthlyGoalReminder({
    required int goalId,
    required int weekday,
    required int minutesOfDay,
    required String title,
  }) async {
    if (!_ready || goalId <= 0) return;
    try {
      await _plugin.zonedSchedule(
        id: _notifIdGoal(goalId),
        scheduledDate: _nextInstanceOfWeekdayTime(weekday, minutesOfDay),
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Aylık hedef',
        body: title.isEmpty ? 'Hedef hatırlatması' : title,
      );
    } on Object {
      return;
    }
  }

  Future<void> cancelMonthlyGoalReminder(int goalId) async {
    if (!_ready || goalId <= 0) return;
    try {
      await _plugin.cancel(id: _notifIdGoal(goalId));
    } on Object {
      return;
    }
  }

  Future<void> cancelAllReminders({
    Iterable<int> taskIds = const [],
    Iterable<int> goalIds = const [],
  }) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _notifIdDailySummary);
      for (final id in taskIds) {
        await _plugin.cancel(id: _notifIdTask(id));
      }
      for (final id in goalIds) {
        await _plugin.cancel(id: _notifIdGoal(id));
      }
    } on Object {
      return;
    }
  }

  Future<void> ensureReminderPermissions() async {
    if (!_ready) return;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } on Object {
      return;
    }
  }

  Future<void> showFocusTimerRunning({
    required DateTime end,
    required int taskId,
    required String title,
    Duration? remaining,
  }) async {
    if (!_ready || taskId <= 0) {
      return;
    }
    if (!Platform.isAndroid) {
      return;
    }
    final rem = remaining ?? end.difference(DateTime.now());
    final clamped = rem.isNegative ? Duration.zero : rem;
    try {
      await _plugin.show(
        id: _notifIdFocusOngoing(taskId),
        title: title.isEmpty ? 'Odak' : title,
        body: formatFocusRemaining(clamped),
        payload: 'focus_running:$taskId',
        notificationDetails: _focusRunningDetails(
          end: end,
          remaining: clamped,
        ),
      );
    } on Object {
      return;
    }
  }

  Future<void> showFocusTimerAlarm({
    required int taskId,
    required String title,
    bool vibrate = true,
  }) async {
    if (!_ready || taskId <= 0) {
      return;
    }
    try {
      await _plugin.cancel(id: _notifIdFocusOngoing(taskId));
      await _plugin.show(
        id: _notifIdFocusAlarm(taskId),
        title: 'Süre doldu',
        body: title.isEmpty ? 'Odak süresi bitti' : title,
        payload: 'focus_alarm:$taskId',
        notificationDetails: _focusAlarmDetails(
          taskId: taskId,
          vibrate: vibrate,
        ),
      );
    } on Object {
      return;
    }
  }

  Future<void> scheduleFocusTimerEnd({
    required DateTime end,
    required int taskId,
    required String title,
    bool vibrate = true,
  }) async {
    if (!_ready || taskId <= 0) {
      return;
    }
    try {
      final when = tz.TZDateTime.from(end, tz.local);
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) {
        return;
      }
      await _plugin.zonedSchedule(
        id: _notifIdFocusScheduled(taskId),
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _focusAlarmChannelId,
            _focusAlarmChannelName,
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true,
            enableVibration: vibrate,
            vibrationPattern: vibrate ? _alarmVibrationPattern : null,
            playSound: true,
            ongoing: true,
            autoCancel: false,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                FocusTimerNotifActions.ack,
                'Sustur',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                FocusTimerNotifActions.done,
                'Tamamlandı',
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: 'Süre doldu',
        body: title.isEmpty ? 'Odak süresi bitti' : title,
        payload: 'focus_alarm:$taskId',
      );
    } on Object {
      return;
    }
  }

  Future<void> cancelFocusTimer(int taskId) async {
    if (!_ready || taskId <= 0) {
      return;
    }
    try {
      await _plugin.cancel(id: _notifIdFocusScheduled(taskId));
      await _plugin.cancel(id: _notifIdFocusOngoing(taskId));
      await _plugin.cancel(id: _notifIdFocusAlarm(taskId));
    } on Object {
      return;
    }
  }
}
