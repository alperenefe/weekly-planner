import 'package:flutter/material.dart';

import '../l10n/app_update_strings.dart';
import '../theme/design_tokens.dart';

/// Uzaktan guncelleme PC'den (kablosuz adb) — telefonda indirme yok.
class AppUpdateCard extends StatelessWidget {
  const AppUpdateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          key: const Key('settings_app_update_row'),
          leading: const Icon(
            Icons.lan_rounded,
            color: DesignTokens.blue400,
          ),
          tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: DesignTokens.slate800),
          ),
          title: Text(
            AppUpdateStrings.section,
            style: theme.textTheme.titleSmall?.copyWith(
              color: DesignTokens.slate200,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            AppUpdateStrings.hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.slate400,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
