import 'package:flutter/material.dart';

import '../../date/week_calendar.dart';
import '../../plan_day_labels.dart';
import '../../theme/design_tokens.dart';

/// Hafta tahtasında bugünü vurgulayan yatay gün şeridi.
class WeeklyPlanTodayPillStrip extends StatelessWidget {
  const WeeklyPlanTodayPillStrip({
    super.key,
    required this.weekStart,
    required this.onDaySelected,
  });

  final String weekStart;
  final void Function(int dayIndex) onDaySelected;

  @override
  Widget build(BuildContext context) {
    final today = toIsoDate(DateTime.now());
    final isos = weekdayIsosFromMonday(weekStart);
    final todayIdx = isos.indexOf(today);

    return SingleChildScrollView(
      key: const Key('weekly_plan_today_pill_strip'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          for (var i = 1; i < kPlanDayLabels.length; i++) ...[
            if (i > 1) const SizedBox(width: 8),
            _DayPill(
              label: kPlanDayLabels[i],
              isToday: todayIdx >= 0 && i - 1 == todayIdx,
              onTap: () => onDaySelected(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.isToday,
    required this.onTap,
  });

  final String label;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isToday
          ? DesignTokens.blue600.withValues(alpha: 0.25)
          : DesignTokens.slate900,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        key: Key('weekly_plan_day_pill_$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isToday ? DesignTokens.blue500 : DesignTokens.slate800,
            ),
          ),
          child: Text(
            isToday ? 'Bugün · $label' : label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isToday ? DesignTokens.blue400 : DesignTokens.slate400,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
