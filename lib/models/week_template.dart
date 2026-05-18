class WeekTemplate {
  const WeekTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    this.taskCount = 0,
  });

  final int id;
  final String name;
  final String createdAt;
  final int taskCount;
}

class WeekTemplateTask {
  const WeekTemplateTask({
    required this.id,
    required this.templateId,
    required this.title,
    this.durationMinutes,
    this.notes,
    this.targetWeekday,
    required this.orderIndex,
  });

  final int id;
  final int templateId;
  final String title;
  final int? durationMinutes;
  final String? notes;
  final int? targetWeekday;
  final int orderIndex;
}

class WeekTemplateDetail {
  const WeekTemplateDetail({
    required this.template,
    required this.tasks,
  });

  final WeekTemplate template;
  final List<WeekTemplateTask> tasks;
}
