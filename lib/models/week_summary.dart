class DailyStats {
  const DailyStats({
    required this.plannedMinutes,
    required this.completedMinutes,
  });

  final int plannedMinutes;
  final int completedMinutes;
}

class WeekTrendItem {
  const WeekTrendItem({
    required this.weekStart,
    required this.completionPercent,
    required this.weekLabel,
  });

  final String weekStart;
  final double completionPercent;
  final String weekLabel;
}

class WeekSummary {
  const WeekSummary({
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.poolMinutes,
    required this.completionPercent,
    required this.dailyBreakdown,
    required this.totalTasks,
    required this.completedTasks,
    required this.skippedTasks,
    required this.movedTasks,
    required this.poolRemainingTasks,
  });

  final int plannedMinutes;
  final int completedMinutes;
  final int poolMinutes;
  final double completionPercent;
  final Map<String, DailyStats> dailyBreakdown;

  final int totalTasks;
  final int completedTasks;
  final int skippedTasks;
  final int movedTasks;
  final int poolRemainingTasks;
}
