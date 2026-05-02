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

String trShortDate(DateTime d) {
  return '${d.day} ${_trMonthsShort[d.month - 1]} ${d.year}';
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
