import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/week_template.dart';
import '../../plan_day_labels.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/board_column.dart';
import '../weekly_plan/weekly_plan_board_scroll.dart';

const double kWeekTemplateBoardColumnWidth = 280;
const double _kDragFeedbackCardWidth = kWeekTemplateBoardColumnWidth - 48;

bool _sameTargetWeekday(int? a, int? b) {
  if (a == null && b == null) return true;
  return a == b;
}

class WeekTemplatePlanBoard extends StatelessWidget {
  const WeekTemplatePlanBoard({
    super.key,
    required this.tasks,
    required this.controller,
    required this.onDropTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onDragUpdate,
  });

  final List<WeekTemplateTask> tasks;
  final ScrollController controller;
  final Future<void> Function(WeekTemplateTask task, int? newTargetWeekday) onDropTask;
  final Future<void> Function(WeekTemplateTask task) onEditTask;
  final Future<void> Function(WeekTemplateTask task) onDeleteTask;
  final void Function(DragUpdateDetails details) onDragUpdate;

  List<List<WeekTemplateTask>> _group(List<WeekTemplateTask> all) {
    final pool = <WeekTemplateTask>[];
    final days = List.generate(7, (_) => <WeekTemplateTask>[]);
    for (final t in all) {
      final tw = t.targetWeekday;
      if (tw == null || tw < 1 || tw > 7) {
        pool.add(t);
      } else {
        days[tw - 1].add(t);
      }
    }
    for (final list in days) {
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }
    pool.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return [pool, ...days];
  }

  @override
  Widget build(BuildContext context) {
    final g = _group(tasks);
    return LayoutBuilder(
      builder: (context, constraints) {
        return WeeklyPlanHorizontalBoardScroll(
          controller: controller,
          minHeight: constraints.maxHeight,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < kPlanDayLabels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  BoardColumn(
                    title: kPlanDayLabels[i],
                    badgeCount: g[i].length,
                    width: kWeekTemplateBoardColumnWidth,
                    subdued: i > 0 && g[i].isEmpty,
                    child: WeekTemplateTaskColumn(
                      tasks: g[i],
                      columnKeySuffix: kPlanDayLabels[i],
                      dropTargetWeekday: i == 0 ? null : i,
                      dragFeedbackCardWidth: _kDragFeedbackCardWidth,
                      onDropFromDrag: onDropTask,
                      onEditTask: onEditTask,
                      onDeleteTask: onDeleteTask,
                      onDragUpdate: onDragUpdate,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class WeekTemplateTaskColumn extends StatelessWidget {
  const WeekTemplateTaskColumn({
    super.key,
    required this.tasks,
    required this.columnKeySuffix,
    required this.dropTargetWeekday,
    required this.dragFeedbackCardWidth,
    required this.onDropFromDrag,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onDragUpdate,
  });

  final List<WeekTemplateTask> tasks;
  final String columnKeySuffix;
  final int? dropTargetWeekday;
  final double dragFeedbackCardWidth;
  final Future<void> Function(WeekTemplateTask task, int? newTargetWeekday) onDropFromDrag;
  final Future<void> Function(WeekTemplateTask task) onEditTask;
  final Future<void> Function(WeekTemplateTask task) onDeleteTask;
  final void Function(DragUpdateDetails details) onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final inner = tasks.isEmpty
        ? WeeklyPlanEmptyColumnPlaceholder(
            label: columnKeySuffix == 'Havuz' ? 'Boş' : 'Etkinlik yok',
            testKey: 'week_tpl_empty_$columnKeySuffix',
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final task = tasks[i];
              Widget card(WeekTemplateTask t, {required bool omitKey, required bool withDrag}) {
                return _WeekTemplateTaskCard(
                  key: omitKey ? null : Key('week_tpl_card_${t.id}'),
                  task: t,
                  onTap: () => unawaited(onEditTask(t)),
                  onDelete: () => unawaited(onDeleteTask(t)),
                  dragSlotWrapper: withDrag
                      ? (Widget body) => LongPressDraggable<WeekTemplateTask>(
                            key: Key('week_tpl_drag_${t.id}'),
                            data: t,
                            delay: const Duration(milliseconds: 800),
                            maxSimultaneousDrags: 1,
                            onDragUpdate: onDragUpdate,
                            hapticFeedbackOnStart: false,
                            onDragStarted: () {
                              HapticFeedback.mediumImpact();
                            },
                            feedback: Material(
                              elevation: 12,
                              borderRadius: BorderRadius.circular(8),
                              clipBehavior: Clip.antiAlias,
                              child: Opacity(
                                opacity: 0.92,
                                child: SizedBox(
                                  width: dragFeedbackCardWidth,
                                  child: card(t, omitKey: true, withDrag: false),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.4,
                              child: card(t, omitKey: true, withDrag: false),
                            ),
                            child: body,
                          )
                      : null,
                );
              }

              return card(task, omitKey: false, withDrag: true);
            },
          );

    return DragTarget<WeekTemplateTask>(
      onWillAcceptWithDetails: (details) =>
          !_sameTargetWeekday(details.data.targetWeekday, dropTargetWeekday),
      onAcceptWithDetails: (details) {
        unawaited(onDropFromDrag(details.data, dropTargetWeekday));
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
}

class _WeekTemplateTaskCard extends StatelessWidget {
  const _WeekTemplateTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    this.dragSlotWrapper,
  });

  final WeekTemplateTask task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Widget Function(Widget child)? dragSlotWrapper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dur = task.durationMinutes;
    final body = Material(
      color: DesignTokens.slate800,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: DesignTokens.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (dur != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$dur dk',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: DesignTokens.slate400,
                        ),
                      ),
                    ],
                    if (task.notes != null && task.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: DesignTokens.slate500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 22),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
    if (dragSlotWrapper != null) {
      return dragSlotWrapper!(body);
    }
    return body;
  }
}
