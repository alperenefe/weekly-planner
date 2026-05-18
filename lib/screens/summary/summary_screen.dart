import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/monthly_goal_repository.dart';
import '../../date/turkish_date.dart';
import '../../date/week_calendar.dart';
import '../../models/monthly_goal.dart';
import '../../models/summary_analysis.dart';
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
  List<WeekTrendItem>? _trend;
  MonthSummary? _monthSummary;
  String _monthYyyyMm = '';
  PostponeAnalysis? _postpone;
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
    final goalRepo = context.read<MonthlyGoalRepository>();
    final week = _weekStart;
    final currentMonth = yyyyMmFromDate(parseIsoDate(week));
    final results = await Future.wait<Object>([
      svc.weekSummary(week),
      svc.weekTrend(week),
      goalRepo.getMonthSummary(currentMonth),
      svc.postponeAnalysis(week),
    ]);
    if (!mounted) return;
    setState(() {
      _summary = results[0] as WeekSummary;
      _trend = results[1] as List<WeekTrendItem>;
      _monthSummary = results[2] as MonthSummary;
      _monthYyyyMm = currentMonth;
      _postpone = results[3] as PostponeAnalysis;
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
            child: _loading ||
                    _summary == null ||
                    _trend == null ||
                    _monthSummary == null ||
                    _postpone == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: DesignTokens.blue500,
                    ),
                  )
                : _SummaryBody(
                    summary: _summary!,
                    weekStart: _weekStart,
                    trend: _trend!,
                    monthSummary: _monthSummary!,
                    monthYyyyMm: _monthYyyyMm,
                    postpone: _postpone!,
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
    required this.trend,
    required this.monthSummary,
    required this.monthYyyyMm,
    required this.postpone,
  });

  final WeekSummary summary;
  final String weekStart;
  final List<WeekTrendItem> trend;
  final MonthSummary monthSummary;
  final String monthYyyyMm;
  final PostponeAnalysis postpone;

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
              _StatGridCard(summary: summary),
              const SizedBox(height: 12),
              _PlannedDoneCard(
                summary: summary,
                pctRounded: pctRounded,
                doneFrac: doneFrac,
              ),
              const SizedBox(height: 12),
              _WeekTrendCard(trend: trend),
              const SizedBox(height: 12),
              _DailyBreakdownCard(
                summary: summary,
                dayIsos: dayIsos,
                maxDailyPlanned: maxDailyPlanned,
              ),
              const SizedBox(height: 12),
              _MonthlyGoalsCard(
                monthSummary: monthSummary,
                monthYyyyMm: monthYyyyMm,
              ),
              const SizedBox(height: 12),
              _PostponeAnalysisCard(analysis: postpone),
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

class _StatGridCard extends StatelessWidget {
  const _StatGridCard({required this.summary});

  final WeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell({
      required int value,
      required String label,
      required IconData icon,
      required Color iconColor,
      Key? valueKey,
    }) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: DesignTokens.slate900,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DesignTokens.slate800),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    key: valueKey,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      height: 1.1,
                      color: DesignTokens.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: DesignTokens.slate400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.slate900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.slate800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.45,
              children: [
                cell(
                  value: summary.completedTasks,
                  label: 'Tamamlanan',
                  icon: Icons.check_circle_outline,
                  iconColor: DesignTokens.green500,
                  valueKey: const Key('summary_stat_completed'),
                ),
                cell(
                  value: summary.skippedTasks,
                  label: 'Atlanan',
                  icon: Icons.close,
                  iconColor: DesignTokens.amber500,
                ),
                cell(
                  value: summary.movedTasks,
                  label: 'Taşınan',
                  icon: Icons.sync,
                  iconColor: DesignTokens.blue400,
                ),
                cell(
                  value: summary.poolRemainingTasks,
                  label: 'Havuzda Kalan',
                  icon: Icons.inbox_outlined,
                  iconColor: DesignTokens.slate400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekTrendCard extends StatelessWidget {
  const _WeekTrendCard({required this.trend});

  final List<WeekTrendItem> trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const Key('summary_week_trend_card'),
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
              'Son 4 Hafta',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: DesignTokens.white,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < trend.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _TrendRow(
                item: trend[i],
                accent: i == 0,
                rowKey: Key('summary_trend_row_$i'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.item,
    required this.accent,
    required this.rowKey,
  });

  final WeekTrendItem item;
  final bool accent;
  final Key rowKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = accent ? DesignTokens.blue400 : DesignTokens.slate400;
    final pct = item.completionPercent.clamp(0.0, 100.0);
    final frac = pct / 100.0;
    final pctText = '%${pct.round()}';
    return Row(
      key: rowKey,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            item.weekLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: labelColor,
              fontWeight: accent ? FontWeight.w600 : null,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: DesignTokens.slate800),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: frac,
                      child: const ColoredBox(color: DesignTokens.blue600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            pctText,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: DesignTokens.slate400,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthlyGoalsCard extends StatelessWidget {
  const _MonthlyGoalsCard({
    required this.monthSummary,
    required this.monthYyyyMm,
  });

  final MonthSummary monthSummary;
  final String monthYyyyMm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleMonth = trMonthYearFromYyyyMm(monthYyyyMm);
    final total = monthSummary.totalGoals;
    final done = monthSummary.doneGoals;
    final frac = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/goals'),
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
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
                  children: [
                    Text(
                      'Aylık Hedefler',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: DesignTokens.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      titleMonth,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: DesignTokens.slate500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (total == 0)
                  Text(
                    'Bu ay henüz hedef yok',
                    key: const Key('summary_monthly_empty'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DesignTokens.slate500,
                    ),
                  )
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: SizedBox(
                      height: 10,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: DesignTokens.slate800),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: frac,
                              child: const ColoredBox(color: DesignTokens.blue600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$done / $total tamamlandı',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DesignTokens.slate500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostponeAnalysisCard extends StatelessWidget {
  const _PostponeAnalysisCard({required this.analysis});

  final PostponeAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMoved = analysis.mostMovedTasks.isNotEmpty;
    final avg = analysis.avgMovesPerMovedTask;
    String? insight;
    if (avg >= 2.0) {
      insight = 'Bu görevler planlamayı zorluyor olabilir.';
    } else if (hasMoved) {
      insight = 'Bazı görevler birden fazla güne taşındı.';
    }

    Color statusDot(String status) {
      switch (status) {
        case 'done':
          return DesignTokens.green500;
        case 'skipped':
          return const Color(0xFFEF4444);
        default:
          return DesignTokens.slate500;
      }
    }

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
              'Erteleme Analizi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: DesignTokens.white,
              ),
            ),
            const SizedBox(height: 12),
            if (!hasMoved)
              Text(
                'Bu hafta hiç görev ertelenmedi 🎯',
                key: const Key('summary_postpone_empty'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.green500,
                  fontWeight: FontWeight.w500,
                ),
              )
            else ...[
              Text(
                '✓ ${analysis.neverMovedCompleted} görev hiç ertelenmeden tamamlandı',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DesignTokens.green500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '↷ Ortalama ${avg.toStringAsFixed(1)} erteleme / taşınan görev',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DesignTokens.slate500,
                  fontSize: 12,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: DesignTokens.slate800),
              ),
              Text(
                'En çok ertelenen görevler:',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: DesignTokens.slate500,
                ),
              ),
              const SizedBox(height: 8),
              for (final t in analysis.mostMovedTasks) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusDot(t.status),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: DesignTokens.slate200,
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0x4D78350F),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            '${t.movedCount}×',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFFBBF24),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            if (insight != null) ...[
              const SizedBox(height: 8),
              Text(
                insight,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: DesignTokens.slate500,
                ),
              ),
            ],
          ],
        ),
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
