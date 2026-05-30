import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/periodic_reminder_repository.dart';
import '../../date/periodic_reminder_dates.dart';
import '../../models/periodic_reminder.dart';
import '../../models/periodic_reminder_completion.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/planner_dialogs.dart';
import 'periodic_reminder_editor_sheet.dart';

Future<void> showPeriodicReminderHistorySheet({
  required BuildContext context,
  required PeriodicReminder reminder,
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTokens.slate900,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _PeriodicReminderHistorySheet(
      reminder: reminder,
      onChanged: onChanged,
    ),
  );
}

class _PeriodicReminderHistorySheet extends StatefulWidget {
  const _PeriodicReminderHistorySheet({
    required this.reminder,
    required this.onChanged,
  });

  final PeriodicReminder reminder;
  final VoidCallback onChanged;

  @override
  State<_PeriodicReminderHistorySheet> createState() =>
      _PeriodicReminderHistorySheetState();
}

class _PeriodicReminderHistorySheetState
    extends State<_PeriodicReminderHistorySheet> {
  List<PeriodicReminderCompletion> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = context.read<PeriodicReminderRepository>();
    final items = await repo.getCompletionsForReminder(widget.reminder.id);
    if (!mounted) return;
    setState(() {
      _history = items;
      _loading = false;
    });
  }

  Future<void> _editReminder() async {
    final result = await showPeriodicReminderEditor(
      context: context,
      existingTitle: widget.reminder.title,
      existingIntervalDays: widget.reminder.intervalDays,
    );
    if (result == null || !mounted) return;
    await context.read<PeriodicReminderRepository>().updateReminder(
          widget.reminder.id,
          title: result.title,
          intervalDays: result.intervalDays,
          nextDueDate: widget.reminder.nextDueDate,
        );
    if (!mounted) return;
    widget.onChanged();
    if (!mounted) return;
    showPlannerSnackBar(context, 'Güncellendi');
    Navigator.of(context).pop();
  }

  Future<void> _undoCompletion(PeriodicReminderCompletion entry) async {
    final ok = await PlannerDialogs.confirmDelete(
      context,
      title: 'Kayıt silinsin mi?',
      message:
          '«${formatCompletedAtLabel(entry.completedAt)}» yapılış kaydı silinir; '
          'son tarih ve sıradaki gün yeniden hesaplanır.',
    );
    if (ok != true || !mounted) return;

    final repo = context.read<PeriodicReminderRepository>();
    await repo.deleteCompletion(entry.id);
    if (!mounted) return;
    widget.onChanged();
    await _load();
    if (!mounted) return;
    showPlannerSnackBar(context, 'Kayıt güncellendi');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final lastLabel = formatLastCompletedLabel(widget.reminder.lastCompletedAt);
    final daysLeft = daysUntilDue(widget.reminder.nextDueDate);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.slate700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.reminder.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: DesignTokens.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lastLabel != null
                ? 'Son yapılış: $lastLabel · ${formatDaysRemaining(daysLeft)}'
                : 'Henüz yapılmadı · ${formatDaysRemaining(daysLeft)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DesignTokens.slate400,
            ),
          ),
          Text(
            'Her ${formatIntervalLabel(widget.reminder.intervalDays)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.slate500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('periodic_history_edit'),
                  onPressed: _editReminder,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Düzenle'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Geçmiş',
            style: theme.textTheme.titleSmall?.copyWith(
              color: DesignTokens.slate300,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Henüz «Yaptım» kaydı yok.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.slate500,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.42,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final entry = _history[index];
                  final isLatest = index == 0;
                  return ListTile(
                    key: Key('periodic_history_${entry.id}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      formatCompletedAtLabel(entry.completedAt),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.slate200,
                      ),
                    ),
                    subtitle: entry.previousNextDueDate != null
                        ? Text(
                            'Önceki hedef: ${entry.previousNextDueDate}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: DesignTokens.slate600,
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      tooltip: isLatest
                          ? 'Son kaydı geri al'
                          : 'Bu kaydı sil',
                      icon: Icon(
                        isLatest ? Icons.undo : Icons.delete_outline,
                        color: DesignTokens.slate400,
                      ),
                      onPressed: () => _undoCompletion(entry),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
