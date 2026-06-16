import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/config/planner_feature_flags.dart';
import 'package:weekly_planner/nav/planner_nav_spec.dart';

void main() {
  test('buildPlannerNavSpec includes reminders when enabled', () {
    const flags = PlannerFeatureFlags(periodicRemindersTabEnabled: true);
    final spec = buildPlannerNavSpec(flags);
    expect(spec.branchIndices, contains(4));
    expect(spec.destinations.length, greaterThan(2));
    final labels = spec.destinations.map((d) => d.label).toList();
    expect(labels, contains('Hatırlatıcılar'));
    expect(labels, contains('Ayarlar'));
  });

  test('buildPlannerNavSpec hides reminders when disabled', () {
    const flags = PlannerFeatureFlags(periodicRemindersTabEnabled: false);
    final spec = buildPlannerNavSpec(flags);
    expect(spec.branchIndices, isNot(contains(4)));
    final labels = spec.destinations.map((d) => d.label).toList();
    expect(labels, isNot(contains('Hatırlatıcılar')));
    expect(spec.branchIndices.last, 6);
  });

  test('visibleSelectedIndex maps shell branch 6 to settings', () {
    const flags = PlannerFeatureFlags();
    final spec = buildPlannerNavSpec(flags);
    final settingsVisible = spec.visibleSelectedIndex(6);
    expect(spec.destinations[settingsVisible].label, 'Ayarlar');
  });
}
