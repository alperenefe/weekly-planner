import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/date/turkish_date.dart';

void main() {
  test('trWeekNavigationLabel same month uses long month name', () {
    expect(
      trWeekNavigationLabel('2026-05-19'),
      '19–25 Mayıs 2026',
    );
  });

  test('trDayMonthShort formats day and short month', () {
    expect(
      trDayMonthShort(DateTime(2026, 5, 19)),
      '19 May',
    );
  });
}
