import 'package:drift/drift.dart';

final class MonthlyGoalsCompanion {
  const MonthlyGoalsCompanion({
    this.title = const Value.absent(),
    this.month = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });

  final Value<String> title;
  final Value<String> month;
  final Value<String> status;
  final Value<String> createdAt;
  final Value<String> updatedAt;

  factory MonthlyGoalsCompanion.insert({
    required String title,
    required String month,
    Value<String> status = const Value.absent(),
    required String createdAt,
    required String updatedAt,
  }) {
    return MonthlyGoalsCompanion(
      title: Value(title),
      month: Value(month),
      status: status,
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
