import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class WeekNavigationBar extends StatelessWidget {
  const WeekNavigationBar({
    super.key,
    required this.label,
    this.onPrevious,
    this.onNext,
    this.trailingAction,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: DesignTokens.slate200,
        );
    return Material(
      color: DesignTokens.slate950.withValues(alpha: 0.95),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: DesignTokens.slate800),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space2,
            vertical: DesignTokens.space2,
          ),
          child: Row(
            children: [
              IconButton(
                key: const Key('week_nav_prev'),
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
                color: DesignTokens.slate200,
              ),
              Expanded(
                child: Text(
                  label,
                  key: const Key('week_nav_label'),
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
              ?trailingAction,
              IconButton(
                key: const Key('week_nav_next'),
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                color: DesignTokens.slate200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
