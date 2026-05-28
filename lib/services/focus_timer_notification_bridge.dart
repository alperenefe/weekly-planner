import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'task_focus_timer_controller.dart';

/// Bildirim aksiyonlarını (arka plan dahil) SharedPreferences üzerinden iletir.
class FocusTimerNotificationBridge {
  FocusTimerNotificationBridge._();

  static const pendingActionKey = 'focus_timer_pending_notif_action_v1';

  static TaskFocusTimerController? _controller;

  static void bind(TaskFocusTimerController controller) {
    _controller = controller;
  }

  static void unbind(TaskFocusTimerController controller) {
    if (identical(_controller, controller)) {
      _controller = null;
    }
  }

  @pragma('vm:entry-point')
  static Future<void> backgroundTap(NotificationResponse response) async {
    await enqueue(response);
  }

  static Future<void> foregroundTap(NotificationResponse response) async {
    await enqueue(response);
    await _controller?.processPendingNotificationAction();
  }

  static Future<void> enqueue(NotificationResponse response) async {
    final parsed = _parse(response);
    if (parsed == null) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(pendingActionKey, parsed);
  }

  static String? _parse(NotificationResponse response) {
    final taskId = _taskIdFromPayload(response.payload);
    if (response.actionId == FocusTimerNotifActions.ack) {
      return 'ack:${taskId ?? 0}';
    }
    if (response.actionId == FocusTimerNotifActions.done) {
      return 'done:${taskId ?? 0}';
    }
    if (response.payload?.startsWith('focus_alarm:') == true) {
      return 'ack:${taskId ?? 0}';
    }
    return null;
  }

  static int? _taskIdFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final parts = payload.split(':');
    if (parts.length < 2) return null;
    return int.tryParse(parts.last);
  }
}

class FocusTimerNotifActions {
  static const ack = 'focus_timer_ack';
  static const done = 'focus_timer_done';
}
