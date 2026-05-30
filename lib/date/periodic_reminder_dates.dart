import '../models/periodic_reminder.dart';
import 'week_calendar.dart';

/// Bugünün yerel ISO tarihi (`YYYY-MM-DD`).
String todayIsoDate({DateTime? reference}) {
  final ref = reference ?? DateTime.now();
  return toIsoDate(DateTime(ref.year, ref.month, ref.day));
}

/// `nextDueDate` ile bugün arasındaki gün farkı (negatif = geçmiş).
int daysUntilDue(String nextDueIso, {DateTime? reference}) {
  final ref = reference ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final due = parseIsoDate(nextDueIso);
  return due.difference(today).inDays;
}

String formatDaysRemaining(int daysLeft) {
  if (daysLeft > 1) return '$daysLeft gün kaldı';
  if (daysLeft == 1) return '1 gün kaldı';
  if (daysLeft == 0) return 'Bugün';
  final overdue = -daysLeft;
  if (overdue == 1) return '1 gün geçti';
  return '$overdue gün geçti';
}

String nextDueAfterInterval(int intervalDays, {DateTime? reference}) {
  return addDaysIso(todayIsoDate(reference: reference), intervalDays);
}

String formatIntervalLabel(int days) {
  for (final p in PeriodicReminderIntervals.presets) {
    if (p.days == days) return p.label;
  }
  return '$days gün';
}
