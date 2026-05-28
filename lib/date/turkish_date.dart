import 'week_calendar.dart';

const _trMonthsShort = <String>[
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

const _trMonthsLong = <String>[
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String yyyyMmFromDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  return '$y-$m';
}

String addMonthsYyyyMm(String yyyyMm, int deltaMonths) {
  final parts = yyyyMm.split('-');
  var y = int.parse(parts[0], radix: 10);
  var mo = int.parse(parts[1], radix: 10);
  mo += deltaMonths;
  while (mo > 12) {
    mo -= 12;
    y++;
  }
  while (mo < 1) {
    mo += 12;
    y--;
  }
  return '${y.toString().padLeft(4, '0')}-${mo.toString().padLeft(2, '0')}';
}

String trMonthYearFromYyyyMm(String yyyyMm) {
  final parts = yyyyMm.split('-');
  final y = int.parse(parts[0], radix: 10);
  final m = int.parse(parts[1], radix: 10);
  return '${_trMonthsLong[m - 1]} $y';
}

String trShortDate(DateTime d) {
  return '${d.day} ${_trMonthsShort[d.month - 1]} ${d.year}';
}

/// Sütun alt satırı: "19 May"
String trDayMonthShort(DateTime d) {
  return '${d.day} ${_trMonthsShort[d.month - 1]}';
}

/// Plan / özet üst çubuğu: "19–25 Mayıs 2026"
String trWeekNavigationLabel(String mondayIso) {
  final mon = parseIsoDate(mondayIso);
  final sun = mon.add(const Duration(days: 6));
  if (mon.year == sun.year && mon.month == sun.month) {
    return '${mon.day}–${sun.day} ${_trMonthsLong[sun.month - 1]} ${sun.year}';
  }
  if (mon.year == sun.year) {
    return '${mon.day} ${_trMonthsShort[mon.month - 1]} – '
        '${sun.day} ${_trMonthsLong[sun.month - 1]} ${sun.year}';
  }
  return '${mon.day} ${_trMonthsLong[mon.month - 1]} ${mon.year} – '
      '${sun.day} ${_trMonthsLong[sun.month - 1]} ${sun.year}';
}

String trWeekRangeFromMonday(String mondayIso) {
  final mon = parseIsoDate(mondayIso);
  final sun = mon.add(const Duration(days: 6));
  if (mon.year == sun.year) {
    return '${mon.day} ${_trMonthsShort[mon.month - 1]} – ${sun.day} ${_trMonthsShort[sun.month - 1]} ${sun.year}';
  }
  return '${trShortDate(mon)} – ${trShortDate(sun)}';
}

String trDayWithWeekday(String weekdayLabel, String isoDate) {
  final d = parseIsoDate(isoDate);
  return '$weekdayLabel (${d.day} ${_trMonthsShort[d.month - 1]})';
}
