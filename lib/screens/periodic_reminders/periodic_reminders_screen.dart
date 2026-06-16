import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/periodic_reminder_companion.dart';
import '../../data/repositories/periodic_reminder_repository.dart';
import '../../date/periodic_reminder_dates.dart';
import '../../models/periodic_reminder.dart';
import '../../theme/design_tokens.dart';
import '../../theme/planner_shell_layout.dart';
import '../../widgets/planner_dialogs.dart';
import '../../widgets/planner_empty_state.dart';
import '../../widgets/planner_top_bar.dart';
import 'periodic_reminder_editor_sheet.dart';
import 'periodic_reminder_history_sheet.dart';

class PeriodicRemindersScreen extends StatefulWidget {
  const PeriodicRemindersScreen({super.key});

  @override
  State<PeriodicRemindersScreen> createState() =>
      _PeriodicRemindersScreenState();
}

class _PeriodicRemindersScreenState extends State<PeriodicRemindersScreen> {
  List<PeriodicReminder> _items = [];
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final repo = context.read<PeriodicReminderRepository>();
      final items = await repo.getAllSortedByDueDate();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _openEditor({PeriodicReminder? existing}) async {
    final result = await showPeriodicReminderEditor(
      context: context,
      existingTitle: existing?.title,
      existingIntervalDays: existing?.intervalDays,
    );
    if (result == null || !mounted) return;

    final repo = context.read<PeriodicReminderRepository>();
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      if (existing == null) {
        await repo.insertReminder(
          PeriodicReminderCompanion.insert(
            title: result.title,
            intervalDays: result.intervalDays,
            nextDueDate: nextDueAfterInterval(result.intervalDays),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await repo.updateReminder(
          existing.id,
          title: result.title,
          intervalDays: result.intervalDays,
          nextDueDate: existing.nextDueDate,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showPlannerErrorSnackBar(context, 'Kaydedilemedi: $e');
      return;
    }
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    showPlannerSnackBar(
      context,
      existing == null ? 'Hatırlatıcı eklendi' : 'Güncellendi',
    );
  }

  Future<void> _openHistory(PeriodicReminder item) async {
    await showPeriodicReminderHistorySheet(
      context: context,
      reminder: item,
      onChanged: () => unawaited(_reload()),
    );
    if (!mounted) return;
    await _reload();
  }

  Future<void> _markDone(PeriodicReminder item) async {
    await context.read<PeriodicReminderRepository>().markCompleted(item.id);
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    PeriodicReminder? updated;
    for (final e in _items) {
      if (e.id == item.id) {
        updated = e;
        break;
      }
    }
    final daysLeft = updated != null
        ? daysUntilDue(updated.nextDueDate)
        : item.intervalDays;
    showPlannerSnackBar(
      context,
      '${item.title}: ${formatDaysRemaining(daysLeft)}',
    );
  }

  Future<void> _undoLastDone(PeriodicReminder item) async {
    final ok = await PlannerDialogs.confirmDelete(
      context,
      title: 'Son yapılışı geri al?',
      message:
          'Yanlışlıkla «Yaptım» dediysen son kayıt silinir; sıradaki gün eski haline döner.',
    );
    if (ok != true || !mounted) return;
    final undone =
        await context.read<PeriodicReminderRepository>().undoLastCompletion(
              item.id,
            );
    if (!mounted) return;
    if (!undone) {
      showPlannerErrorSnackBar(context, 'Geri alınacak kayıt yok');
      return;
    }
    await _reload();
    if (!mounted) return;
    showPlannerSnackBar(context, 'Son yapılış geri alındı');
  }

  Future<void> _confirmDelete(PeriodicReminder item) async {
    final ok = await PlannerDialogs.confirmDelete(
      context,
      title: 'Silinsin mi?',
      message: '“${item.title}” kalıcı olarak silinir.',
    );
    if (ok != true || !mounted) return;
    await context.read<PeriodicReminderRepository>().deleteReminder(item.id);
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('periodic_reminders_screen'),
      appBar: const PlannerTopBar(title: 'Hatırlatıcılar'),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: plannerShellFabBottomPadding(context),
        ),
        child: FloatingActionButton.extended(
          key: const Key('periodic_reminders_add_fab'),
          onPressed: () => unawaited(_openEditor()),
          backgroundColor: DesignTokens.blue600,
          foregroundColor: DesignTokens.white,
          elevation: 8,
          icon: const Icon(Icons.add),
          label: const Text('Ekle'),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            const LinearProgressIndicator(
              key: Key('periodic_reminders_loading_bar'),
              minHeight: 2,
              backgroundColor: DesignTokens.slate900,
              color: DesignTokens.blue500,
            ),
          Expanded(
            child: _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hatırlatıcılar yüklenemedi.\n$_loadError',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: DesignTokens.slate500),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => unawaited(_reload()),
                            child: const Text('Tekrar dene'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    children: [
                      if (_items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: PlannerEmptyState(
                            testKey: const Key('periodic_reminders_empty'),
                            icon: Icons.event_repeat,
                            title: 'Periyodik iş ekle',
                            subtitle:
                                'Başlık + kaç günde bir (örn. 14, 180)',
                            actionLabel: 'İlk hatırlatıcıyı ekle',
                            onAction: () => unawaited(_openEditor()),
                          ),
                        ),
                      for (final item in _items)
                        _ReminderRow(
                          item: item,
                          onTap: () => unawaited(_openHistory(item)),
                          onDone: () => unawaited(_markDone(item)),
                          onEdit: () => unawaited(_openEditor(existing: item)),
                          onUndoLast: item.lastCompletedAt != null
                              ? () => unawaited(_undoLastDone(item))
                              : null,
                          onDelete: () => unawaited(_confirmDelete(item)),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.item,
    required this.onTap,
    required this.onDone,
    required this.onEdit,
    required this.onUndoLast,
    required this.onDelete,
  });

  final PeriodicReminder item;
  final VoidCallback onTap;
  final VoidCallback onDone;
  final VoidCallback onEdit;
  final VoidCallback? onUndoLast;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft = daysUntilDue(item.nextDueDate);
    final remainingText = formatDaysRemaining(daysLeft);
    final overdue = daysLeft < 0;
    final dueToday = daysLeft == 0;
    final lastDone = formatLastCompletedLabel(item.lastCompletedAt);

    Color statusColor = DesignTokens.slate400;
    if (overdue) {
      statusColor = const Color(0xFFF97316);
    } else if (dueToday) {
      statusColor = DesignTokens.blue400;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: DesignTokens.slate900,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        key: Key('periodic_reminder_title_${item.id}'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: DesignTokens.slate200,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remainingText,
                        key: Key('periodic_reminder_days_${item.id}'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastDone != null
                            ? 'Son yapılış: $lastDone'
                            : 'Henüz yapılmadı',
                        key: Key('periodic_reminder_last_${item.id}'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DesignTokens.slate500,
                        ),
                      ),
                      Text(
                        'Her ${formatIntervalLabel(item.intervalDays)} · Geçmiş için dokun',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DesignTokens.slate600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('periodic_reminder_done_${item.id}'),
                  tooltip: 'Yaptım',
                  onPressed: onDone,
                  icon: const Icon(Icons.check_circle_outline),
                  color: const Color(0xFF22C55E),
                ),
                PopupMenuButton<String>(
                  key: Key('periodic_reminder_menu_${item.id}'),
                  icon: const Icon(Icons.more_vert, color: DesignTokens.slate400),
                  color: DesignTokens.slate900,
                  onSelected: (value) {
                    switch (value) {
                      case 'history':
                        onTap();
                      case 'edit':
                        onEdit();
                      case 'undo':
                        onUndoLast?.call();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'history',
                      child: Text('Geçmiş'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Düzenle'),
                    ),
                    if (onUndoLast != null)
                      const PopupMenuItem(
                        value: 'undo',
                        child: Text('Son yapılışı geri al'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Sil'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
