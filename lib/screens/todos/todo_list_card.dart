import 'package:flutter/material.dart';

import '../../models/todo_category.dart';
import '../../models/todo_item.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/planner_color_chip.dart';
class TodoListCard extends StatelessWidget {
  const TodoListCard({
    super.key,
    required this.todo,
    this.category,
    required this.onTap,
    required this.onToggleDone,
    required this.onDelete,
  });

  final TodoItem todo;
  final TodoCategory? category;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stripe = category?.colorArgb != null
        ? Color(category!.colorArgb!)
        : DesignTokens.blue500;
    final deadline = todo.deadlineDate;

    return Material(
      color: DesignTokens.slate900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: DesignTokens.slate800),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: stripe),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.slate200,
                          decoration:
                              todo.isDone ? TextDecoration.lineThrough : null,
                          decorationColor: DesignTokens.slate500,
                        ),
                      ),
                      if (category != null || deadline != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (category != null)
                              PlannerColorChip(
                                label: category!.name,
                                color: Color(category!.colorArgb ?? 0xFF64748B),
                                compact: true,
                              ),
                            if (deadline != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event,
                                    size: 12,
                                    color: _deadlineColor(deadline),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDeadline(deadline),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: _deadlineColor(deadline),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    key: Key('todo_done_${todo.id}'),
                    onPressed: onToggleDone,
                    icon: Icon(
                      todo.isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      color: todo.isDone
                          ? DesignTokens.green500
                          : DesignTokens.slate500,
                      size: 22,
                    ),
                  ),
                  IconButton(
                    key: Key('todo_delete_${todo.id}'),
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: DesignTokens.slate600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _deadlineColor(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return DesignTokens.slate400;
    final today = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final now = DateTime(today.year, today.month, today.day);
    if (day.isBefore(now)) return const Color(0xFFEF4444);
    if (day == now) return DesignTokens.amber500;
    return DesignTokens.slate400;
  }

  static String _formatDeadline(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
