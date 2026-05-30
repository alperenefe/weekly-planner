import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/config/planner_feature_flags.dart';

void main() {
  test('toJson fromJson roundtrip', () {
    const original = PlannerFeatureFlags(
      copyLastWeekEnabled: false,
      scheduledBreaksEnabled: true,
      weekSummaryTabEnabled: false,
      historyExportTabEnabled: true,
      planBoardSearchEnabled: false,
      monthlyGoalsEnabled: false,
      recurringTemplatesEnabled: false,
      weekTemplatesEnabled: false,
      periodicRemindersTabEnabled: false,
    );
    final decoded = PlannerFeatureFlags.fromJson(original.toJson());
    expect(decoded.copyLastWeekEnabled, false);
    expect(decoded.scheduledBreaksEnabled, true);
    expect(decoded.weekSummaryTabEnabled, false);
    expect(decoded.historyExportTabEnabled, true);
    expect(decoded.planBoardSearchEnabled, false);
    expect(decoded.monthlyGoalsEnabled, false);
    expect(decoded.recurringTemplatesEnabled, false);
    expect(decoded.weekTemplatesEnabled, false);
    expect(decoded.periodicRemindersTabEnabled, false);
  });

  test('fromJson eksik anahtarlar true varsayar', () {
    final decoded = PlannerFeatureFlags.fromJson(
      <String, dynamic>{'copyLastWeekEnabled': false},
    );
    expect(decoded.copyLastWeekEnabled, false);
    expect(decoded.weekSummaryTabEnabled, true);
    expect(decoded.historyExportTabEnabled, true);
    expect(decoded.planBoardSearchEnabled, true);
    expect(decoded.monthlyGoalsEnabled, true);
    expect(decoded.recurringTemplatesEnabled, true);
    expect(decoded.weekTemplatesEnabled, true);
    expect(decoded.periodicRemindersTabEnabled, true);
  });

  test('tryParseStored invalid returns null', () {
    expect(PlannerFeatureFlags.tryParseStored('not-json'), isNull);
  });
}
