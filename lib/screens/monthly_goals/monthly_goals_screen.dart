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
import '../../services/reminder_scheduler_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/planner_dialogs.dart';
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
    await _reload();
  }

  Future<void> _toggleDone(MonthlyGoal g) async {
    final repo = context.read<MonthlyGoalRepository>();
    if (g.status == 'done') {
      await repo.markGoalActive(g.id);
    } else {
      await repo.markGoalDone(g.id);
    }
    if (!mounted) return;
    context.read<PlanDataRevision>().bump();
    await _reload();
  }

  Future<void> _openGoalReminderSheet(MonthlyGoal goal) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _GoalReminderSheet(
          goal: goal,
          sheetContext: sheetContext,
          onSaved: () async {
            if (!mounted) return;
            context.read<PlanDataRevision>().bump();
            await _reload();
          },
        );
      },
    );
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
                      Padding(
                        key: const Key('monthly_goals_add_inline'),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: DesignTokens.slate900,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DesignTokens.slate800),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    key: const Key('monthly_goals_new_title'),
                                    controller: _newGoalController,
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(color: DesignTokens.white),
                                    decoration: InputDecoration(
                                      hintText: 'Yeni hedef…',
                                      hintStyle: TextStyle(
                                        color: DesignTokens.slate500,
                                      ),
                                      filled: true,
                                      fillColor: DesignTokens.slate950,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: DesignTokens.slate800,
                                        ),
                                      ),
                                    ),
                                    onSubmitted: (_) => unawaited(_submitNewGoal()),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  key: const Key('monthly_goals_new_submit'),
                                  onPressed: () => unawaited(_submitNewGoal()),
                                  icon: const Icon(Icons.add_circle),
                                  color: DesignTokens.blue400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_goals.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'Bu ay henüz hedef yok',
                            key: const Key('monthly_goals_empty_hint'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: DesignTokens.slate500,
                            ),
                          ),
                        ),
                      for (final g in _goals)
                        _GoalRow(
                          goal: g,
                          onToggleDone: () => unawaited(_toggleDone(g)),
                          onAddToWeek: () => unawaited(_openAddToWeekSheet(g)),
                          onReminder: () => unawaited(_openGoalReminderSheet(g)),
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
    required this.onReminder,
  });

  final MonthlyGoal goal;
  final VoidCallback onToggleDone;
  final VoidCallback onAddToWeek;
  final VoidCallback onReminder;

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
                  key: Key('monthly_goals_reminder_${goal.id}'),
                  onPressed: done ? null : onReminder,
                  icon: Icon(
                    goal.reminderEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_none_outlined,
                    color: goal.reminderEnabled
                        ? DesignTokens.blue400
                        : DesignTokens.slate400,
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
    final idx = _selected.isEmpty ? 0 : _selected.first;
    final planned = plannedDateForChipIndex(widget.weekStart, idx);
    await svc.addGoalToWeek(widget.goal, widget.weekStart, planned);
    revision.bump();
    if (widget.sheetContext.mounted) {
      Navigator.of(widget.sheetContext).pop();
    }
    showPlannerSnackBar(widget.sheetContext, 'Göreve eklendi');
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

class _GoalReminderSheet extends StatefulWidget {
  const _GoalReminderSheet({
    required this.goal,
    required this.sheetContext,
    required this.onSaved,
  });

  final MonthlyGoal goal;
  final BuildContext sheetContext;
  final Future<void> Function() onSaved;

  @override
  State<_GoalReminderSheet> createState() => _GoalReminderSheetState();
}

class _GoalReminderSheetState extends State<_GoalReminderSheet> {
  late bool _enabled;
  late int _weekday;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _enabled = widget.goal.reminderEnabled;
    _weekday = widget.goal.reminderWeekday ?? DateTime.monday;
    _minutes = widget.goal.reminderMinutes ?? 9 * 60;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: DesignTokens.blue500,
              brightness: Brightness.dark,
            ).copyWith(surface: DesignTokens.slate900),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _minutes = snappedStartMinutesFromWallClock(
        hour: picked.hour,
        minute: picked.minute,
      );
    });
  }

  Future<void> _save() async {
    final repo = context.read<MonthlyGoalRepository>();
    await repo.updateGoalReminder(
      widget.goal.id,
      enabled: _enabled,
      weekday: _enabled ? _weekday : null,
      minutes: _enabled ? _minutes : null,
    );
    if (widget.sheetContext.mounted) {
      Navigator.of(widget.sheetContext).pop();
    }
    await widget.onSaved();
    if (!context.mounted) return;
    await context.read<ReminderSchedulerService>().syncAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    const weekdayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Material(
        key: const Key('monthly_goal_reminder_sheet'),
        color: DesignTokens.slate950,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hedef hatırlatıcısı',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: DesignTokens.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.goal.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.slate400,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  key: const Key('monthly_goal_reminder_toggle'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Hatırlat',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: DesignTokens.white,
                    ),
                  ),
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                  activeThumbColor: DesignTokens.blue400,
                ),
                if (_enabled) ...[
                  Text(
                    'Gün',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: DesignTokens.slate400,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        ChoiceChip(
                          key: Key('monthly_goal_reminder_wd_$d'),
                          label: Text(weekdayLabels[d - 1]),
                          selected: _weekday == d,
                          onSelected: (_) => setState(() => _weekday = d),
                          selectedColor: DesignTokens.blue600,
                          labelStyle: TextStyle(
                            color: _weekday == d
                                ? DesignTokens.white
                                : DesignTokens.slate400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('monthly_goal_reminder_time'),
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text('Saat: ${formatClockMinutes(_minutes)}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.blue400,
                      side: const BorderSide(color: DesignTokens.slate700),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('monthly_goal_reminder_save'),
                  onPressed: () => unawaited(_save()),
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
