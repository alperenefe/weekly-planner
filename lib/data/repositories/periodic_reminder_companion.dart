import 'package:drift/drift.dart';

final class PeriodicReminderCompanion {
  const PeriodicReminderCompanion({
    this.title = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.lastCompletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });

  final Value<String> title;
  final Value<int> intervalDays;
  final Value<String> nextDueDate;
  final Value<String?> lastCompletedAt;
  final Value<String> createdAt;
  final Value<String> updatedAt;

  factory PeriodicReminderCompanion.insert({
    required String title,
    required int intervalDays,
    required String nextDueDate,
    required String createdAt,
    required String updatedAt,
  }) {
    return PeriodicReminderCompanion(
      title: Value(title),
      intervalDays: Value(intervalDays),
      nextDueDate: Value(nextDueDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
