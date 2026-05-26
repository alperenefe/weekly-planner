import 'package:shared_preferences/shared_preferences.dart';

/// İlk açılış onboarding (3 slayt).
class OnboardingStore {
  static const _kKey = 'planner_onboarding_completed_v1';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kKey) ?? false);
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, true);
  }
}
