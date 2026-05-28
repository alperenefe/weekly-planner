import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class BoardColumn extends StatelessWidget {
  const BoardColumn({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeCount,
    required this.width,
    required this.child,
    this.subdued = false,
    this.titleHighlightToday = false,
    this.doneCount,
    this.taskCount,
  });

  final String title;
  final String? subtitle;
  final int? badgeCount;
  final double width;
  final Widget child;
  final bool subdued;
  final bool titleHighlightToday;
  final int? doneCount;
  final int? taskCount;

  @override
  Widget build(BuildContext context) {
    final isToday = titleHighlightToday;
    final column = SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isToday
              ? DesignTokens.slate800.withValues(alpha: 0.95)
              : DesignTokens.slate900.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? DesignTokens.blue500 : DesignTokens.slate800,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (isToday)
                    Container(
                      key: Key('board_col_today_dot_$title'),
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: DesignTokens.blue500,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      title,
                      key: Key('board_col_title_$title'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isToday
                                ? DesignTokens.blue400
                                : DesignTokens.slate200,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            height: 28 / 18,
                          ),
                    ),
                  ),
                  if (badgeCount != null)
                    Container(
                      key: Key('board_col_badge_$title'),
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.space2,
                        vertical: DesignTokens.space1,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.slate800,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeCount == 0
                              ? DesignTokens.slate500
                              : DesignTokens.slate400,
                        ),
                      ),
                    ),
                ],
              ),
              if (subtitle != null) ...[
                SizedBox(height: DesignTokens.space1),
                Text(
                  subtitle!,
                  key: Key('board_col_sub_$title'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isToday
                            ? DesignTokens.blue400.withValues(alpha: 0.85)
                            : DesignTokens.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: isToday ? 0.2 : 1.2,
                        fontSize: 12,
                      ),
                ),
              ],
              if (taskCount != null && taskCount! > 0) ...[
                SizedBox(height: DesignTokens.space1),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    key: Key('board_col_progress_$title'),
                    value: (doneCount ?? 0) / taskCount!,
                    minHeight: 4,
                    backgroundColor: DesignTokens.slate800,
                    color: isToday
                        ? DesignTokens.blue600
                        : DesignTokens.slate600,
                  ),
                ),
              ],
              SizedBox(height: DesignTokens.space2),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
    if (subdued) {
      return Opacity(opacity: 0.7, child: column);
    }
    return column;
  }
}
