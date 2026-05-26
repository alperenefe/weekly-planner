import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/date/week_calendar.dart';

void main() {
  group('chipIndexForPlannedDate', () {
    const monday = '2025-01-13';

    test('null planned_date → 0 (havuz)', () {
      expect(chipIndexForPlannedDate(monday, null), 0);
    });

    test('Tuesday in week → 2', () {
      expect(chipIndexForPlannedDate(monday, '2025-01-14'), 2);
    });

    test('date outside week → -1', () {
      expect(chipIndexForPlannedDate(monday, '2025-01-20'), -1);
    });
  });

  group('dayChipIndexForUi', () {
    const monday = '2025-01-13';

    test('outside week maps to 0 for chips', () {
      expect(dayChipIndexForUi(monday, '2025-01-20'), 0);
    });
  });

  group('isPlannedDateInWeek', () {
    const monday = '2025-01-13';

    test('in week', () {
      expect(isPlannedDateInWeek(monday, '2025-01-15'), isTrue);
    });

    test('outside week', () {
      expect(isPlannedDateInWeek(monday, '2025-02-01'), isFalse);
    });
  });
}
