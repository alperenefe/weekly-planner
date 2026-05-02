class DailyStats {
  const DailyStats({
    required this.plannedMinutes,
    required this.completedMinutes,
  });

  final int plannedMinutes;
  final int completedMinutes;
}

class WeekSummary {
  const WeekSummary({
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.poolMinutes,
    required this.completionPercent,
    required this.dailyBreakdown,
  });

  final int plannedMinutes;
  final int completedMinutes;
  final int poolMinutes;
  final double completionPercent;
  final Map<String, DailyStats> dailyBreakdown;
}
