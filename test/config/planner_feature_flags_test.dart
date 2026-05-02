import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/config/planner_feature_flags.dart';

void main() {
  test('toJson fromJson roundtrip', () {
    const original = PlannerFeatureFlags(
      copyLastWeekEnabled: false,
      scheduledBreaksEnabled: true,
    );
    final decoded = PlannerFeatureFlags.fromJson(original.toJson());
    expect(decoded.copyLastWeekEnabled, false);
    expect(decoded.scheduledBreaksEnabled, true);
  });

  test('tryParseStored invalid returns null', () {
    expect(PlannerFeatureFlags.tryParseStored('not-json'), isNull);
  });
}
