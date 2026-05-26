import 'package:flutter/material.dart';

import '../date/week_calendar.dart';
import '../theme/design_tokens.dart';

/// Etkinlik sheet’lerinde hatırlatıcı aç/kapa + saat seçici.
class TaskReminderRow extends StatelessWidget {
  const TaskReminderRow({
    super.key,
    required this.enabled,
    required this.minutesOfDay,
    required this.onEnabledChanged,
    required this.onPickTime,
  });

  final bool enabled;
  final int minutesOfDay;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('task_reminder_toggle'),
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Hatırlatıcı',
            style: theme.textTheme.titleSmall?.copyWith(
              color: DesignTokens.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            enabled
                ? formatClockMinutes(minutesOfDay)
                : 'Kapalı — bildirim gönderilmez',
            style: theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.slate400,
            ),
          ),
          value: enabled,
          onChanged: onEnabledChanged,
          activeThumbColor: DesignTokens.blue400,
        ),
        if (enabled) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('task_reminder_pick_time'),
              onPressed: onPickTime,
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: Text('Saat: ${formatClockMinutes(minutesOfDay)}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.blue400,
                side: const BorderSide(color: DesignTokens.slate700),
              ),
            ),
          ),
        ],
      ],
      ),
    );
  }
}
