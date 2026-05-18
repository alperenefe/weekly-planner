import 'package:drift/drift.dart';

final class WeekTemplateTasksCompanion {
  const WeekTemplateTasksCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.title = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.notes = const Value.absent(),
    this.targetWeekday = const Value.absent(),
    this.orderIndex = const Value.absent(),
  });

  final Value<int> id;
  final Value<int> templateId;
  final Value<String> title;
  final Value<int?> durationMinutes;
  final Value<String?> notes;
  final Value<int?> targetWeekday;
  final Value<int> orderIndex;

  factory WeekTemplateTasksCompanion.insert({
    required int templateId,
    required String title,
    Value<int?> durationMinutes = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> targetWeekday = const Value.absent(),
    Value<int> orderIndex = const Value.absent(),
  }) {
    return WeekTemplateTasksCompanion(
      templateId: Value(templateId),
      title: Value(title),
      durationMinutes: durationMinutes,
      notes: notes,
      targetWeekday: targetWeekday,
      orderIndex: orderIndex,
    );
  }
}
