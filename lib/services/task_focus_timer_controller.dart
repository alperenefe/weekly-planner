import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../data/db/app_database.dart';
import 'planner_local_notifications.dart';

enum TaskFocusTimerPhase { idle, running, alarming }

class TaskFocusTimerController extends ChangeNotifier {
  static const _kEndsAtKey = 'task_focus_ends_at';
  static const _kTitleKey = 'task_focus_title';
  static const _kTaskIdKey = 'task_focus_task_id';
  static const _kRemainingMapKey = 'task_focus_remaining_seconds_map_v1';

  final PlannerLocalNotifications? _notifications;

  TaskFocusTimerController({PlannerLocalNotifications? notifications})
      : _notifications = notifications {
    unawaited(_restore());
  }

  TaskFocusTimerPhase _phase = TaskFocusTimerPhase.idle;
  DateTime? _endsAt;
  String _title = '';
  int _taskId = 0;
  Timer? _ticker;
  Timer? _alarmPulse;
  Map<int, int> _remainingByTask = {};

  TaskFocusTimerPhase get phase => _phase;
  String get activeTitle => _title;
  int get activeTaskId => _taskId;

  Future<void> preloadPartialGoals() async {
    await _ensureRemainingsLoaded();
    notifyListeners();
  }

  int budgetRemainingSeconds({
    required int taskId,
    required int goalTotalSeconds,
  }) {
    if (goalTotalSeconds <= 0) return 0;
    final stored = _remainingByTask[taskId];
    final raw = stored ?? goalTotalSeconds;
    if (raw <= 0) return goalTotalSeconds;
    if (raw > goalTotalSeconds) return goalTotalSeconds;
    return raw;
  }

  Duration remainingNow() {
    final e = _endsAt;
    if (e == null || _phase != TaskFocusTimerPhase.running) {
      return Duration.zero;
    }
    final d = e.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  Future<void> start(Task task) async {
    final d = task.durationMinutes;
    if (d == null || d <= 0) return;
    if (task.status != 'planned') return;
    await _ensureRemainingsLoaded();
    if (_phase == TaskFocusTimerPhase.running) {
      await pauseSession();
    } else if (_phase == TaskFocusTimerPhase.alarming) {
      await acknowledgeAlarm();
    } else {
      await _silenceSession();
    }
    final goalSec = d * 60;
    var remSec = budgetRemainingSeconds(
      taskId: task.id,
      goalTotalSeconds: goalSec,
    );
    if (remSec <= 0) {
      remSec = goalSec;
    }
    _taskId = task.id;
    _title = task.title;
    _endsAt = DateTime.now().add(Duration(seconds: remSec));
    _phase = TaskFocusTimerPhase.running;
    await _persist();
    _startTicker();
    await _notifications?.scheduleFocusTimerEnd(
      end: _endsAt!,
      taskId: _taskId,
      title: _title,
    );
    await _notifications?.showFocusTimerRunning(
      end: _endsAt!,
      taskId: _taskId,
      title: _title,
    );
    notifyListeners();
  }

  Future<void> pauseSession() async {
    if (_phase == TaskFocusTimerPhase.alarming) {
      await acknowledgeAlarm();
      return;
    }
    if (_phase != TaskFocusTimerPhase.running ||
        _endsAt == null ||
        _taskId <= 0) {
      await _silenceSession();
      notifyListeners();
      return;
    }
    await _ensureRemainingsLoaded();
    final sec = remainingNow().inSeconds.clamp(0, 86400 * 7);
    _remainingByTask[_taskId] = sec;
    await _persistRemainings();
    await _silenceSession();
    notifyListeners();
  }

  Future<void> resetGoalAndStop() async {
    final tid = _taskId;
    if (tid > 0) {
      await _ensureRemainingsLoaded();
      _remainingByTask.remove(tid);
      await _persistRemainings();
    }
    await _silenceSession();
    notifyListeners();
  }

  Future<void> cancel() async {
    await pauseSession();
  }

  Future<void> clearPersistedAndSilenceAfterDone(int taskId) async {
    await _ensureRemainingsLoaded();
    _remainingByTask.remove(taskId);
    await _persistRemainings();
    await _silenceSession();
    notifyListeners();
  }

  Future<void> acknowledgeAlarm() async {
    final tid = _taskId;
    _stopAlarmPulse();
    _phase = TaskFocusTimerPhase.idle;
    _endsAt = null;
    _title = '';
    _taskId = 0;
    await _clearPrefs();
    await _cancelVibrationPlugin();
    await _notifications?.cancelFocusTimer(tid);
    if (tid > 0) {
      await _ensureRemainingsLoaded();
      _remainingByTask.remove(tid);
      await _persistRemainings();
    }
    notifyListeners();
  }

  void onAppLifecyclePaused() {
    _remainingsHydratedFromDisk = false;
    _ticker?.cancel();
    _ticker = null;
    _alarmPulse?.cancel();
    _alarmPulse = null;
  }

  Future<void> onAppLifecycleResumed() async {
    await _ensureRemainingsLoaded();
    final sp = await SharedPreferences.getInstance();
    final endsStr = sp.getString(_kEndsAtKey);
    if (endsStr == null) {
      if (_phase != TaskFocusTimerPhase.idle) {
        _ticker?.cancel();
        _ticker = null;
        _stopAlarmPulse();
        _phase = TaskFocusTimerPhase.idle;
        _endsAt = null;
        _title = '';
        _taskId = 0;
        notifyListeners();
      }
      return;
    }
    await _applyStoredSession(sp, endsStr);
  }

  Future<void> _restore() async {
    await _ensureRemainingsLoaded();
    final sp = await SharedPreferences.getInstance();
    final endsStr = sp.getString(_kEndsAtKey);
    if (endsStr == null) {
      notifyListeners();
      return;
    }
    await _applyStoredSession(sp, endsStr);
  }

  Future<void> _applyStoredSession(SharedPreferences sp, String endsStr) async {
    final e = DateTime.tryParse(endsStr);
    if (e == null) {
      await _clearPrefs();
      if (_phase != TaskFocusTimerPhase.idle) {
        await _silenceSession();
      }
      return;
    }
    _title = sp.getString(_kTitleKey) ?? '';
    _taskId = sp.getInt(_kTaskIdKey) ?? 0;
    _endsAt = e;
    _ticker?.cancel();
    _ticker = null;
    _stopAlarmPulseOnlyTimer();
    if (DateTime.now().isBefore(e)) {
      _phase = TaskFocusTimerPhase.running;
      _startTicker();
      await _notifications?.scheduleFocusTimerEnd(
        end: e,
        taskId: _taskId,
        title: _title,
      );
      await _notifications?.showFocusTimerRunning(
        end: e,
        taskId: _taskId,
        title: _title,
      );
    } else {
      _phase = TaskFocusTimerPhase.alarming;
      _startAlarmPulse();
      await _notifications?.cancelFocusTimer(_taskId);
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    final e = _endsAt;
    if (e == null) return;
    await sp.setString(_kEndsAtKey, e.toIso8601String());
    await sp.setString(_kTitleKey, _title);
    await sp.setInt(_kTaskIdKey, _taskId);
  }

  Future<void> _clearPrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kEndsAtKey);
    await sp.remove(_kTitleKey);
    await sp.remove(_kTaskIdKey);
  }

  Future<void> _ensureRemainingsLoaded() async {
    if (_remainingsHydratedFromDisk) return;
    final sp = await SharedPreferences.getInstance();
    _remainingByTask = _parseRemainings(sp.getString(_kRemainingMapKey));
    _remainingsHydratedFromDisk = true;
  }

  bool _remainingsHydratedFromDisk = false;

  Future<void> _persistRemainings() async {
    final sp = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _remainingByTask.map((k, v) => MapEntry(k.toString(), v)),
    );
    await sp.setString(_kRemainingMapKey, encoded);
  }

  Map<int, int> _parseRemainings(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final dynamic j = jsonDecode(raw);
      if (j is! Map) return {};
      final out = <int, int>{};
      j.forEach((k, v) {
        final ki = int.tryParse(k.toString());
        final vi = v is int ? v : int.tryParse('$v');
        if (ki != null && vi != null && vi >= 0) {
          out[ki] = vi;
        }
      });
      return out;
    } on Object {
      return {};
    }
  }

  Future<void> _silenceSession() async {
    final tid = _taskId;
    _ticker?.cancel();
    _ticker = null;
    _stopAlarmPulse();
    _phase = TaskFocusTimerPhase.idle;
    _endsAt = null;
    _title = '';
    _taskId = 0;
    await _clearPrefs();
    await _cancelVibrationPlugin();
    await _notifications?.cancelFocusTimer(tid);
  }

  /// `flutter test` ortamında saniyelik timer `pumpAndSettle`'ı sonsuza kilitlemesin.
  static bool get _flutterTest {
    return SchedulerBinding.instance.runtimeType
        .toString()
        .contains('Test');
  }

  void _startTicker() {
    _ticker?.cancel();
    if (_flutterTest) {
      _tickRunningOnceForTests();
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickRunningOnceForTests();
    });
  }

  void _tickRunningOnceForTests() {
    if (_phase != TaskFocusTimerPhase.running || _endsAt == null) return;
    if (!DateTime.now().isBefore(_endsAt!)) {
      _enterAlarming();
    } else {
      notifyListeners();
    }
  }

  void _enterAlarming() {
    final tid = _taskId;
    _ticker?.cancel();
    _ticker = null;
    _phase = TaskFocusTimerPhase.alarming;
    _startAlarmPulse();
    unawaited(_notifications?.cancelFocusTimer(tid));
    if (tid > 0) {
      unawaited(() async {
        await _ensureRemainingsLoaded();
        _remainingByTask[tid] = 0;
        await _persistRemainings();
      }());
    }
    notifyListeners();
  }

  Future<void> _vibratePulse() async {
    try {
      final has = await Vibration.hasVibrator();
      if (has == true) {
        await Vibration.vibrate(duration: 380);
        return;
      }
    } catch (_) {}
    HapticFeedback.heavyImpact();
    HapticFeedback.mediumImpact();
  }

  void _startAlarmPulse() {
    _stopAlarmPulseOnlyTimer();
    unawaited(_vibratePulse());
    if (_flutterTest) return;
    _alarmPulse = Timer.periodic(const Duration(milliseconds: 720), (_) {
      unawaited(_vibratePulse());
    });
  }

  void _stopAlarmPulseOnlyTimer() {
    _alarmPulse?.cancel();
    _alarmPulse = null;
  }

  void _stopAlarmPulse() {
    _stopAlarmPulseOnlyTimer();
    unawaited(_cancelVibrationPlugin());
  }

  Future<void> _cancelVibrationPlugin() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopAlarmPulse();
    super.dispose();
  }
}
