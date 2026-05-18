class MonthlyGoal {
  const MonthlyGoal({
    required this.id,
    required this.title,
    required this.month,
    required this.orderIndex,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String month;
  final int orderIndex;
  final String status;
  final String createdAt;
  final String updatedAt;
}

class MonthSummary {
  const MonthSummary({
    required this.totalGoals,
    required this.doneGoals,
  });

  final int totalGoals;
  final int doneGoals;
}
