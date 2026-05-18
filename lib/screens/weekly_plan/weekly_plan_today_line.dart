import '../../data/db/app_database.dart';
import '../../date/week_calendar.dart';

String weeklyPlanTodaySummaryLine({
  required String weekStart,
  required List<List<Task>> dayTasks,
}) {
  final today = toIsoDate(DateTime.now());
  final isos = weekdayIsosFromMonday(weekStart);
  final idx = isos.indexOf(today);
  if (idx < 0) {
    return 'Bu hafta takvimde değil';
  }
  final list = dayTasks[idx];
  var mins = 0;
  for (final t in list) {
    mins += t.durationMinutes ?? 0;
  }
  return 'Bugün ${list.length} etkinliğin var · $mins dk';
}
