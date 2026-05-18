import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/monthly_goal_repository.dart';
import '../../data/repositories/monthly_goals_companion.dart';
import '../../date/turkish_date.dart';
import '../../date/week_calendar.dart';
import '../../models/monthly_goal.dart';
import '../../plan_day_labels.dart';
import '../../plan_data_revision.dart';
import '../../services/monthly_goal_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/planner_top_bar.dart';

class MonthlyGoalsScreen extends StatefulWidget {
  const MonthlyGoalsScreen({super.key});

  @override
  State<MonthlyGoalsScreen> createState() => _MonthlyGoalsScreenState();
}

class _MonthlyGoalsScreenState extends State<MonthlyGoalsScreen> {
  late String _monthYyyyMm;
  List<MonthlyGoal> _goals = [];
  MonthSummary _summary = const MonthSummary(totalGoals: 0, doneGoals: 0);
  bool _loading = true;
  bool _showAddRow = false;
  final TextEditingController _newGoalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _monthYyyyMm = yyyyMmFromDate(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _newGoalController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final repo = context.read<MonthlyGoalRepository>();
    final goals = await repo.getGoalsForMonth(_monthYyyyMm);
    final summary = await repo.getMonthSummary(_monthYyyyMm);
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _summary = summary;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _monthYyyyMm = addMonthsYyyyMm(_monthYyyyMm, delta);
      _showAddRow = false;
      _newGoalController.clear();
    });
    unawaited(_reload());
  }

  Future<void> _submitNewGoal() async {
    final title = _newGoalController.text.trim();
    if (title.isEmpty) return;
    final repo = context.read<MonthlyGoalRepository>();
    final now = DateTime.now().toUtc().toIso8601String();
    await repo.insertGoal(
      MonthlyGoalsCompanion.insert(
        title: title,
        month: _monthYyyyMm,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (!mounted) return;
    _newGoalController.clear();
    setState(() => _showAddRow = false);
    await _reload();
  }

  Future<void> _toggleDone(MonthlyGoal g) async {
    final repo = context.read<MonthlyGoalRepository>();
    if (g.status == 'done') {
      await repo.markGoalActive(g.id);
    } else {
      await repo.markGoalDone(g.id);
    }
    if (mounted) await _reload();
  }

  Future<void> _openAddToWeekSheet(MonthlyGoal goal) async {
    final weekStart = mondayIsoContaining(DateTime.now());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _AddGoalToWeekSheetBody(
          parentContext: context,
          goal: goal,
          weekStart: weekStart,
          sheetContext: sheetContext,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('monthly_goals_screen'),
      backgroundColor: DesignTokens.slate950,
      appBar: const PlannerTopBar(title: 'Aylık hedefler'),
      floatingActionButton: FloatingActionButton(
        key: const Key('monthly_goals_fab'),
        onPressed: () {
          setState(() => _showAddRow = !_showAddRow);
        },
        backgroundColor: DesignTokens.blue600,
        foregroundColor: DesignTokens.white,
        child: Icon(_showAddRow ? Icons.close : Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                IconButton(
                  key: const Key('monthly_goals_prev_month'),
                  onPressed: () => _shiftMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                  color: DesignTokens.slate400,
                ),
                Expanded(
                  child: Text(
                    trMonthYearFromYyyyMm(_monthYyyyMm),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: DesignTokens.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('monthly_goals_next_month'),
                  onPressed: () => _shiftMonth(1),
                  icon: const Icon(Icons.chevron_right),
                  color: DesignTokens.slate400,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DesignTokens.slate900,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DesignTokens.slate800),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  _summary.totalGoals == 0
                      ? 'Bu ay henüz hedef yok'
                      : '${_summary.doneGoals} / ${_summary.totalGoals} tamamlandı',
                  key: const Key('monthly_goals_summary_pill'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.slate400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    children: [
                      if (_goals.isEmpty && !_showAddRow)
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Text(
                            'Bu ay henüz hedef yok',
                            key: const Key('monthly_goals_empty_hint'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: DesignTokens.slate500,
                            ),
                          ),
                        ),
                      for (final g in _goals) _GoalRow(
                        goal: g,
                        onToggleDone: () => unawaited(_toggleDone(g)),
                        onAddToWeek: () => unawaited(_openAddToWeekSheet(g)),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: _showAddRow
                            ? Padding(
                                key: const Key('monthly_goals_add_inline'),
                                padding: const EdgeInsets.only(top: 12),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: DesignTokens.slate900,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: DesignTokens.slate800),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        TextField(
                                          key: const Key(
                                            'monthly_goals_new_title',
                                          ),
                                          controller: _newGoalController,
                                          autofocus: true,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(color: DesignTokens.white),
                                          decoration: InputDecoration(
                                            hintText: 'Hedef başlığı',
                                            hintStyle: TextStyle(
                                              color: DesignTokens.slate500,
                                            ),
                                            filled: true,
                                            fillColor: DesignTokens.slate950,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: DesignTokens.slate800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: FilledButton(
                                            key: const Key(
                                              'monthly_goals_new_submit',
                                            ),
                                            onPressed: _submitNewGoal,
                                            child: const Text('Ekle'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.goal,
    required this.onToggleDone,
    required this.onAddToWeek,
  });

  final MonthlyGoal goal;
  final VoidCallback onToggleDone;
  final VoidCallback onAddToWeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = goal.status == 'done';
    return Opacity(
      opacity: done ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: DesignTokens.slate900,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: DesignTokens.slate800,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${goal.orderIndex}',
                    key: Key('monthly_goals_order_${goal.id}'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: DesignTokens.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.title,
                    key: Key('monthly_goals_title_${goal.id}'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: DesignTokens.slate200,
                      fontWeight: FontWeight.w600,
                      decoration:
                          done ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                ),
                IconButton(
                  key: Key('monthly_goals_done_${goal.id}'),
                  onPressed: onToggleDone,
                  icon: Icon(
                    done ? Icons.check_circle : Icons.check_circle_outline,
                    color: done ? const Color(0xFF22C55E) : DesignTokens.slate400,
                  ),
                ),
                IconButton(
                  key: Key('monthly_goals_add_week_${goal.id}'),
                  onPressed: onAddToWeek,
                  icon: const Icon(Icons.calendar_today_outlined),
                  color: DesignTokens.blue400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddGoalToWeekSheetBody extends StatefulWidget {
  const _AddGoalToWeekSheetBody({
    required this.parentContext,
    required this.goal,
    required this.weekStart,
    required this.sheetContext,
  });

  final BuildContext parentContext;
  final MonthlyGoal goal;
  final String weekStart;
  final BuildContext sheetContext;

  @override
  State<_AddGoalToWeekSheetBody> createState() => _AddGoalToWeekSheetBodyState();
}

class _AddGoalToWeekSheetBodyState extends State<_AddGoalToWeekSheetBody> {
  final Set<int> _selected = {0};

  Future<void> _onSubmit() async {
    final p = widget.parentContext;
    if (!p.mounted) return;
    final svc = p.read<MonthlyGoalService>();
    final revision = p.read<PlanDataRevision>();
    final messenger = ScaffoldMessenger.of(p);
    final idx = _selected.isEmpty ? 0 : _selected.first;
    final planned = plannedDateForChipIndex(widget.weekStart, idx);
    await svc.addGoalToWeek(widget.goal, widget.weekStart, planned);
    revision.bump();
    if (widget.sheetContext.mounted) {
      Navigator.of(widget.sheetContext).pop();
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Göreve eklendi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Material(
        key: const Key('monthly_goals_add_to_week_sheet'),
        color: DesignTokens.slate950,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Haftaya Ekle',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: DesignTokens.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  trWeekRangeFromMonday(widget.weekStart),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.slate400,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gün',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: DesignTokens.slate500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < kPlanDayLabels.length; i++)
                      FilterChip(
                        key: Key('goal_to_week_day_${kPlanDayLabels[i]}'),
                        label: Text(kPlanDayLabels[i]),
                        selected: _selected.contains(i),
                        onSelected: (_) {
                          setState(() {
                            _selected
                              ..clear()
                              ..add(i);
                          });
                        },
                        selectedColor: DesignTokens.blue600,
                        labelStyle: TextStyle(
                          color: _selected.contains(i)
                              ? DesignTokens.white
                              : DesignTokens.slate400,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('monthly_goals_add_to_week_confirm'),
                  onPressed: _onSubmit,
                  child: const Text('Ekle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
