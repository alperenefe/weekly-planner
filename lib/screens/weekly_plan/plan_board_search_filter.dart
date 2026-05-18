import '../../config/planner_feature_flags.dart';
import '../../data/db/app_database.dart';

class PlanBoardSearchFilter {
  PlanBoardSearchFilter._();

  static List<Task> poolColumn({
    required PlannerFeatureFlags flags,
    required bool isSearching,
    required String searchRaw,
    required List<Task> pool,
  }) {
    if (!flags.planBoardSearchEnabled || !isSearching) return pool;
    final q = searchRaw.trim().toLowerCase();
    if (q.isEmpty) return pool;
    return pool.where((t) => t.title.toLowerCase().contains(q)).toList();
  }

  static List<List<Task>> dayColumns({
    required PlannerFeatureFlags flags,
    required bool isSearching,
    required String searchRaw,
    required List<List<Task>> dayTasks,
  }) {
    if (!flags.planBoardSearchEnabled || !isSearching) return dayTasks;
    final q = searchRaw.trim().toLowerCase();
    if (q.isEmpty) return dayTasks;
    return List.generate(
      7,
      (i) => dayTasks[i]
          .where((t) => t.title.toLowerCase().contains(q))
          .toList(),
    );
  }
}
