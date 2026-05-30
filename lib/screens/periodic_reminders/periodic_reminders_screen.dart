import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/periodic_reminder_companion.dart';
import '../../data/repositories/periodic_reminder_repository.dart';
import '../../date/periodic_reminder_dates.dart';
import '../../models/periodic_reminder.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/planner_dialogs.dart';
import '../../widgets/planner_top_bar.dart';
import 'periodic_reminder_editor_sheet.dart';

class PeriodicRemindersScreen extends StatefulWidget {
  const PeriodicRemindersScreen({super.key});

  @override
  State<PeriodicRemindersScreen> createState() =>
      _PeriodicRemindersScreenState();
}

class _PeriodicRemindersScreenState extends State<PeriodicRemindersScreen> {
  List<PeriodicReminder> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_reload()));
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final repo = context.read<PeriodicReminderRepository>();
    final items = await repo.getAllSortedByDueDate();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
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

  Future<void> _markDone(PeriodicReminder item) async {
    await context.read<PeriodicReminderRepository>().markCompleted(item.id);
    if (!mounted) return;
    final message = '${item.title}: ${formatDaysRemaining(item.intervalDays)}';
    await _reload();
    if (!mounted) return;
    showPlannerSnackBar(context, message);
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
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('periodic_reminders_screen'),
      appBar: const PlannerTopBar(title: 'Hatırlatıcılar'),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          key: const Key('periodic_reminders_add_fab'),
          onPressed: () => unawaited(_openEditor()),
          icon: const Icon(Icons.add),
          label: const Text('Ekle'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('periodic_reminders_empty'),
                        onTap: () => unawaited(_openEditor()),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_repeat,
                                size: 48,
                                color: DesignTokens.slate600,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Periyodik iş ekle',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: DesignTokens.blue400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Başlık + kaç günde bir (örn. 14, 180)',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: DesignTokens.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                for (final item in _items)
                  _ReminderRow(
                    item: item,
                    onDone: () => unawaited(_markDone(item)),
                    onEdit: () => unawaited(_openEditor(existing: item)),
                    onDelete: () => unawaited(_confirmDelete(item)),
                  ),
              ],
            ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.item,
    required this.onDone,
    required this.onEdit,
    required this.onDelete,
  });

  final PeriodicReminder item;
  final VoidCallback onDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft = daysUntilDue(item.nextDueDate);
    final remainingText = formatDaysRemaining(daysLeft);
    final overdue = daysLeft < 0;
    final dueToday = daysLeft == 0;

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
                      'Her ${formatIntervalLabel(item.intervalDays)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.slate500,
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
                    case 'edit':
                      onEdit();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Düzenle'),
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
    );
  }
}
