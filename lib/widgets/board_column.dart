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
  });

  final String title;
  final String? subtitle;
  final int? badgeCount;
  final double width;
  final Widget child;
  final bool subdued;
  final bool titleHighlightToday;

  @override
  Widget build(BuildContext context) {
    final column = SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DesignTokens.slate900.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.slate800),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      key: Key('board_col_title_$title'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: titleHighlightToday
                                ? DesignTokens.blue400
                                : DesignTokens.slate200,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            height: 28 / 18,
                            decoration: titleHighlightToday
                                ? TextDecoration.underline
                                : null,
                            decorationColor: titleHighlightToday
                                ? DesignTokens.blue400
                                : null,
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
                        color: DesignTokens.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 12,
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
