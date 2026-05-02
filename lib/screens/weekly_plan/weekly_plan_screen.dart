import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/task_repository.dart';
import '../../date/week_calendar.dart';
import '../../plan_data_revision.dart';
import '../../plan_day_labels.dart';
import '../../services/planner_feature_flags_store.dart';
import '../../services/week_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/add_task_sheet.dart';
import '../../widgets/board_column.dart';
import '../../widgets/edit_task_sheet.dart';
import '../../widgets/plan_shift_sheet.dart';
import '../../widgets/planner_top_bar.dart';
import '../../widgets/task_card.dart';
import '../../widgets/week_navigation_bar.dart';

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  static const double columnWidth = 280;

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  static const double _fabNavClearance = 88;

  late String _weekStart;
  List<Task> _poolTasks = [];
  final List<List<Task>> _dayTasks = List.generate(7, (_) => []);
  bool _copyFromPreviousApplied = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _boardScrollController = ScrollController();
  PlanDataRevision? _planRevision;
  bool _suppressPlanRevisionListener = false;

  List<Task> get _filteredPoolTasks {
    if (!_isSearching) return _poolTasks;
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _poolTasks;
    return _poolTasks
        .where((t) => t.title.toLowerCase().contains(q))
        .toList();
  }

  List<List<Task>> get _filteredDayTasks {
    if (!_isSearching) return _dayTasks;
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _dayTasks;
    return List.generate(
      7,
      (i) => _dayTasks[i]
          .where((t) => t.title.toLowerCase().contains(q))
          .toList(),
    );
  }

  @override
  void initState() {
    super.initState();
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

  void _onPlanDataRevision() {
    if (!mounted || _suppressPlanRevisionListener) return;
    _loadTasksFromRepository(notifyRevision: false);
  }

  @override
  void dispose() {
    _planRevision?.removeListener(_onPlanDataRevision);
    _searchController.dispose();
    _boardScrollController.dispose();
    super.dispose();
  }

  void _autoScrollBoardDuringDrag(DragUpdateDetails details) {
    if (!_boardScrollController.hasClients) return;
    final padding = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final dx = details.globalPosition.dx;
    const edge = 72.0;
    const step = 28.0;
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

  Future<void> _loadTasksFromRepository({required bool notifyRevision}) async {
    final weekService = context.read<WeekService>();
    final repo = context.read<TaskRepository>();
    await weekService.ensureWeekTasks(_weekStart);
    final pool = await repo.getPoolTasks(_weekStart);
    final copyApplied = await repo.isCopyFromPreviousApplied(_weekStart);
    final dayIsos = weekdayIsosFromMonday(_weekStart);
    final days = <List<Task>>[];
    for (final iso in dayIsos) {
      days.add(await repo.getDayTasks(_weekStart, iso));
    }
    if (!mounted) return;
    setState(() {
      _poolTasks = pool;
      _copyFromPreviousApplied = copyApplied;
      for (var i = 0; i < 7; i++) {
        _dayTasks[i] = days[i];
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
            onSubmit: (title, duration, notes, dayIndices, startMinutes) async {
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
    await repo.moveTask(task.id, dropPlannedIso);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Etkinlik taşındı')),
    );
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
            onSubmit: (title, durationMinutes, notes, int dayIndex, int? startMinutes) async {
              final repo = context.read<TaskRepository>();
              final messenger = ScaffoldMessenger.of(context);
              final newPlanned = plannedDateForChipIndex(_weekStart, dayIndex);
              if (task.plannedDate != newPlanned) {
                await repo.moveTask(task.id, newPlanned);
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
                  updatedAt: now,
                ),
              );
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Güncellendi')),
              );
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

  Widget _columnBody(
    List<Task> tasks,
    String columnKeySuffix, {
    required String? dropPlannedIso,
  }) {
    final inner = tasks.isEmpty
        ? _EmptyColumnPlaceholder(
            label: columnKeySuffix == 'Havuz' ? 'Boş' : 'Etkinlik yok',
            testKey: 'weekly_plan_empty_$columnKeySuffix',
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final task = tasks[i];
              Widget card(Task t, {required bool omitKey, required bool withDragSlot}) {
                return TaskCard(
                  key: omitKey ? null : Key('task_card_${t.id}'),
                  task: t,
                  onBodyTap: () => unawaited(_openEditTaskSheet(t)),
                  onMarkDone: () async {
                    final repo = context.read<TaskRepository>();
                    await repo.markDone(t.id);
                    if (mounted) await _loadTasks();
                  },
                  onUnmarkDone: () async {
                    final repo = context.read<TaskRepository>();
                    await repo.unmarkDone(t.id);
                    if (mounted) await _loadTasks();
                  },
                  dragSlotWrapper: withDragSlot
                      ? (Widget dragBody) {
                          return LongPressDraggable<Task>(
                            key: Key('task_drag_${t.id}'),
                            data: t,
                            maxSimultaneousDrags: 1,
                            onDragUpdate: _autoScrollBoardDuringDrag,
                            hapticFeedbackOnStart: true,
                            feedback: Material(
                              elevation: 12,
                              borderRadius: BorderRadius.circular(8),
                              clipBehavior: Clip.antiAlias,
                              child: Opacity(
                                opacity: 0.92,
                                child: SizedBox(
                                  width: WeeklyPlanScreen.columnWidth - 48,
                                  child: card(t, omitKey: true, withDragSlot: false),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.4,
                              child: card(t, omitKey: true, withDragSlot: false),
                            ),
                            child: dragBody,
                          );
                        }
                      : null,
                );
              }

              return card(task, omitKey: false, withDragSlot: true);
            },
          );

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) =>
          details.data.plannedDate != dropPlannedIso,
      onAcceptWithDetails: (details) {
        unawaited(_dropTaskOnColumn(details.data, dropPlannedIso));
      },
      builder: (context, candidateData, rejected) {
        final highlight = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              width: 2,
              color: highlight ? DesignTokens.blue500 : Colors.transparent,
            ),
          ),
          child: inner,
        );
      },
    );
  }

  String _todayLine() {
    final today = toIsoDate(DateTime.now());
    final isos = weekdayIsosFromMonday(_weekStart);
    final idx = isos.indexOf(today);
    if (idx < 0) {
      return 'Bu hafta takvimde değil';
    }
    final list = _dayTasks[idx];
    var mins = 0;
    for (final t in list) {
      mins += t.durationMinutes ?? 0;
    }
    return 'Bugün ${list.length} etkinliğin var · $mins dk';
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
        extraActions: [
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
        ],
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
            trailingAction:
                featureFlags.copyLastWeekEnabled ? copyBtn : null,
            onPrevious: () {
              setState(() {
                _weekStart = addDaysIso(_weekStart, -7);
                _isSearching = false;
                _searchController.clear();
              });
              _loadTasks();
            },
            onNext: () {
              setState(() {
                _weekStart = addDaysIso(_weekStart, 7);
                _isSearching = false;
                _searchController.clear();
              });
              _loadTasks();
            },
          ),
          if (_isSearching)
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
                  _todayLine(),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dayIsos = weekdayIsosFromMonday(_weekStart);
                return _HorizontalBoardScroll(
                  controller: _boardScrollController,
                  minHeight: constraints.maxHeight,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < kPlanDayLabels.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          BoardColumn(
                            title: kPlanDayLabels[i],
                            subtitle: null,
                            badgeCount: i == 0
                                ? _filteredPoolTasks.length
                                : _filteredDayTasks[i - 1].length,
                            width: WeeklyPlanScreen.columnWidth,
                            titleHighlightToday: _isTodayColumnTitle(i),
                            subdued: i > 0 &&
                                _filteredDayTasks[i - 1].isEmpty,
                            child: i == 0
                                ? _columnBody(
                                    _filteredPoolTasks,
                                    kPlanDayLabels[i],
                                    dropPlannedIso: null,
                                  )
                                : _columnBody(
                                    _filteredDayTasks[i - 1],
                                    kPlanDayLabels[i],
                                    dropPlannedIso: dayIsos[i - 1],
                                  ),
                          ),
                        ],
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyColumnPlaceholder extends StatelessWidget {
  const _EmptyColumnPlaceholder({
    required this.label,
    required this.testKey,
  });

  final String label;
  final String testKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _DashedRRectPainter(
                color: const Color(0xFF334155),
                strokeWidth: 2,
                borderRadius: 8,
              ),
            ),
            Center(
              child: Text(
                label,
                key: Key(testKey),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    this.strokeWidth = 2,
    this.borderRadius = 8,
  });

  static const double _dashLength = 6;
  static const double _gapLength = 4;

  final Color color;
  final double strokeWidth;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final len = math.min(_dashLength, metric.length - d);
        canvas.drawPath(metric.extractPath(d, len), paint);
        d += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.borderRadius != borderRadius;
}

class _HorizontalBoardScroll extends StatelessWidget {
  const _HorizontalBoardScroll({
    required this.controller,
    required this.minHeight,
    required this.child,
  });

  final ScrollController controller;
  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: child,
        ),
      ),
    );
  }
}
