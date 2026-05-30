class PeriodicReminder {
  const PeriodicReminder({
    required this.id,
    required this.title,
    required this.intervalDays,
    required this.nextDueDate,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    this.lastCompletedAt,
  });

  final int id;
  final String title;
  final int intervalDays;
  /// Yerel takvim günü `YYYY-MM-DD`.
  final String nextDueDate;
  final int orderIndex;
  final String createdAt;
  final String updatedAt;
  final String? lastCompletedAt;
}

/// Önceden tanımlı periyot seçenekleri (gün).
class PeriodicReminderIntervals {
  const PeriodicReminderIntervals._();

  static const List<({String label, int days})> presets = [
    (label: '1 hafta', days: 7),
    (label: '2 hafta', days: 14),
    (label: '1 ay', days: 30),
    (label: '3 ay', days: 90),
    (label: '6 ay', days: 180),
  ];
}
