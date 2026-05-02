import 'dart:convert';

import '../data/db/app_database.dart';
import '../data/repositories/task_repository.dart';
import '../date/turkish_date.dart';
import '../date/week_calendar.dart';
import '../plan_day_labels.dart';
import 'summary_service.dart';

class ExportService {
  ExportService(this._taskRepository, this._summaryService);

  final TaskRepository _taskRepository;
  final SummaryService _summaryService;

  Future<String> exportJson(String weekStart) async {
    final tasks = await _taskRepository.getTasksForWeek(weekStart);
    final exportedAt = DateTime.now().toUtc().toIso8601String();
    final taskMaps = <Map<String, dynamic>>[];
    for (final t in tasks) {
      final histories = await _taskRepository.getTaskHistoriesForTask(t.id);
      taskMaps.add({
        'id': t.id,
        'title': t.title,
        'status': t.status,
        'plannedDate': t.plannedDate,
        'durationMinutes': t.durationMinutes,
        'startMinutes': t.startMinutes,
        'movedCount': t.movedCount,
        'notes': t.notes,
        'history': histories
            .map(
              (h) => {
                'eventType': h.eventType,
                'timestamp': h.timestamp,
                'fromDate': h.fromDate,
                'toDate': h.toDate,
              },
            )
            .toList(),
      });
    }
    return const JsonEncoder.withIndent('  ').convert({
      'weekStart': weekStart,
      'exportedAt': exportedAt,
      'tasks': taskMaps,
    });
  }

  Future<String> exportLlmText(String weekStart) async {
    final summary = await _summaryService.weekSummary(weekStart);
    final tasks = await _taskRepository.getTasksForWeek(weekStart);
    final isos = weekdayIsosFromMonday(weekStart);
    final pct = summary.plannedMinutes == 0
        ? 0
        : (summary.completionPercent.round());

    final buf = StringBuffer();
    buf.writeln('Hafta: ${trWeekRangeFromMonday(weekStart)}');
    buf.writeln(
      'Tamamlanan: ${summary.completedMinutes} dk / ${summary.plannedMinutes} dk (%$pct)',
    );
    buf.writeln('Havuz: ${summary.poolMinutes} dk');
    buf.writeln();
    buf.writeln('Günler:');
    for (var i = 0; i < 7; i++) {
      final iso = isos[i];
      final label = kPlanDayLabels[i + 1];
      final dayTasks = tasks.where((t) => t.plannedDate == iso).toList();
      final doneTasks = dayTasks.where((t) => t.status == 'done').toList();
      var doneM = 0;
      for (final t in doneTasks) {
        doneM += t.durationMinutes ?? 0;
      }
      buf.writeln(
        '${trDayWithWeekday(label, iso)}: ${doneTasks.length} etkinlik, $doneM dk tamamlandı',
      );
    }
    buf.writeln();
    buf.writeln('Etkinlikler:');
    final ordered = _orderedTasksForExport(tasks, isos);
    for (final t in ordered) {
      final tag = t.plannedDate == null ? 'pool' : t.status;
      final dur = t.durationMinutes ?? 0;
      buf.writeln('- [$tag] ${t.title} ($dur dk, ${t.movedCount} taşıma)');
    }
    return buf.toString();
  }

  List<Task> _orderedTasksForExport(List<Task> tasks, List<String> dayIsos) {
    final out = <Task>[];
    for (final iso in dayIsos) {
      final day = tasks.where((t) => t.plannedDate == iso).toList()
        ..sort(compareTasksPlannedDayOrder);
      out.addAll(day);
    }
    final pool = tasks.where((t) => t.plannedDate == null).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    out.addAll(pool);
    return out;
  }
}
