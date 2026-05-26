String mondayIsoContaining(DateTime instant) {
  final local = DateTime(instant.year, instant.month, instant.day);
  final monday = local.subtract(Duration(days: local.weekday - DateTime.monday));
  return toIsoDate(monday);
}

String toIsoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime parseIsoDate(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) {
    throw FormatException('Invalid ISO date: $iso');
  }
  return DateTime(
    int.parse(parts[0], radix: 10),
    int.parse(parts[1], radix: 10),
    int.parse(parts[2], radix: 10),
  );
}

String addDaysIso(String mondayIso, int days) {
  final base = parseIsoDate(mondayIso);
  return toIsoDate(base.add(Duration(days: days)));
}

String? plannedDateForChipIndex(String weekMondayIso, int chipIndex) {
  if (chipIndex <= 0) return null;
  return addDaysIso(weekMondayIso, chipIndex - 1);
}

/// `planned_date` bu haftanın Pazartesi–Pazar aralığında mı?
bool isPlannedDateInWeek(String weekMondayIso, String? plannedDate) {
  if (plannedDate == null || plannedDate.isEmpty) return false;
  return weekdayIsosFromMonday(weekMondayIso).contains(plannedDate);
}

/// 0 = havuz, 1–7 = gün; **-1** = planlı tarih var ama bu hafta dışında.
int chipIndexForPlannedDate(String weekMondayIso, String? plannedDate) {
  if (plannedDate == null) return 0;
  final isos = weekdayIsosFromMonday(weekMondayIso);
  final i = isos.indexOf(plannedDate);
  if (i < 0) return -1;
  return i + 1;
}

/// Düzenleme sheet chip’leri: hafta dışı tarih havuz (0) olarak gösterilir.
int dayChipIndexForUi(String weekMondayIso, String? plannedDate) {
  final idx = chipIndexForPlannedDate(weekMondayIso, plannedDate);
  return idx < 0 ? 0 : idx;
}

List<String> weekdayIsosFromMonday(String mondayIso) {
  return List.generate(7, (i) => addDaysIso(mondayIso, i));
}

String tomorrowIsoForMove({String? plannedDate}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (plannedDate != null && plannedDate.isNotEmpty) {
    return addDaysIso(plannedDate, 1);
  }
  return toIsoDate(today.add(const Duration(days: 1)));
}

String mapPlannedDateToNewWeek(
  String oldPlannedIso,
  String oldWeekMondayIso,
  String newWeekMondayIso,
) {
  final offset =
      parseIsoDate(oldPlannedIso).difference(parseIsoDate(oldWeekMondayIso)).inDays;
  return addDaysIso(newWeekMondayIso, offset);
}

String formatClockMinutes(int totalMinutes) {
  final m = totalMinutes.clamp(0, 1439);
  final h = m ~/ 60;
  final min = m % 60;
  return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}

int startMinutesFromQuarterIndex(int quarter) {
  return (quarter.clamp(0, 95) * 15).clamp(0, 1425);
}

int quarterIndexFromStartMinutes(int? minutes, {int defaultQuarter = 36}) {
  if (minutes == null) return defaultQuarter;
  return ((minutes.clamp(0, 1439)) / 15).round().clamp(0, 95);
}

int snappedStartMinutesFromWallClock({required int hour, required int minute}) {
  final total = hour.clamp(0, 23) * 60 + minute.clamp(0, 59);
  return startMinutesFromQuarterIndex(quarterIndexFromStartMinutes(total));
}
