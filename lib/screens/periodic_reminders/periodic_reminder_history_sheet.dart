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
  late PeriodicReminder _reminder;
  List<PeriodicReminderCompletion> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reminder = widget.reminder;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = context.read<PeriodicReminderRepository>();
    final items = await repo.getCompletionsForReminder(_reminder.id);
    final fresh = await repo.getReminderById(_reminder.id);
    if (!mounted) return;
    setState(() {
      _history = items;
      if (fresh != null) _reminder = fresh;
      _loading = false;
    });
  }

  Future<void> _editReminder() async {
    final result = await showPeriodicReminderEditor(
      context: context,
      existingTitle: _reminder.title,
      existingIntervalDays: _reminder.intervalDays,
    );
    if (result == null || !mounted) return;
    await context.read<PeriodicReminderRepository>().updateReminder(
          _reminder.id,
          title: result.title,
          intervalDays: result.intervalDays,
          nextDueDate: _reminder.nextDueDate,
        );
    if (!mounted) return;
    widget.onChanged();
    if (!mounted) return;
    showPlannerSnackBar(context, 'Güncellendi');
    Navigator.of(context).pop();
  }

  Future<void> _editCompletionDate(PeriodicReminderCompletion entry) async {
    final local = parseCompletedAtLocal(entry.completedAt) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: local,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'Yapılış tarihi',
      cancelText: 'İptal',
      confirmText: 'Tamam',
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(local),
      helpText: 'Yapılış saati',
      cancelText: 'İptal',
      confirmText: 'Tamam',
    );
    if (pickedTime == null || !mounted) return;

    final updatedLocal = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    if (updatedLocal.isAfter(DateTime.now())) {
      if (!mounted) return;
      showPlannerErrorSnackBar(context, 'Gelecek tarih seçilemez');
      return;
    }

    await context.read<PeriodicReminderRepository>().updateCompletionCompletedAt(
          entry.id,
          updatedLocal.toUtc().toIso8601String(),
        );
    if (!mounted) return;
    widget.onChanged();
    await _load();
    if (!mounted) return;
    showPlannerSnackBar(context, 'Tarih güncellendi');
  }

  Future<void> _deleteCompletion(PeriodicReminderCompletion entry) async {
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
    showPlannerSnackBar(context, 'Kayıt silindi');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final lastLabel = formatLastCompletedLabel(_reminder.lastCompletedAt);
    final daysLeft = daysUntilDue(_reminder.nextDueDate);

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
            _reminder.title,
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
            'Her ${formatIntervalLabel(_reminder.intervalDays)}',
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
              color: DesignTokens.slate400,
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
                  return ListTile(
                    key: Key('periodic_history_${entry.id}'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _editCompletionDate(entry),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('periodic_history_edit_date_${entry.id}'),
                          tooltip: 'Tarihi değiştir',
                          icon: const Icon(Icons.edit_calendar_outlined),
                          color: DesignTokens.slate400,
                          onPressed: () => _editCompletionDate(entry),
                        ),
                        IconButton(
                          key: Key('periodic_history_delete_${entry.id}'),
                          tooltip: 'Kaydı sil',
                          icon: const Icon(Icons.delete_outline),
                          color: DesignTokens.slate400,
                          onPressed: () => _deleteCompletion(entry),
                        ),
                      ],
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
