import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../date/week_calendar.dart';
import '../../models/week_summary.dart';
import '../../plan_data_revision.dart';
import '../../plan_day_labels.dart';
import '../../services/summary_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/planner_top_bar.dart';
import '../../widgets/week_navigation_bar.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late String _weekStart;
  WeekSummary? _summary;
  bool _loading = true;
  PlanDataRevision? _planRevision;

  @override
  void initState() {
    super.initState();
    _weekStart = mondayIsoContaining(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final r = context.read<PlanDataRevision>();
      _planRevision = r;
      r.addListener(_onPlanDataChanged);
      _reload();
    });
  }

  @override
  void dispose() {
    _planRevision?.removeListener(_onPlanDataChanged);
    super.dispose();
  }

  void _onPlanDataChanged() {
    if (mounted) {
      _reload();
    }
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });
    final svc = context.read<SummaryService>();
    final s = await svc.weekSummary(_weekStart);
    if (!mounted) return;
    setState(() {
      _summary = s;
      _loading = false;
    });
  }

  void _shiftWeek(int deltaDays) {
    setState(() {
      _weekStart = addDaysIso(_weekStart, deltaDays);
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('summary_screen'),
      backgroundColor: DesignTokens.slate950,
      appBar: const PlannerTopBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WeekNavigationBar(
            label: 'Bu hafta: $_weekStart',
            onPrevious: () => _shiftWeek(-7),
            onNext: () => _shiftWeek(7),
          ),
          Expanded(
            child: _loading || _summary == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: DesignTokens.blue500,
                    ),
                  )
                : _SummaryBody(
                    summary: _summary!,
                    weekStart: _weekStart,
                  ),
          ),
        ],
      ),
    );
  }
}

String _fmtInt(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      out.write(',');
    }
    out.write(s[i]);
  }
  return out.toString();
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({
    required this.summary,
    required this.weekStart,
  });

  final WeekSummary summary;
  final String weekStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pctRounded = summary.completionPercent.round();
    final dayIsos = weekdayIsosFromMonday(weekStart);
    var maxDailyPlanned = 1;
    for (final iso in dayIsos) {
      maxDailyPlanned = math.max(
        maxDailyPlanned,
        summary.dailyBreakdown[iso]!.plannedMinutes,
      );
    }
    final doneFrac = summary.plannedMinutes == 0
        ? 0.0
        : (summary.completedMinutes / summary.plannedMinutes).clamp(0.0, 1.0);

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Haftalık Özet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.white,
                  fontSize: 20,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Performans analizi ve zaman dağılımı',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.slate400,
                  fontSize: 14,
                  height: 1.43,
                ),
              ),
              const SizedBox(height: 24),
              _HeroCard(summary: summary),
              const SizedBox(height: 12),
              _PlannedDoneCard(
                summary: summary,
                pctRounded: pctRounded,
                doneFrac: doneFrac,
              ),
              const SizedBox(height: 12),
              _DailyBreakdownCard(
                summary: summary,
                dayIsos: dayIsos,
                maxDailyPlanned: maxDailyPlanned,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary});

  final WeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: DesignTokens.slate900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DesignTokens.slate800),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'TAMAMLANAN SÜRE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontSize: 12,
                      height: 16 / 12,
                      color: DesignTokens.slate400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _fmtInt(summary.completedMinutes),
                        key: const Key('summary_completed_large'),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 30,
                          height: 38 / 30,
                          letterSpacing: -0.6,
                          color: DesignTokens.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'dk',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DesignTokens.slate400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Havuzda ${summary.poolMinutes} dk',
                    key: const Key('summary_pool_line'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DesignTokens.blue400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DesignTokens.blue600.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannedDoneCard extends StatelessWidget {
  const _PlannedDoneCard({
    required this.summary,
    required this.pctRounded,
    required this.doneFrac,
  });

  final WeekSummary summary;
  final int pctRounded;
  final double doneFrac;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.slate900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.slate800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PLANLANAN',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: DesignTokens.white,
                  ),
                ),
                Text(
                  '${_fmtInt(summary.plannedMinutes)} dk',
                  key: const Key('summary_planned_line'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: DesignTokens.slate400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: DesignTokens.slate800),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: 1,
                        child: ColoredBox(
                          color: Color(0xCC64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TAMAMLANAN',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: DesignTokens.white,
                  ),
                ),
                Text(
                  '${_fmtInt(summary.completedMinutes)} / ${_fmtInt(summary.plannedMinutes)} dk (%$pctRounded)',
                  key: const Key('summary_completion_badge'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: DesignTokens.slate400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: DesignTokens.slate800),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: doneFrac,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: DesignTokens.blue600,
                            boxShadow: [
                              BoxShadow(
                                color: DesignTokens.blue600
                                    .withValues(alpha: 0.45),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyBreakdownCard extends StatelessWidget {
  const _DailyBreakdownCard({
    required this.summary,
    required this.dayIsos,
    required this.maxDailyPlanned,
  });

  final WeekSummary summary;
  final List<String> dayIsos;
  final int maxDailyPlanned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.slate900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.slate800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Günlük dağılım',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: DesignTokens.white,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 12),
              child: Divider(
                height: 1,
                color: DesignTokens.slate800,
              ),
            ),
            for (var i = 0; i < dayIsos.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _DayBarRow(
                label: kPlanDayLabels[i + 1],
                iso: dayIsos[i],
                stats: summary.dailyBreakdown[dayIsos[i]]!,
                maxPlanned: maxDailyPlanned,
                weekend: i >= 5,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayBarRow extends StatelessWidget {
  const _DayBarRow({
    required this.label,
    required this.iso,
    required this.stats,
    required this.maxPlanned,
    required this.weekend,
  });

  final String label;
  final String iso;
  final DailyStats stats;
  final int maxPlanned;
  final bool weekend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dim = weekend && stats.plannedMinutes == 0;
    final labelColor =
        dim ? DesignTokens.slate500 : DesignTokens.slate400;
    final valueColor =
        dim ? DesignTokens.slate500 : DesignTokens.white;
    final barColor =
        stats.plannedMinutes == 0 ? DesignTokens.slate600 : DesignTokens.blue600;

    return Opacity(
      opacity: dim ? 0.6 : 1,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label.toUpperCase(),
              key: Key('summary_day_label_$iso'),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 12,
                color: labelColor,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final frac = maxPlanned > 0
                    ? (stats.plannedMinutes / maxPlanned).clamp(0.0, 1.0)
                    : 0.0;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        const ColoredBox(color: DesignTokens.slate800),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: w * frac,
                            height: 6,
                            color: barColor.withValues(
                              alpha: stats.plannedMinutes == 0 ? 0.5 : 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${stats.plannedMinutes} dk',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
