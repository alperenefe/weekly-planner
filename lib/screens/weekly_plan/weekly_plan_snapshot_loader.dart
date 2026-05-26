import '../../data/db/app_database.dart';
import '../../data/repositories/task_repository.dart';
import '../../date/week_calendar.dart';
import '../../services/week_service.dart';

class WeeklyPlanBoardSnapshot {
  WeeklyPlanBoardSnapshot({
    required this.poolTasks,
    required List<List<Task>> dayTasksByIndex,
    required this.copyFromPreviousApplied,
  }) : dayTasksByIndex = List.unmodifiable(dayTasksByIndex);

  final List<Task> poolTasks;
  final List<List<Task>> dayTasksByIndex;
  final bool copyFromPreviousApplied;
}

Future<WeeklyPlanBoardSnapshot> loadWeeklyPlanBoardSnapshot({
  required String weekStart,
  required WeekService weekService,
  required TaskRepository repo,
}) async {
  await weekService.ensureWeekTasks(weekStart);
  final pool = await repo.getPoolTasks(weekStart);
  final orphans = await repo.getOrphanPlannedTasks(weekStart);
  final poolMerged = [...pool, ...orphans];
  final copyApplied = await repo.isCopyFromPreviousApplied(weekStart);
  final dayIsos = weekdayIsosFromMonday(weekStart);
  final days = <List<Task>>[];
  for (final iso in dayIsos) {
    days.add(await repo.getDayTasks(weekStart, iso));
  }
  return WeeklyPlanBoardSnapshot(
    poolTasks: poolMerged,
    dayTasksByIndex: days,
    copyFromPreviousApplied: copyApplied,
  );
}
