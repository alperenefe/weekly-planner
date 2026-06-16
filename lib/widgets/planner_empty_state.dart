import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// TickTick tarzı boş ekran: ikon + kısa metin + isteğe bağlı CTA.
class PlannerEmptyState extends StatelessWidget {
  const PlannerEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.testKey,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? testKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = Column(
      key: testKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: DesignTokens.blue600.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: DesignTokens.blue500.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(icon, size: 36, color: DesignTokens.blue400),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: DesignTokens.slate200,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DesignTokens.slate500,
              height: 1.45,
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 20),
            label: Text(actionLabel!),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.blue600,
              foregroundColor: DesignTokens.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ],
    );

    return Padding(padding: const EdgeInsets.all(24), child: body);
  }
}

/// Ayarlar alt ekranları: geri + başlık.
class PlannerSubScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PlannerSubScreenAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DesignTokens.slate950,
      foregroundColor: DesignTokens.white,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
