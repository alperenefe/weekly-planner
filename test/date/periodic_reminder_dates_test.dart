import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/date/periodic_reminder_dates.dart';
import 'package:weekly_planner/date/turkish_date.dart';
import 'package:weekly_planner/date/week_calendar.dart';

void main() {
  group('periodic_reminder_dates', () {
    final ref = DateTime(2026, 5, 30);

    test('daysUntilDue positive', () {
      expect(
        daysUntilDue('2026-06-13', reference: ref),
        14,
      );
    });

    test('daysUntilDue zero for today', () {
      expect(
        daysUntilDue('2026-05-30', reference: ref),
        0,
      );
    });

    test('daysUntilDue negative when overdue', () {
      expect(
        daysUntilDue('2026-05-27', reference: ref),
        -3,
      );
    });

    test('formatDaysRemaining', () {
      expect(formatDaysRemaining(14), '14 gün kaldı');
      expect(formatDaysRemaining(1), '1 gün kaldı');
      expect(formatDaysRemaining(0), 'Bugün');
      expect(formatDaysRemaining(-3), '3 gün geçti');
    });

    test('nextDueAfterInterval', () {
      expect(
        nextDueAfterInterval(14, reference: ref),
        addDaysIso(toIsoDate(ref), 14),
      );
    });

    test('formatIntervalLabel preset and custom', () {
      expect(formatIntervalLabel(14), '2 hafta');
      expect(formatIntervalLabel(45), '45 gün');
    });

    test('formatLastCompletedLabel', () {
      final iso = DateTime(2026, 5, 28, 14, 30).toUtc().toIso8601String();
      expect(formatLastCompletedLabel(iso), trShortDate(DateTime(2026, 5, 28)));
      expect(formatLastCompletedLabel(null), isNull);
    });
  });
}
