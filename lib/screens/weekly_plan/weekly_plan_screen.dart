import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/planner_feature_flags.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/week_template_repository.dart';
import '../../date/week_calendar.dart';
import '../../plan_data_revision.dart';
import '../../plan_day_labels.dart';
import '../../models/week_template.dart';
import '../../services/planner_feature_flags_store.dart';
import '../../services/task_focus_timer_controller.dart';
import '../../services/week_service.dart';
import '../../services/week_template_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/add_task_sheet.dart';
import '../../widgets/board_column.dart';
import '../../widgets/edit_task_sheet.dart';
import '../../widgets/plan_shift_sheet.dart';
import '../../widgets/planner_top_bar.dart';
import '../../widgets/week_navigation_bar.dart';
import 'plan_board_search_filter.dart';
import 'weekly_plan_board_scroll.dart';
import 'weekly_plan_snapshot_loader.dart';
import 'weekly_plan_task_column.dart';
import 'weekly_plan_today_line.dart';

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  static const double columnWidth = 280;

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  static const double _fabNavClearance = 88;
  static const double _dragFeedbackCardWidth = WeeklyPlanScreen.columnWidth - 48;

  late String _weekStart;
  List<Task> _poolTasks = [];
  final List<List<Task>> _dayTasks = List.generate(7, (_) => []);
  bool _copyFromPreviousApplied = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _boardScrollController;
  final List<ScrollController> _orphanBoardScrollControllers = [];
  Timer? _boardScrollDisposeTimer;
  PlanDataRevision? _planRevision;
  bool _suppressPlanRevisionListener = false;

  List<Task> _poolTasksFiltered(PlannerFeatureFlags flags) {
    return PlanBoardSearchFilter.poolColumn(
      flags: flags,
      isSearching: _isSearching,
      searchRaw: _searchController.text,
      pool: _poolTasks,
    );
  }

  List<List<Task>> _dayTasksFiltered(PlannerFeatureFlags flags) {
    return PlanBoardSearchFilter.dayColumns(
      flags: flags,
      isSearching: _isSearching,
      searchRaw: _searchController.text,
      dayTasks: _dayTasks,
    );
  }

  @override
  void initState() {
    super.initState();
    _boardScrollController = ScrollController();
    _weekStart = mondayIsoContaining(DateTime.now());
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final r = context.read<PlanDataRevision>();
      _planRevision = r;
      r.addListener(_onPlanDataRevision);
      _loadTasksFromRepository(notifyRevision: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final searchOn =
        context.watch<PlannerFeatureFlagsStore>().flags.planBoardSearchEnabled;
    if (!searchOn && _isSearching) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
    }
  }

  void _onPlanDataRevision() {
    if (!mounted || _suppressPlanRevisionListener) return;
    _loadTasksFromRepository(notifyRevision: false);
  }

  @override
  void dispose() {
    _planRevision?.removeListener(_onPlanDataRevision);
    _boardScrollDisposeTimer?.cancel();
    for (final c in _orphanBoardScrollControllers) {
      c.dispose();
    }
    _orphanBoardScrollControllers.clear();
    _searchController.dispose();
    _boardScrollController.dispose();
    super.dispose();
  }

  void _retireBoardScrollControllerForWeekChange() {
    _orphanBoardScrollControllers.add(_boardScrollController);
    _boardScrollController = ScrollController();
    _boardScrollDisposeTimer?.cancel();
    _boardScrollDisposeTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      for (final c in _orphanBoardScrollControllers) {
        c.dispose();
      }
      _orphanBoardScrollControllers.clear();
      _boardScrollDisposeTimer = null;
    });
  }

  void _autoScrollBoardDuringDrag(DragUpdateDetails details) {
    if (!_boardScrollController.hasClients) return;
    final padding = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final dx = details.globalPosition.dx;
    const edge = 72.0;
    const step = 10.0;
    final position = _boardScrollController.position;
    final maxExtent = position.maxScrollExtent;
    var offset = position.pixels;
    if (dx < padding.left + edge) {
      offset = (offset - step).clamp(0.0, maxExtent);
      if (offset != position.pixels) {
        _boardScrollController.jumpTo(offset);
      }
    } else if (dx > width - padding.right - edge) {
      offset = (offset + step).clamp(0.0, maxExtent);
      if (offset != position.pixels) {
        _boardScrollController.jumpTo(offset);
      }
    }
  }

  Future<void> _loadTasks() => _loadTasksFromRepository(notifyRevision: true);

  Future<void> _loadTasksFromRepository({
    required bool notifyRevision,
    String? applyWeekStart,
  }) async {
    final week = applyWeekStart ?? _weekStart;
    final snapshot = await loadWeeklyPlanBoardSnapshot(
      weekStart: week,
      weekService: context.read<WeekService>(),
      repo: context.read<TaskRepository>(),
    );
    if (!mounted) return;
    if (applyWeekStart != null && applyWeekStart != _weekStart) {
      _retireBoardScrollControllerForWeekChange();
    }
    setState(() {
      if (applyWeekStart != null) {
        _weekStart = applyWeekStart;
        _isSearching = false;
        _searchController.clear();
      }
      _poolTasks = snapshot.poolTasks;
      _copyFromPreviousApplied = snapshot.copyFromPreviousApplied;
      for (var i = 0; i < 7; i++) {
        _dayTasks[i] = snapshot.dayTasksByIndex[i];
      }
    });
    if (mounted && notifyRevision) {
      _suppressPlanRevisionListener = true;
      context.read<PlanDataRevision>().bump();
      _suppressPlanRevisionListener = false;
    }
  }

  Future<void> _openAddTaskSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: AddTaskSheet(
            onSubmit: (title, duration, notes, dayIndices, startMinutes,
                accentArgb) async {
              final repo = context.read<TaskRepository>();
              final messenger = ScaffoldMessenger.of(context);
              for (final dayIndex in dayIndices) {
                final plannedIso =
                    plannedDateForChipIndex(_weekStart, dayIndex);
                final now = DateTime.now().toUtc().toIso8601String();
                await repo.insertTask(
                  TasksCompanion.insert(
                    title: title,
                    durationMinutes:
                        duration == null ? const Value.absent() : Value(duration),
                    startMinutes: startMinutes == null
                        ? const Value.absent()
                        : Value(startMinutes),
                    notes: notes == null ? const Value.absent() : Value(notes),
                    accentColor: accentArgb == null
                        ? const Value.absent()
                        : Value(accentArgb),
                    weekStart: _weekStart,
                    plannedDate: plannedIso == null
                        ? const Value.absent()
                        : Value(plannedIso),
                    originalPlannedDate: plannedIso == null
                        ? const Value.absent()
                        : Value(plannedIso),
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
              }
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    dayIndices.length == 1
                        ? 'Etkinlik eklendi'
                        : '${dayIndices.length} etkinlik eklendi',
                  ),
                ),
              );
              if (!context.mounted) return;
              await _loadTasks();
            },
          ),
        );
      },
    );
  }

  Future<void> _dropTaskOnColumn(Task task, String? dropPlannedIso) async {
    if (task.plannedDate == dropPlannedIso) return;
    final repo = context.read<TaskRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final out = await repo.moveTask(task.id, dropPlannedIso);
    if (!mounted) return;
    if (out.didChange) {
      final text = out.movedCountAfter >= 3
          ? 'Etkinlik taşındı — sık taşınıyor (${out.movedCountAfter})'
          : 'Etkinlik taşındı';
      messenger.showSnackBar(SnackBar(content: Text(text)));
    }
    await _loadTasks();
  }

  Future<void> _openPlanShiftSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: PlanShiftSheet(
            weekStart: _weekStart,
            loadDayTasks: (plannedIso) =>
                context.read<TaskRepository>().getDayTasks(
                      _weekStart,
                      plannedIso,
                    ),
            onApply: (plannedIso, anchorMinutes, shiftMinutes) async {
              final repo = context.read<TaskRepository>();
              final messenger = ScaffoldMessenger.of(context);
              final n = await repo.shiftPlannedDayTasksAfterAnchor(
                weekStart: _weekStart,
                plannedDateIso: plannedIso,
                anchorStartMinutes: anchorMinutes,
                breakMinutes: shiftMinutes,
              );
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              if (!context.mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    n == 0
                        ? 'Kaydırılacak etkinlik yok'
                        : '$n etkinlik kaydırıldı',
                  ),
                ),
              );
              if (mounted) await _loadTasks();
            },
          ),
        );
      },
    );
  }

  Future<void> _runTaskDeleteFlow(
    Task task, {
    required BuildContext dialogAnchor,
    void Function()? afterRepoDelete,
  }) async {
    final ok = await showDialog<bool>(
      context: dialogAnchor,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Etkinliği sil'),
        content: Text('“${task.title}” silinecek. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'İptal',
              style: TextStyle(color: DesignTokens.blue400),
            ),
          ),
          FilledButton(
            key: const Key('confirm_task_delete_dialog'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final repo = context.read<TaskRepository>();
    final messenger = ScaffoldMessenger.of(context);
    await repo.deleteTask(task.id);
    if (!mounted) return;
    afterRepoDelete?.call();
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Etkinlik silindi')),
    );
    await _loadTasks();
  }

  Future<void> _openEditTaskSheet(Task task) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: EditTaskSheet(
            initialTitle: task.title,
            initialDurationMinutes: task.durationMinutes,
            initialNotes: task.notes,
            initialDayIndex: chipIndexForPlannedDate(_weekStart, task.plannedDate),
            initialStartMinutes: task.startMinutes,
            initialAccentColor: task.accentColor,
            taskEntity: task,
            onStartFocus: task.status == 'planned'
                ? (draft) async {
                    await context.read<TaskFocusTimerController>().start(draft);
                  }
                : null,
            onSubmit:
                (title, durationMinutes, notes, int dayIndex, int? startMinutes,
                    int? accentColorArgb) async {
              final repo = context.read<TaskRepository>();
              final messenger = ScaffoldMessenger.of(context);
              final newPlanned = plannedDateForChipIndex(_weekStart, dayIndex);
              MoveTaskOutcome? moveOut;
              if (task.plannedDate != newPlanned) {
                moveOut = await repo.moveTask(task.id, newPlanned);
              }
              final latest = await repo.getTaskById(task.id);
              if (latest == null) return;
              final now = DateTime.now().toUtc().toIso8601String();
              await repo.updateTask(
                latest.copyWith(
                  title: title,
                  durationMinutes: Value(durationMinutes),
                  startMinutes: Value(startMinutes),
                  notes: Value(notes),
                  accentColor: Value(accentColorArgb),
                  updatedAt: now,
                ),
              );
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              var line = 'Güncellendi';
              if (moveOut != null &&
                  moveOut.didChange &&
                  moveOut.movedCountAfter >= 3) {
                line =
                    'Güncellendi — sık taşınıyor (${moveOut.movedCountAfter})';
              }
              messenger.showSnackBar(SnackBar(content: Text(line)));
              if (!context.mounted) return;
              await _loadTasks();
            },
            onDeletePressed: () async {
              await _runTaskDeleteFlow(
                task,
                dialogAnchor: sheetContext,
                afterRepoDelete: () {
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  bool _isTodayColumnTitle(int columnIndex) {
    if (columnIndex <= 0) return false;
    final today = toIsoDate(DateTime.now());
    final isos = weekdayIsosFromMonday(_weekStart);
    final dayIdx = columnIndex - 1;
    if (dayIdx < 0 || dayIdx >= isos.length) return false;
    return isos[dayIdx] == today;
  }

  Future<void> _onMarkDone(Task t) async {
    final repo = context.read<TaskRepository>();
    await repo.markDone(t.id);
    if (mounted) await _loadTasks();
  }

  Future<void> _onUnmarkDone(Task t) async {
    final repo = context.read<TaskRepository>();
    await repo.unmarkDone(t.id);
    if (mounted) await _loadTasks();
  }

  Future<void> _onCopyLastWeek() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Geçen haftayı kopyala'),
        content: const Text(
          'Geçen haftanın etkinlikleri kopyalanacak. Devam?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Devam'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repo = context.read<TaskRepository>();
    final messenger = ScaffoldMessenger.of(context);
    await repo.copyLastWeekTasks(_weekStart);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Kopyalandı')),
    );
    await _loadTasks();
  }

  Future<void> _openApplyTemplateSheet() async {
    final repo = context.read<WeekTemplateRepository>();
    final templates = await repo.getTemplates();
    if (!mounted) return;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Henüz şablon yok. Ayarlar > Şablonlar\'dan ekle.',
          ),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        return _ApplyWeekTemplateSheet(
          parentContext: context,
          sheetContext: sheetContext,
          weekStart: _weekStart,
          templates: templates,
          onApplied: _loadTasks,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.viewPaddingOf(context).bottom + _fabNavClearance;
    final featureFlags = context.watch<PlannerFeatureFlagsStore>().flags;
    final copyBtn = IconButton(
      key: const Key('copy_last_week'),
      tooltip: _copyFromPreviousApplied
          ? 'Bu hafta için uygulandı'
          : 'Geçen haftayı kopyala',
      onPressed: _copyFromPreviousApplied ? null : _onCopyLastWeek,
      icon: Icon(
        Icons.content_copy,
        color: _copyFromPreviousApplied
            ? const Color(0xFF64748B)
            : const Color(0xFFE2E8F0),
      ),
    );

    Widget? weekNavTrailing;
    final trailingParts = <Widget>[];
    if (featureFlags.weekTemplatesEnabled) {
      trailingParts.add(
        IconButton(
          key: const Key('weekly_plan_apply_template'),
          tooltip: 'Şablon uygula',
          onPressed: _openApplyTemplateSheet,
          icon: const Icon(Icons.dashboard_customize_outlined),
          color: DesignTokens.blue400,
        ),
      );
    }
    if (featureFlags.copyLastWeekEnabled) {
      trailingParts.add(copyBtn);
    }
    if (trailingParts.length == 1) {
      weekNavTrailing = trailingParts.single;
    } else if (trailingParts.length > 1) {
      weekNavTrailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: trailingParts,
      );
    }

    return Scaffold(
      key: const Key('weekly_plan_screen'),
      backgroundColor: DesignTokens.slate950,
      appBar: PlannerTopBar(
        onCalendarTap: () {},
        moreMenuBuilder: (_) => [
          if (featureFlags.scheduledBreaksEnabled)
            const PopupMenuItem<String>(
              value: 'plan_shift',
              child: Text('Planı kaydır'),
            ),
          const PopupMenuItem<String>(
            value: 'refresh_week',
            child: Text('Haftayı yenile'),
          ),
        ],
        onMoreMenuSelected: (value) {
          switch (value) {
            case 'plan_shift':
              unawaited(_openPlanShiftSheet());
              break;
            case 'refresh_week':
              unawaited(_loadTasks());
              break;
          }
        },
        extraActions: featureFlags.planBoardSearchEnabled
            ? [
                if (_isSearching)
                  IconButton(
                    key: const Key('weekly_plan_search_clear'),
                    icon: const Icon(Icons.close),
                    color: DesignTokens.blue500,
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                      });
                    },
                  )
                else
                  IconButton(
                    key: const Key('weekly_plan_search'),
                    icon: const Icon(Icons.search),
                    color: DesignTokens.blue500,
                    onPressed: () {
                      setState(() => _isSearching = true);
                    },
                  ),
              ]
            : null,
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FloatingActionButton(
          key: const Key('fab_add_task'),
          onPressed: _openAddTaskSheet,
          backgroundColor: DesignTokens.blue600,
          foregroundColor: DesignTokens.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WeekNavigationBar(
            label: 'Bu hafta: $_weekStart',
            trailingAction: weekNavTrailing,
            onPrevious: () {
              unawaited(
                _loadTasksFromRepository(
                  notifyRevision: true,
                  applyWeekStart: addDaysIso(_weekStart, -7),
                ),
              );
            },
            onNext: () {
              unawaited(
                _loadTasksFromRepository(
                  notifyRevision: true,
                  applyWeekStart: addDaysIso(_weekStart, 7),
                ),
              );
            },
          ),
          if (featureFlags.planBoardSearchEnabled && _isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                key: const Key('weekly_plan_search_field'),
                controller: _searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: DesignTokens.white,
                    ),
                cursorColor: DesignTokens.blue400,
                decoration: InputDecoration(
                  hintText: 'Etkinlik ara…',
                  hintStyle: TextStyle(color: DesignTokens.slate500),
                  filled: true,
                  fillColor: DesignTokens.slate900,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: DesignTokens.slate700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: DesignTokens.slate700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: DesignTokens.blue500),
                  ),
                ),
              ),
            ),
          Material(
            color: DesignTokens.slate900.withValues(alpha: 0.5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: DesignTokens.slate800.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(
                  weeklyPlanTodaySummaryLine(
                    weekStart: _weekStart,
                    dayTasks: _dayTasks,
                  ),
                  key: const Key('weekly_plan_day_hint'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: DesignTokens.slate400,
                      ),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: DesignTokens.motionMedium,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.028),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: LayoutBuilder(
                key: ValueKey<String>(_weekStart),
                builder: (context, constraints) {
                  final dayIsos = weekdayIsosFromMonday(_weekStart);
                  return WeeklyPlanHorizontalBoardScroll(
                    controller: _boardScrollController,
                    minHeight: constraints.maxHeight,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < kPlanDayLabels.length; i++) ...[
                            if (i > 0) SizedBox(width: DesignTokens.space3),
                            BoardColumn(
                              title: kPlanDayLabels[i],
                              subtitle: null,
                              badgeCount: i == 0
                                  ? _poolTasksFiltered(featureFlags).length
                                  : _dayTasksFiltered(featureFlags)[i - 1].length,
                              width: WeeklyPlanScreen.columnWidth,
                              titleHighlightToday: _isTodayColumnTitle(i),
                              subdued: i > 0 &&
                                  _dayTasksFiltered(featureFlags)[i - 1].isEmpty,
                              child: i == 0
                                  ? WeeklyPlanTaskColumn(
                                      tasks: _poolTasksFiltered(featureFlags),
                                      columnKeySuffix: kPlanDayLabels[i],
                                      dropPlannedIso: null,
                                      dragFeedbackCardWidth:
                                          _dragFeedbackCardWidth,
                                      onEditTask: _openEditTaskSheet,
                                      onMarkDone: _onMarkDone,
                                      onUnmarkDone: _onUnmarkDone,
                                      onDropFromDrag: _dropTaskOnColumn,
                                      onDragUpdate: _autoScrollBoardDuringDrag,
                                    )
                                  : WeeklyPlanTaskColumn(
                                      tasks: _dayTasksFiltered(featureFlags)[i - 1],
                                      columnKeySuffix: kPlanDayLabels[i],
                                      dropPlannedIso: dayIsos[i - 1],
                                      dragFeedbackCardWidth:
                                          _dragFeedbackCardWidth,
                                      onEditTask: _openEditTaskSheet,
                                      onMarkDone: _onMarkDone,
                                      onUnmarkDone: _onUnmarkDone,
                                      onDropFromDrag: _dropTaskOnColumn,
                                      onDragUpdate: _autoScrollBoardDuringDrag,
                                    ),
                            ),
                          ],
                          SizedBox(width: DesignTokens.space2),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyWeekTemplateSheet extends StatelessWidget {
  const _ApplyWeekTemplateSheet({
    required this.parentContext,
    required this.sheetContext,
    required this.weekStart,
    required this.templates,
    required this.onApplied,
  });

  final BuildContext parentContext;
  final BuildContext sheetContext;
  final String weekStart;
  final List<WeekTemplate> templates;
  final Future<void> Function() onApplied;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('week_template_apply_sheet'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        shrinkWrap: true,
        children: [
          Text(
            'Şablon Uygula',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final t in templates)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.name),
              subtitle: Text('${t.taskCount} görev'),
              onTap: () => _onPick(t),
            ),
        ],
      ),
    );
  }

  Future<void> _onPick(WeekTemplate t) async {
    Navigator.of(sheetContext).pop();
    final ok = await showDialog<bool>(
      context: parentContext,
      builder: (dctx) => AlertDialog(
        title: const Text('Şablon uygula'),
        content: Text('${t.taskCount} görev bu haftaya eklenecek. Devam?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Devam'),
          ),
        ],
      ),
    );
    if (ok != true || !parentContext.mounted) return;
    final svc = parentContext.read<WeekTemplateService>();
    final n = await svc.applyTemplate(t.id, weekStart);
    if (!parentContext.mounted) return;
    await onApplied();
    if (!parentContext.mounted) return;
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(content: Text('$n görev eklendi')),
    );
  }
}
