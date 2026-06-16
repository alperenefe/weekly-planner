import 'dart:convert';

class PlannerFeatureFlags {
  const PlannerFeatureFlags({
    this.copyLastWeekEnabled = true,
    this.scheduledBreaksEnabled = true,
    this.weekSummaryTabEnabled = true,
    this.historyExportTabEnabled = true,
    this.planBoardSearchEnabled = true,
    this.monthlyGoalsEnabled = true,
    this.recurringTemplatesEnabled = true,
    this.weekTemplatesEnabled = true,
    this.periodicRemindersTabEnabled = true,
    this.todosTabEnabled = true,
  });

  final bool copyLastWeekEnabled;
  final bool scheduledBreaksEnabled;
  final bool weekSummaryTabEnabled;
  final bool historyExportTabEnabled;
  final bool planBoardSearchEnabled;
  final bool monthlyGoalsEnabled;
  final bool recurringTemplatesEnabled;
  final bool weekTemplatesEnabled;
  final bool periodicRemindersTabEnabled;
  final bool todosTabEnabled;

  PlannerFeatureFlags copyWith({
    bool? copyLastWeekEnabled,
    bool? scheduledBreaksEnabled,
    bool? weekSummaryTabEnabled,
    bool? historyExportTabEnabled,
    bool? planBoardSearchEnabled,
    bool? monthlyGoalsEnabled,
    bool? recurringTemplatesEnabled,
    bool? weekTemplatesEnabled,
    bool? periodicRemindersTabEnabled,
    bool? todosTabEnabled,
  }) {
    return PlannerFeatureFlags(
      copyLastWeekEnabled: copyLastWeekEnabled ?? this.copyLastWeekEnabled,
      scheduledBreaksEnabled:
          scheduledBreaksEnabled ?? this.scheduledBreaksEnabled,
      weekSummaryTabEnabled:
          weekSummaryTabEnabled ?? this.weekSummaryTabEnabled,
      historyExportTabEnabled:
          historyExportTabEnabled ?? this.historyExportTabEnabled,
      planBoardSearchEnabled:
          planBoardSearchEnabled ?? this.planBoardSearchEnabled,
      monthlyGoalsEnabled:
          monthlyGoalsEnabled ?? this.monthlyGoalsEnabled,
      recurringTemplatesEnabled:
          recurringTemplatesEnabled ?? this.recurringTemplatesEnabled,
      weekTemplatesEnabled:
          weekTemplatesEnabled ?? this.weekTemplatesEnabled,
      periodicRemindersTabEnabled:
          periodicRemindersTabEnabled ?? this.periodicRemindersTabEnabled,
      todosTabEnabled: todosTabEnabled ?? this.todosTabEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlannerFeatureFlags &&
        other.copyLastWeekEnabled == copyLastWeekEnabled &&
        other.scheduledBreaksEnabled == scheduledBreaksEnabled &&
        other.weekSummaryTabEnabled == weekSummaryTabEnabled &&
        other.historyExportTabEnabled == historyExportTabEnabled &&
        other.planBoardSearchEnabled == planBoardSearchEnabled &&
        other.monthlyGoalsEnabled == monthlyGoalsEnabled &&
        other.recurringTemplatesEnabled == recurringTemplatesEnabled &&
        other.weekTemplatesEnabled == weekTemplatesEnabled &&
        other.periodicRemindersTabEnabled == periodicRemindersTabEnabled &&
        other.todosTabEnabled == todosTabEnabled;
  }

  @override
  int get hashCode => Object.hash(
        copyLastWeekEnabled,
        scheduledBreaksEnabled,
        weekSummaryTabEnabled,
        historyExportTabEnabled,
        planBoardSearchEnabled,
        monthlyGoalsEnabled,
        recurringTemplatesEnabled,
        weekTemplatesEnabled,
        periodicRemindersTabEnabled,
        todosTabEnabled,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'copyLastWeekEnabled': copyLastWeekEnabled,
        'scheduledBreaksEnabled': scheduledBreaksEnabled,
        'weekSummaryTabEnabled': weekSummaryTabEnabled,
        'historyExportTabEnabled': historyExportTabEnabled,
        'planBoardSearchEnabled': planBoardSearchEnabled,
        'monthlyGoalsEnabled': monthlyGoalsEnabled,
        'recurringTemplatesEnabled': recurringTemplatesEnabled,
        'weekTemplatesEnabled': weekTemplatesEnabled,
        'periodicRemindersTabEnabled': periodicRemindersTabEnabled,
        'todosTabEnabled': todosTabEnabled,
      };

  static PlannerFeatureFlags fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PlannerFeatureFlags();
    }
    return PlannerFeatureFlags(
      copyLastWeekEnabled: (json['copyLastWeekEnabled'] as bool?) ?? true,
      scheduledBreaksEnabled:
          (json['scheduledBreaksEnabled'] as bool?) ?? true,
      weekSummaryTabEnabled: (json['weekSummaryTabEnabled'] as bool?) ?? true,
      historyExportTabEnabled:
          (json['historyExportTabEnabled'] as bool?) ?? true,
      planBoardSearchEnabled:
          (json['planBoardSearchEnabled'] as bool?) ?? true,
      monthlyGoalsEnabled: (json['monthlyGoalsEnabled'] as bool?) ?? true,
      recurringTemplatesEnabled:
          (json['recurringTemplatesEnabled'] as bool?) ?? true,
      weekTemplatesEnabled: (json['weekTemplatesEnabled'] as bool?) ?? true,
      periodicRemindersTabEnabled:
          (json['periodicRemindersTabEnabled'] as bool?) ?? true,
      todosTabEnabled: (json['todosTabEnabled'] as bool?) ?? true,
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
