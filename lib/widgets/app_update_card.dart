import 'package:flutter/material.dart';

import '../l10n/app_update_strings.dart';
import '../services/app_distribution_update.dart';
import '../theme/design_tokens.dart';

/// Ayarlar — Firebase App Distribution guncelleme.
class AppUpdateCard extends StatefulWidget {
  const AppUpdateCard({super.key});

  @override
  State<AppUpdateCard> createState() => _AppUpdateCardState();
}

class _AppUpdateCardState extends State<AppUpdateCard> {
  var _busy = false;

  Future<void> _check() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await AppDistributionUpdate.checkFromApp();
    if (!mounted) return;
    setState(() => _busy = false);
    final msg = switch (result) {
      AppUpdateResult.upToDate => AppUpdateStrings.upToDate,
      AppUpdateResult.updateStarted => AppUpdateStrings.started,
      AppUpdateResult.debugBuild => AppUpdateStrings.debugOnly,
      AppUpdateResult.firebaseNotConfigured => AppUpdateStrings.firebaseMissing,
      AppUpdateResult.failed => AppUpdateStrings.failed,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          key: const Key('settings_app_update_row'),
          leading: const Icon(
            Icons.system_update_rounded,
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
            ),
          ),
          trailing: _busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.download_rounded),
                  tooltip: AppUpdateStrings.check,
                  onPressed: _check,
                ),
          onTap: _busy ? null : _check,
        ),
      ],
    );
  }
}
