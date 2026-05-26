import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../date/week_calendar.dart';
import '../data/db/app_database.dart';
import '../services/task_focus_timer_controller.dart';
import '../theme/design_tokens.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onMarkDone,
    this.weekMondayIso,
    this.onUnmarkDone,
    this.onMarkSkipped,
    this.onUnmarkSkipped,
    this.onQuickMove,
    this.onBodyTap,
    this.onDelete,
    this.dragSlotWrapper,
  });

  final Task task;
  /// Havuzda hafta dışı `planned_date` uyarısı için (plan ekranı).
  final String? weekMondayIso;
  final Future<void> Function() onMarkDone;
  final Future<void> Function()? onUnmarkDone;
  final Future<void> Function()? onMarkSkipped;
  final Future<void> Function()? onUnmarkSkipped;
  final VoidCallback? onQuickMove;
  final VoidCallback? onBodyTap;
  final Future<void> Function()? onDelete;
  final Widget Function(Widget dragBody)? dragSlotWrapper;

  bool get _inPool => task.plannedDate == null;

  bool get _plannedDateOutsideWeek {
    final w = weekMondayIso;
    final p = task.plannedDate;
    if (w == null || p == null) return false;
    return !isPlannedDateInWeek(w, p);
  }

  Color get _stripeColor {
    final custom = task.accentColor;
    if (custom != null) {
      return Color(custom);
    }
    if (_inPool) {
      return DesignTokens.slate600;
    }
    switch (task.status) {
      case 'done':
        return DesignTokens.green500;
      case 'skipped':
        return DesignTokens.amber500;
      default:
        return DesignTokens.blue500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = task.status == 'done';
    final planned = task.status == 'planned';
    final skipped = task.status == 'skipped';

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
      color: DesignTokens.white,
      decoration: isDone ? TextDecoration.lineThrough : null,
      decorationColor: DesignTokens.slate400,
    );

    Widget leadingControl() {
      if (planned) {
        return InkWell(
          key: Key('task_card_checkbox_${task.id}'),
          customBorder: const CircleBorder(),
          onTap: () async {
            await onMarkDone();
          },
          child: const Icon(
            Icons.radio_button_unchecked,
            size: 18,
            color: DesignTokens.slate500,
          ),
        );
      }
      if (isDone) {
        if (onUnmarkDone != null) {
          return InkWell(
            key: Key('task_card_unmark_done_${task.id}'),
            customBorder: const CircleBorder(),
            onTap: () async {
              await onUnmarkDone!();
            },
            child: Icon(
              Icons.check_circle,
              size: 18,
              color: DesignTokens.green500.withValues(alpha: 0.9),
            ),
          );
        }
        return Icon(
          Icons.check_circle,
          size: 18,
          color: DesignTokens.green500.withValues(alpha: 0.9),
        );
      }
      if (skipped) {
        if (onUnmarkSkipped != null) {
          return InkWell(
            key: Key('task_card_unmark_skipped_${task.id}'),
            customBorder: const CircleBorder(),
            onTap: () async {
              await onUnmarkSkipped!();
            },
            child: Icon(
              Icons.remove_circle_outline,
              size: 18,
              color: DesignTokens.amber500.withValues(alpha: 0.9),
            ),
          );
        }
        return Icon(
          Icons.remove_circle_outline,
          size: 18,
          color: DesignTokens.amber500.withValues(alpha: 0.9),
        );
      }
      return Icon(
        Icons.remove_circle_outline,
        size: 18,
        color: DesignTokens.amber500.withValues(alpha: 0.9),
      );
    }

    Widget timeChip() {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: _inPool ? DesignTokens.slate800 : const Color(0x4D1E3A8A),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          task.startMinutes != null
              ? formatClockMinutes(task.startMinutes!)
              : '—',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _inPool ? DesignTokens.slate400 : DesignTokens.blue400,
          ),
        ),
      );
    }

    Widget durationRow() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule,
            size: 12,
            color: DesignTokens.slate500,
          ),
          const SizedBox(width: 4),
          Text(
            task.durationMinutes != null
                ? '${task.durationMinutes} dk'
                : '—',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: DesignTokens.slate500,
            ),
          ),
        ],
      );
    }

    Widget focusSpentChip() {
      if (task.durationMinutes == null || task.durationMinutes! <= 0) {
        return const SizedBox.shrink();
      }
      return Selector<TaskFocusTimerController, int?>(
        selector: (_, c) {
          final goalSec = task.durationMinutes! * 60;
          final rem = c.budgetRemainingSeconds(
            taskId: task.id,
            goalTotalSeconds: goalSec,
          );
          if (rem >= goalSec) return null;
          final spentSec = goalSec - rem;
          final mins = (spentSec + 59) ~/ 60;
          return mins > 0 ? mins : null;
        },
        builder: (_, minsSpent, _) {
          if (minsSpent == null) return const SizedBox.shrink();
          return Container(
            key: Key('task_focus_spent_${task.id}'),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x3322C55E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$minsSpent dk odak',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: DesignTokens.green500,
              ),
            ),
          );
        },
      );
    }

    Widget focusRemainChip() {
      if (task.status != 'planned' ||
          task.durationMinutes == null ||
          task.durationMinutes! <= 0) {
        return const SizedBox.shrink();
      }
      return Selector<TaskFocusTimerController, int?>(
        selector: (_, c) {
          final goalSec = task.durationMinutes! * 60;
          final rem = c.budgetRemainingSeconds(
            taskId: task.id,
            goalTotalSeconds: goalSec,
          );
          if (rem >= goalSec) return null;
          final mins = (rem + 59) ~/ 60;
          return mins > 0 ? mins : null;
        },
        builder: (_, minsLeft, _) {
          if (minsLeft == null) return const SizedBox.shrink();
          return Container(
            key: Key('task_focus_remaining_${task.id}'),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x4D1E3A8A),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$minsLeft dk kaldı',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: DesignTokens.blue400,
              ),
            ),
          );
        },
      );
    }

    Widget titleAndMetaColumn() {
      final column = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            task.title,
            key: Key('task_title_${task.id}'),
            style: titleStyle,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.start,
            children: [
              timeChip(),
              durationRow(),
              focusSpentChip(),
              focusRemainChip(),
              if (_plannedDateOutsideWeek)
                Text(
                  'Tarih bu hafta dışında (${task.plannedDate})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: DesignTokens.amber500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      );
      final fullWidth = SizedBox(
        width: double.infinity,
        child: column,
      );
      if (onBodyTap != null) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBodyTap,
            child: fullWidth,
          ),
        );
      }
      return fullWidth;
    }

    final stackBody = Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: dragSlotWrapper != null
              ? const EdgeInsets.fromLTRB(0, 10, 10, 10)
              : const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: dragSlotWrapper != null
              ? titleAndMetaColumn()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: leadingControl(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: titleAndMetaColumn(),
                    ),
                  ],
                ),
        ),
        if (onQuickMove != null)
          Positioned(
            top: 4,
            right: onDelete != null ? 32 : 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: Key('task_card_move_${task.id}'),
                onTap: onQuickMove,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.swap_horiz,
                    size: 18,
                    color: DesignTokens.slate500,
                  ),
                ),
              ),
            ),
          ),
        if (planned && onMarkSkipped != null)
          Positioned(
            top: 4,
            right: onDelete != null
                ? (onQuickMove != null ? 58 : 32)
                : (onQuickMove != null ? 32 : 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: Key('task_card_skip_${task.id}'),
                onTap: () async {
                  await onMarkSkipped!();
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.skip_next,
                    size: 18,
                    color: DesignTokens.amber500,
                  ),
                ),
              ),
            ),
          ),
        if (onDelete != null)
          Positioned(
            bottom: 4,
            right: 4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: Key('task_card_delete_${task.id}'),
                onTap: () async {
                  await onDelete!();
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: DesignTokens.slate500.withValues(
                      alpha: 0.95,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (task.movedCount > 0)
          Positioned(
            top: 4,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xCC1E293B),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0x4D9A3412),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 10, height: 1),
                  ),
                  Text(
                    '${task.movedCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: DesignTokens.orange400,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: DesignTokens.slate900,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: _stripeColor),
              if (dragSlotWrapper != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: leadingControl(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: dragSlotWrapper!(stackBody),
                ),
              ] else ...[
                Expanded(
                  child: stackBody,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
