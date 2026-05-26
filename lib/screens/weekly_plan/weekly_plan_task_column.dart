import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/db/app_database.dart';
import '../../theme/design_tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    final inner = tasks.isEmpty
        ? WeeklyPlanEmptyColumnPlaceholder(
            label: columnKeySuffix == 'Havuz' ? 'Boş' : 'Etkinlik yok',
            testKey: 'weekly_plan_empty_$columnKeySuffix',
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: DesignTokens.space2),
            itemBuilder: (context, i) {
              final task = tasks[i];
              Widget card(
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
                                  child: card(
                                    t,
                                    omitKey: true,
                                    withDragSlot: false,
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.4,
                              child: card(
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

              return card(task, omitKey: false, withDragSlot: true);
            },
          );

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
