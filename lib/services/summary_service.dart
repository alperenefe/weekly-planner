import '../data/db/app_database.dart';
import '../data/repositories/task_repository.dart';
import '../date/week_calendar.dart';
import '../models/week_summary.dart';

class SummaryService {
  SummaryService(this._taskRepository);

  final TaskRepository _taskRepository;

  int _durationMinutesOrZero(Task task) {
    return task.durationMinutes ?? 0;
  }

  Future<WeekSummary> weekSummary(String weekStart) async {
    final tasks = await _taskRepository.getTasksForWeek(weekStart);

    var plannedMinutes = 0;
    var completedMinutes = 0;
    var poolMinutes = 0;

    for (final t in tasks) {
      final d = _durationMinutesOrZero(t);
      plannedMinutes += d;
      if (t.status == 'done') {
        completedMinutes += d;
      }
      if (t.plannedDate == null) {
        poolMinutes += d;
      }
    }

    final dayIsos = weekdayIsosFromMonday(weekStart);
    final dailyBreakdown = <String, DailyStats>{
      for (final iso in dayIsos)
        iso: const DailyStats(plannedMinutes: 0, completedMinutes: 0),
    };

    for (final t in tasks) {
      final pd = t.plannedDate;
      if (pd == null || !dailyBreakdown.containsKey(pd)) {
        continue;
      }
      final d = _durationMinutesOrZero(t);
      final cur = dailyBreakdown[pd]!;
      dailyBreakdown[pd] = DailyStats(
        plannedMinutes: cur.plannedMinutes + d,
        completedMinutes:
            cur.completedMinutes + (t.status == 'done' ? d : 0),
      );
    }

    final completionPercent = plannedMinutes == 0
        ? 0.0
        : (completedMinutes / plannedMinutes) * 100.0;

    return WeekSummary(
      plannedMinutes: plannedMinutes,
      completedMinutes: completedMinutes,
      poolMinutes: poolMinutes,
      completionPercent: completionPercent,
      dailyBreakdown: dailyBreakdown,
    );
  }
}
