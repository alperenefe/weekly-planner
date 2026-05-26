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
import 'summary_hero_copy.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/planner_top_bar.dart';
import '../../widgets/week_navigation_bar.dart';

part 'summary_screen_widgets.dart';

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
