import 'dart:convert';

class PlannerFeatureFlags {
  const PlannerFeatureFlags({
    this.copyLastWeekEnabled = true,
    this.scheduledBreaksEnabled = true,
  });

  final bool copyLastWeekEnabled;
  final bool scheduledBreaksEnabled;

  PlannerFeatureFlags copyWith({
    bool? copyLastWeekEnabled,
    bool? scheduledBreaksEnabled,
  }) {
    return PlannerFeatureFlags(
      copyLastWeekEnabled:
          copyLastWeekEnabled ?? this.copyLastWeekEnabled,
      scheduledBreaksEnabled:
          scheduledBreaksEnabled ?? this.scheduledBreaksEnabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'copyLastWeekEnabled': copyLastWeekEnabled,
        'scheduledBreaksEnabled': scheduledBreaksEnabled,
      };

  static PlannerFeatureFlags fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PlannerFeatureFlags();
    }
    return PlannerFeatureFlags(
      copyLastWeekEnabled:
          (json['copyLastWeekEnabled'] as bool?) ?? true,
      scheduledBreaksEnabled:
          (json['scheduledBreaksEnabled'] as bool?) ?? true,
    );
  }

  static PlannerFeatureFlags? tryParseStored(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PlannerFeatureFlags.fromJson(map);
    } on Object {
      return null;
    }
  }

  String encodeForStorage() => jsonEncode(toJson());
}
