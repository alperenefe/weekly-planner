import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hatırlatıcılar ve günlük özet saati (SharedPreferences).
class ReminderSettingsStore extends ChangeNotifier {
  ReminderSettingsStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const _kKey = 'planner_reminder_settings_v1';

  SharedPreferences? _prefs;
  bool _loaded = false;

  bool remindersEnabled = true;
  bool dailySummaryEnabled = false;
  int dailySummaryMinutes = 8 * 60;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        remindersEnabled = (j['remindersEnabled'] as bool?) ?? true;
        dailySummaryEnabled = (j['dailySummaryEnabled'] as bool?) ?? false;
        dailySummaryMinutes =
            (j['dailySummaryMinutes'] as int?) ?? 8 * 60;
      } on Object {
        // varsayılanlar
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _kKey,
      jsonEncode({
        'remindersEnabled': remindersEnabled,
        'dailySummaryEnabled': dailySummaryEnabled,
        'dailySummaryMinutes': dailySummaryMinutes,
      }),
    );
    notifyListeners();
  }

  Future<void> setRemindersEnabled(bool v) async {
    await ensureLoaded();
    remindersEnabled = v;
    await _persist();
  }

  Future<void> setDailySummaryEnabled(bool v) async {
    await ensureLoaded();
    dailySummaryEnabled = v;
    await _persist();
  }

  Future<void> setDailySummaryMinutes(int minutes) async {
    await ensureLoaded();
    dailySummaryMinutes = minutes.clamp(0, 1439);
    await _persist();
  }
}
