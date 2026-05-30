import '../models/periodic_reminder.dart';
import 'turkish_date.dart';
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

DateTime? parseCompletedAtLocal(String? isoUtc) {
  if (isoUtc == null || isoUtc.trim().isEmpty) return null;
  return DateTime.tryParse(isoUtc)?.toLocal();
}

/// Liste satırı: «Son: 28 May 2026» veya null → henüz yok.
String? formatLastCompletedLabel(String? lastCompletedAtIso) {
  final local = parseCompletedAtLocal(lastCompletedAtIso);
  if (local == null) return null;
  return trShortDate(local);
}

String formatCompletedAtLabel(String completedAtIso) {
  final local = parseCompletedAtLocal(completedAtIso);
  if (local == null) return completedAtIso;
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '${trShortDate(local)} · $h:$m';
}
