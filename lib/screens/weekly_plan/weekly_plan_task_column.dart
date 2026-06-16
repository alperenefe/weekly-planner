import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/db/app_database.dart';
import '../../models/task_kind.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/day_events_collapsible_strip.dart';
import '../../widgets/task_card.dart';
import 'weekly_plan_board_scroll.dart';

class WeeklyPlanTaskColumn extends StatelessWidget {
  const WeeklyPlanTaskColumn({
    super.key,
    required this.tasks,
    this.weekMondayIso,
    required this.columnKeySuffix,
    required this.dropPlannedIso,
    required this.dragFeedbackCardWidth,
    required this.onEditTask,
    required this.onMarkDone,
    required this.onUnmarkDone,
    this.onMarkSkipped,
    this.onUnmarkSkipped,
    this.onQuickMove,
    required this.onDropFromDrag,
    required this.onDragUpdate,
  });

  final List<Task> tasks;
  final String? weekMondayIso;
  final String columnKeySuffix;
  final String? dropPlannedIso;
  final double dragFeedbackCardWidth;
  final Future<void> Function(Task task) onEditTask;
  final Future<void> Function(Task task) onMarkDone;
  final Future<void> Function(Task task) onUnmarkDone;
  final Future<void> Function(Task task)? onMarkSkipped;
  final Future<void> Function(Task task)? onUnmarkSkipped;
  final Future<void> Function(Task task)? onQuickMove;
  final Future<void> Function(Task task, String? dropIso) onDropFromDrag;
  final void Function(DragUpdateDetails details) onDragUpdate;

  bool get _isPool => columnKeySuffix == 'Havuz';

  @override
  Widget build(BuildContext context) {
    final workTasks = tasks.where(TaskKind.isWork).toList();
    final eventTasks = tasks.where(TaskKind.isEvent).toList();

    Widget buildCard(
      Task t, {
      required bool omitKey,
      required bool withDragSlot,
    }) {
      return TaskCard(
        key: omitKey ? null : Key('task_card_${t.id}'),
        task: t,
        weekMondayIso: weekMondayIso,
        onBodyTap: () {
          unawaited(onEditTask(t));
        },
        onMarkDone: () async {
          await onMarkDone(t);
        },
        onUnmarkDone: () async {
          await onUnmarkDone(t);
        },
        onMarkSkipped: onMarkSkipped == null
            ? null
            : () async {
                await onMarkSkipped!(t);
              },
        onUnmarkSkipped: onUnmarkSkipped == null
            ? null
            : () async {
                await onUnmarkSkipped!(t);
              },
        onQuickMove: onQuickMove == null
            ? null
            : () {
                unawaited(onQuickMove!(t));
              },
        dragSlotWrapper: withDragSlot
            ? (Widget dragBody) {
                return LongPressDraggable<Task>(
                  key: Key('task_drag_${t.id}'),
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
                        child: buildCard(
                          t,
                          omitKey: true,
                          withDragSlot: false,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.4,
                    child: buildCard(
                      t,
                      omitKey: true,
                      withDragSlot: false,
                    ),
                  ),
                  child: dragBody,
                );
              }
            : null,
      );
    }

    Widget taskList(List<Task> list) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: DesignTokens.space2),
        itemBuilder: (context, i) {
          final task = list[i];
          return buildCard(task, omitKey: false, withDragSlot: true);
        },
      );
    }

    Widget sectionLabel(String label, IconData icon) {
      return Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.space2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: DesignTokens.slate500),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: DesignTokens.slate500,
              ),
            ),
          ],
        ),
      );
    }

    Widget inner;
    if (tasks.isEmpty) {
      inner = WeeklyPlanEmptyColumnPlaceholder(
        label: _isPool ? 'Boş' : '',
        testKey: 'weekly_plan_empty_$columnKeySuffix',
      );
    } else if (_isPool) {
      inner = taskList(tasks);
    } else {
      final children = <Widget>[];
      if (eventTasks.isNotEmpty) {
        children.add(
          DayEventsCollapsibleStrip(
            events: eventTasks,
            columnKeySuffix: columnKeySuffix,
            itemBuilder: (t) =>
                buildCard(t, omitKey: false, withDragSlot: true),
          ),
        );
      }
      if (workTasks.isNotEmpty) {
        if (eventTasks.isNotEmpty) {
          children.add(SizedBox(height: DesignTokens.space3));
        }
        children.add(sectionLabel('İşler', Icons.work_outline_rounded));
        children.add(taskList(workTasks));
      }
      inner = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) =>
          details.data.plannedDate != dropPlannedIso,
      onAcceptWithDetails: (details) {
        unawaited(onDropFromDrag(details.data, dropPlannedIso));
      },
      builder: (context, candidateData, rejected) {
        final highlight = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: highlight
                ? DesignTokens.blue500.withValues(alpha: 0.1)
                : Colors.transparent,
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
