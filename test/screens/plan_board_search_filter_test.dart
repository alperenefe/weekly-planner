import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/config/planner_feature_flags.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/screens/weekly_plan/plan_board_search_filter.dart';

void main() {
  const flagsOn = PlannerFeatureFlags(planBoardSearchEnabled: true);
  const flagsOff = PlannerFeatureFlags(planBoardSearchEnabled: false);

  Task t(int id, String title) {
    const stamp = '2026-01-01T00:00:00.000Z';
    return Task(
      id: id,
      title: title,
      durationMinutes: null,
      startMinutes: null,
      notes: null,
      status: 'planned',
      weekStart: '2026-01-05',
      plannedDate: null,
      originalPlannedDate: null,
      movedCount: 0,
      recurrenceTemplateId: null,
      createdAt: stamp,
      updatedAt: stamp,
      completedAt: null,
    );
  }

  test('arama kapalıysa filtre uygulanmaz', () {
    final pool = [t(1, 'Ab'), t(2, 'Cd')];
    final out = PlanBoardSearchFilter.poolColumn(
      flags: flagsOff,
      isSearching: true,
      searchRaw: 'Ab',
      pool: pool,
    );
    expect(out.length, 2);
  });

  test('arama açık ve aranıyorsa başlığa göre süzülür', () {
    final pool = [t(1, 'Alpha'), t(2, 'Beta')];
    final out = PlanBoardSearchFilter.poolColumn(
      flags: flagsOn,
      isSearching: true,
      searchRaw: 'alp',
      pool: pool,
    );
    expect(out.length, 1);
    expect(out.single.title, 'Alpha');
  });
}
