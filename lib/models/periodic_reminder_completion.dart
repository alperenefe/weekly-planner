class PeriodicReminderCompletion {
  const PeriodicReminderCompletion({
    required this.id,
    required this.reminderId,
    required this.completedAt,
    this.previousNextDueDate,
  });

  final int id;
  final int reminderId;
  final String completedAt;
  /// `markCompleted` öncesi `next_due_date` (yanlış «Yaptım» geri alma).
  final String? previousNextDueDate;
}
