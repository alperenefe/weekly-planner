import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class PlannerLocalNotifications {
  PlannerLocalNotifications();

  static const _channelId = 'focus_timer';
  static const _channelName = 'Odak süresi';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
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
      );
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
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

  int _notifIdScheduled(int taskId) => 5_000_000 + (taskId % 100_000);

  int _notifIdOngoing(int taskId) => 5_100_000 + (taskId % 100_000);

  Future<void> showFocusTimerRunning({
    required DateTime end,
    required int taskId,
    required String title,
  }) async {
    if (!_ready || taskId <= 0) {
      return;
    }
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _plugin.show(
        id: _notifIdOngoing(taskId),
        title: title.isEmpty ? 'Odak' : title,
        body: 'Bitişe kadar geri sayım',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: true,
            when: end.millisecondsSinceEpoch,
            usesChronometer: true,
            chronometerCountDown: true,
            category: AndroidNotificationCategory.progress,
          ),
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
        id: _notifIdScheduled(taskId),
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Süre doldu',
        body: title.isEmpty ? 'Odak' : title,
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
      await _plugin.cancel(id: _notifIdScheduled(taskId));
      await _plugin.cancel(id: _notifIdOngoing(taskId));
    } on Object {
      return;
    }
  }
}
