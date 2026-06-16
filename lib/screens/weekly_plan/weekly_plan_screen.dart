import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/planner_feature_flags.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/task_repository.dart';
import '../../models/task_kind.dart';
import '../../data/repositories/week_template_repository.dart';
import '../../date/turkish_date.dart';
import '../../date/week_calendar.dart';
import '../../plan_data_revision.dart';
import '../../plan_day_labels.dart';
import '../../models/week_template.dart';
import '../../services/planner_feature_flags_store.dart';
import '../../services/task_focus_timer_controller.dart';
import '../../services/week_service.dart';
import '../../services/week_template_service.dart';
import '../../theme/design_tokens.dart';
import '../../theme/planner_shell_layout.dart';
import '../../widgets/add_task_sheet.dart';
import '../../widgets/board_column.dart';
import '../../widgets/edit_task_sheet.dart';
import '../../widgets/plan_shift_sheet.dart';
import '../../widgets/planner_dialogs.dart';
import '../../widgets/planner_top_bar.dart';
import '../../widgets/quick_move_sheet.dart';
import '../../widgets/week_navigation_bar.dart';
import 'plan_board_search_filter.dart';
import 'weekly_plan_board_scroll.dart';
import 'weekly_plan_snapshot_loader.dart';
import 'weekly_plan_task_column.dart';

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  static const double columnWidth = 280;

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
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
  bool _applyTemplateInFlight = false;
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
                accentArgb, taskKind) async {
              final repo = context.read<TaskRepository>();
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
                    taskKind: Value(taskKind),
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
              final label = taskKind == TaskKind.event ? 'Etkinlik' : 'İş';
              showPlannerSnackBar(
                sheetContext,
                dayIndices.length == 1
                    ? '$label eklendi'
                    : '${dayIndices.length} $label eklendi',
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
    final out = await repo.moveTask(task.id, dropPlannedIso);
    if (!mounted) return;
    if (out.didChange) {
      final text = out.movedCountAfter >= 3
          ? 'Etkinlik taşındı — sık taşınıyor (${out.movedCountAfter})'
          : 'Etkinlik taşındı';
      showPlannerSnackBar(context, text);
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
              final n = await repo.shiftPlannedDayTasksAfterAnchor(
                weekStart: _weekStart,
                plannedDateIso: plannedIso,
                anchorStartMinutes: anchorMinutes,
                breakMinutes: shiftMinutes,
              );
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              if (!context.mounted) return;
              showPlannerSnackBar(
                sheetContext,
                n == 0
                    ? 'Kaydırılacak etkinlik yok'
                    : '$n etkinlik kaydırıldı',
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
    final ok = await PlannerDialogs.confirmDelete(
      dialogAnchor,
      title: 'Etkinliği sil',
      message: '“${task.title}” silinecek. Bu işlem geri alınamaz.',
      confirmKey: const Key('confirm_task_delete_dialog'),
    );
    if (ok != true || !mounted) return;
    final repo = context.read<TaskRepository>();
    await repo.deleteTask(task.id);
    if (!mounted) return;
    afterRepoDelete?.call();
    if (!mounted) return;
    showPlannerSnackBar(context, 'Etkinlik silindi');
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
            initialDayIndex:
                dayChipIndexForUi(_weekStart, task.plannedDate),
            initialStartMinutes: task.startMinutes,
            initialAccentColor: task.accentColor,
            initialTaskKind: task.taskKind,
            taskEntity: task,
            onStartFocus: task.status == 'planned' && TaskKind.isWork(task)
                ? (draft) async {
                    await context.read<TaskFocusTimerController>().start(draft);
                  }
                : null,
            onSubmit:
                (title, durationMinutes, notes, int dayIndex, int? startMinutes,
                    int? accentColorArgb, String taskKind) async {
              final repo = context.read<TaskRepository>();
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
                  taskKind: taskKind,
                  reminderEnabled: 0,
                  reminderMinutes: const Value(null),
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
              showPlannerSnackBar(sheetContext, line);
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

  Future<void> _onMarkSkipped(Task t) async {
    final repo = context.read<TaskRepository>();
    await repo.markSkipped(t.id);
    if (mounted) {
      context.read<PlanDataRevision>().bump();
      await _loadTasks();
    }
  }

  Future<void> _onUnmarkSkipped(Task t) async {
    final repo = context.read<TaskRepository>();
    await repo.unmarkSkipped(t.id);
    if (mounted) {
      context.read<PlanDataRevision>().bump();
      await _loadTasks();
    }
  }

  Future<void> _onQuickMove(Task t) async {
    await showQuickMoveSheet(
      context: context,
      task: t,
      onMoveToDayIndex: (dayIndex) async {
        final iso = plannedDateForChipIndex(_weekStart, dayIndex);
        await _dropTaskOnColumn(t, iso);
      },
    );
  }

  void _scrollToBoardColumn(int columnIndex) {
    if (!_boardScrollController.hasClients) return;
    final step = WeeklyPlanScreen.columnWidth + DesignTokens.space3;
    final target = (columnIndex * step).clamp(
      0.0,
      _boardScrollController.position.maxScrollExtent,
    );
    unawaited(
      _boardScrollController.animateTo(
        target,
        duration: DesignTokens.motionMedium,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _pickWeekFromCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseIsoDate(_weekStart),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Hafta seçin',
      cancelText: 'İptal',
      confirmText: 'Tamam',
    );
    if (picked == null || !mounted) return;
    final monday = mondayIsoContaining(picked);
    if (monday == _weekStart) return;
    await _loadTasksFromRepository(
      applyWeekStart: monday,
      notifyRevision: true,
    );
  }

  Future<void> _onCopyLastWeek() async {
    final confirmed = await PlannerDialogs.confirm(
      context,
      title: 'Geçen haftayı kopyala',
      message: 'Geçen haftanın etkinlikleri kopyalanacak. Devam?',
    );
    if (confirmed != true || !mounted) return;
    final repo = context.read<TaskRepository>();
    await repo.copyLastWeekTasks(_weekStart);
    if (!mounted) return;
    showPlannerSnackBar(context, 'Kopyalandı');
    await _loadTasks();
  }

  Future<void> _openApplyTemplateSheet() async {
    if (_applyTemplateInFlight) return;
    final repo = context.read<WeekTemplateRepository>();
    final templates = await repo.getTemplates();
    if (!mounted) return;
    if (templates.isEmpty) {
      showPlannerSnackBar(
        context,
        'Henüz kayıtlı plan yok. Ayarlar → Kayıtlı hafta planlarından ekleyebilirsin.',
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        return _ApplyWeekTemplateSheet(
          templates: templates,
          onPick: _applyWeekTemplate,
        );
      },
    );
  }

  Future<void> _applyWeekTemplate(WeekTemplate t) async {
    if (_applyTemplateInFlight || !mounted) return;
    _applyTemplateInFlight = true;
    try {
      final weekStart = _weekStart;
      final existingCount =
          (await context.read<TaskRepository>().getTasksForWeek(weekStart))
              .length;
      final duplicateHint = existingCount > 0
          ? '\n\nBu haftada zaten $existingCount görev var; şablon tekrar uygulanırsa görevler çoğalır.'
          : '';
      if (!mounted) return;
      final ok = await PlannerDialogs.confirm(
        context,
        title: 'Kayıtlı plan uygula',
        message:
            '${t.taskCount} görev bu haftaya eklenecek.$duplicateHint\n\nDevam?',
      );
      if (ok != true || !mounted) return;
      final n = await context.read<WeekTemplateService>().applyTemplate(
            t.id,
            weekStart,
          );
      if (!mounted) return;
      await _loadTasks();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      showPlannerSnackBar(context, '$n görev eklendi');
    } finally {
      _applyTemplateInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = plannerShellFabBottomPadding(context);
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
          tooltip: 'Kayıtlı hafta planını uygula',
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
        onCalendarTap: () => unawaited(_pickWeekFromCalendar()),
        moreMenuBuilder: (_) => [
          if (featureFlags.scheduledBreaksEnabled)
            const PopupMenuItem<String>(
              value: 'plan_shift',
              child: Text('Günlük planı kaydır'),
            ),
          const PopupMenuItem<String>(
            value: 'refresh_week',
            child: Text('Listeyi yenile'),
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
            label: trWeekNavigationLabel(_weekStart),
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
                            Builder(
                              builder: (context) {
                                final colTasks = i == 0
                                    ? _poolTasksFiltered(featureFlags)
                                    : _dayTasksFiltered(featureFlags)[i - 1];
                                final isTodayCol = _isTodayColumnTitle(i);
                                return BoardColumn(
                                  title: kPlanDayLabels[i],
                                  dateShort: i > 0
                                      ? trDayMonthShort(
                                          parseIsoDate(dayIsos[i - 1]),
                                        )
                                      : null,
                                  badgeCount: colTasks.length,
                                  width: WeeklyPlanScreen.columnWidth,
                                  titleHighlightToday: isTodayCol,
                                  subdued: i > 0 && colTasks.isEmpty,
                                  child: WeeklyPlanTaskColumn(
                                    tasks: colTasks,
                                    weekMondayIso: _weekStart,
                                    columnKeySuffix: kPlanDayLabels[i],
                                    dropPlannedIso:
                                        i == 0 ? null : dayIsos[i - 1],
                                    dragFeedbackCardWidth:
                                        _dragFeedbackCardWidth,
                                    onEditTask: _openEditTaskSheet,
                                    onMarkDone: _onMarkDone,
                                    onUnmarkDone: _onUnmarkDone,
                                    onMarkSkipped: _onMarkSkipped,
                                    onUnmarkSkipped: _onUnmarkSkipped,
                                    onQuickMove: _onQuickMove,
                                    onDropFromDrag: _dropTaskOnColumn,
                                    onDragUpdate: _autoScrollBoardDuringDrag,
                                  ),
                                );
                              },
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
    required this.templates,
    required this.onPick,
  });

  final List<WeekTemplate> templates;
  final Future<void> Function(WeekTemplate template) onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('week_template_apply_sheet'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        shrinkWrap: true,
        children: [
          Text(
            'Kayıtlı plan uygula',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final t in templates)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.name),
              subtitle: Text('${t.taskCount} görev'),
              onTap: () {
                Navigator.of(context).pop();
                unawaited(onPick(t));
              },
            ),
        ],
      ),
    );
  }
}
