import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/planner_feature_flags.dart';

class PlannerFeatureFlagsStore extends ChangeNotifier {
  PlannerFeatureFlagsStore({PlannerFeatureFlags? initial}) {
    if (initial != null) {
      _flags = initial;
    } else {
      unawaited(_loadFromDisk());
    }
  }

  static const String _prefsKey = 'planner_feature_flags_v1';

  PlannerFeatureFlags _flags = const PlannerFeatureFlags();

  PlannerFeatureFlags get flags => _flags;

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final parsed = PlannerFeatureFlags.tryParseStored(raw);
    if (parsed != null) {
      _flags = parsed;
      notifyListeners();
    }
  }

  Future<void> setFlags(PlannerFeatureFlags next) async {
    _flags = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, next.encodeForStorage());
  }
}
