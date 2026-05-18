import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/recurring_template_repository.dart';
import '../../plan_day_labels.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/planner_top_bar.dart';

class RecurringTemplatesScreen extends StatefulWidget {
  const RecurringTemplatesScreen({super.key});

  @override
  State<RecurringTemplatesScreen> createState() =>
      _RecurringTemplatesScreenState();
}

class _RecurringTemplatesScreenState extends State<RecurringTemplatesScreen> {
  List<RecurringTemplate> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final repo = context.read<RecurringTemplateRepository>();
    final list = await repo.getAllTemplates();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  String _dayLabel(int? tw) {
    if (tw == null || tw < 0 || tw >= kPlanDayLabels.length) {
      return 'Havuz';
    }
    return kPlanDayLabels[tw];
  }

  Future<void> _openEditor({RecurringTemplate? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final durCtrl = TextEditingController(
      text: existing?.durationMinutes?.toString() ?? '',
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var dayIndex = existing?.targetWeekday ?? 0;
    if (dayIndex < 0 || dayIndex > 7) {
      dayIndex = 0;
    }
    var active = (existing?.isActive ?? 1) == 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(existing == null ? 'Yeni tekrar' : 'Tekrarı düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Başlık'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Süre (dk), isteğe bağlı',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Not'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hedef',
                      style: Theme.of(ctx).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < kPlanDayLabels.length; i++)
                          ChoiceChip(
                            label: Text(kPlanDayLabels[i]),
                            selected: dayIndex == i,
                            onSelected: (_) => setLocal(() => dayIndex = i),
                          ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Aktif'),
                      value: active,
                      onChanged: (v) => setLocal(() => active = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dctx, false),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dctx, true),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !mounted) {
      titleCtrl.dispose();
      durCtrl.dispose();
      notesCtrl.dispose();
      return;
    }
    final title = titleCtrl.text.trim();
    if (title.isEmpty) {
      titleCtrl.dispose();
      durCtrl.dispose();
      notesCtrl.dispose();
      return;
    }
    int? duration;
    final ds = durCtrl.text.trim();
    if (ds.isNotEmpty) {
      duration = int.tryParse(ds);
    }
    final notesRaw = notesCtrl.text.trim();
    final now = DateTime.now().toUtc().toIso8601String();
    final repo = context.read<RecurringTemplateRepository>();
    if (existing == null) {
      await repo.insertTemplate(
        RecurringTemplatesCompanion.insert(
          title: title,
          durationMinutes: duration == null
              ? const Value.absent()
              : Value(duration),
          notes: notesRaw.isEmpty ? const Value.absent() : Value(notesRaw),
          targetWeekday: dayIndex == 0
              ? const Value.absent()
              : Value(dayIndex),
          isActive: Value(active ? 1 : 0),
          createdAt: now,
        ),
      );
    } else {
      await repo.updateTemplate(
        existing.id,
        RecurringTemplatesCompanion(
          title: Value(title),
          durationMinutes: duration == null
              ? const Value.absent()
              : Value(duration),
          notes: notesRaw.isEmpty ? const Value(null) : Value(notesRaw),
          targetWeekday: dayIndex == 0
              ? const Value(null)
              : Value(dayIndex),
          isActive: Value(active ? 1 : 0),
        ),
      );
    }
    titleCtrl.dispose();
    durCtrl.dispose();
    notesCtrl.dispose();
    await _reload();
  }

  Future<void> _confirmDelete(RecurringTemplate t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Sil'),
        content: Text('“${t.title}” silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<RecurringTemplateRepository>().deleteTemplate(t.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('recurring_templates_screen'),
      backgroundColor: DesignTokens.slate950,
      appBar: const PlannerTopBar(title: 'Tekrarlayan görevler'),
      floatingActionButton: FloatingActionButton(
        key: const Key('recurring_templates_new'),
        onPressed: () => unawaited(_openEditor()),
        backgroundColor: DesignTokens.blue600,
        foregroundColor: DesignTokens.white,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(
                    'Henüz tekrar yok',
                    key: const Key('recurring_templates_empty'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: DesignTokens.slate400,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: _items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = _items[i];
                    return ListTile(
                      key: Key('recurring_template_row_${t.id}'),
                      tileColor: DesignTokens.slate900.withValues(alpha: 0.65),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: DesignTokens.slate800),
                      ),
                      title: Text(
                        t.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: DesignTokens.slate200,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${_dayLabel(t.targetWeekday)} · '
                        '${t.isActive == 1 ? 'Aktif' : 'Kapalı'} · '
                        '${t.durationMinutes ?? '—'} dk',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DesignTokens.slate400,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: DesignTokens.slate400,
                        onPressed: () => unawaited(_confirmDelete(t)),
                      ),
                      onTap: () => unawaited(_openEditor(existing: t)),
                    );
                  },
                ),
    );
  }
}
