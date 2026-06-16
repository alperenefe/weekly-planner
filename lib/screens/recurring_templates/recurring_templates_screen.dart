import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/recurring_template_repository.dart';
import '../../plan_day_labels.dart';
import '../../theme/design_tokens.dart';
import '../../theme/planner_shell_layout.dart';
import '../../widgets/planner_dialogs.dart';
import '../../widgets/planner_empty_state.dart';

class RecurringTemplatesScreen extends StatefulWidget {
  const RecurringTemplatesScreen({super.key});

  @override
  State<RecurringTemplatesScreen> createState() =>
      _RecurringTemplatesScreenState();
}

class _RecurringTemplatesScreenState extends State<RecurringTemplatesScreen> {
  List<RecurringTemplate> _items = [];
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
      final repo = context.read<RecurringTemplateRepository>();
      final list = await repo.getAllTemplates();
      if (!mounted) return;
      setState(() {
        _items = list;
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
    final ok = await PlannerDialogs.show<bool>(
      context,
      builder: (dctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final fieldStyle = PlannerDialogs.dialogFieldTextStyle;
            return PlannerDialogs.build(
              title: PlannerDialogs.titleText(
                existing == null
                    ? 'Yeni otomatik görev'
                    : 'Otomatik görevi düzenle',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: fieldStyle,
                      cursorColor: DesignTokens.blue400,
                      decoration: PlannerDialogs.fieldDecoration('Başlık'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durCtrl,
                      style: fieldStyle,
                      cursorColor: DesignTokens.blue400,
                      keyboardType: TextInputType.number,
                      decoration: PlannerDialogs.fieldDecoration(
                        'Süre (dk), isteğe bağlı',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      style: fieldStyle,
                      cursorColor: DesignTokens.blue400,
                      maxLines: 3,
                      decoration: PlannerDialogs.fieldDecoration('Not'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Hedef', style: PlannerDialogs.bodyTextStyle),
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
                      title: Text(
                        'Aktif',
                        style: PlannerDialogs.dialogFieldTextStyle,
                      ),
                      value: active,
                      onChanged: (v) => setLocal(() => active = v),
                    ),
                  ],
                ),
              ),
              actions: [
                PlannerDialogs.cancelAction(
                  dctx,
                  onPressed: () => Navigator.pop(dctx, false),
                ),
                PlannerDialogs.confirmAction(
                  dctx,
                  label: 'Kaydet',
                  onPressed: () => Navigator.pop(dctx, true),
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
    final ok = await PlannerDialogs.confirmDelete(
      context,
      title: 'Sil',
      message: '“${t.title}” silinsin mi?',
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
      appBar: const PlannerSubScreenAppBar(
        title: 'Her hafta otomatik görevler',
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: plannerShellFabBottomPadding(context),
        ),
        child: FloatingActionButton.extended(
          key: const Key('recurring_templates_new'),
          onPressed: () => unawaited(_openEditor()),
          backgroundColor: DesignTokens.blue600,
          foregroundColor: DesignTokens.white,
          icon: const Icon(Icons.add),
          label: const Text('Kural ekle'),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: DesignTokens.slate900,
              color: DesignTokens.blue500,
            ),
          Expanded(
            child: _loadError != null
                ? Center(
                    child: Text(
                      'Yüklenemedi.\n$_loadError',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: DesignTokens.slate500),
                    ),
                  )
                : _items.isEmpty
                    ? Center(
                        child: PlannerEmptyState(
                          testKey: const Key('recurring_templates_empty'),
                          icon: Icons.repeat_rounded,
                          title: 'Henüz otomatik görev yok',
                          subtitle:
                              'Örn. her Pazartesi «spor» veya her Perşembe «toplantı» '
                              'gibi kurallar yeni haftaya kendiliğinden eklenir.',
                          actionLabel: 'İlk kuralı ekle',
                          onAction: () => unawaited(_openEditor()),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          plannerShellFabBottomPadding(context) + 72,
                        ),
                  itemCount: _items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = _items[i];
                    return ListTile(
                      key: Key('recurring_template_row_${t.id}'),
                      leading: CircleAvatar(
                        backgroundColor: t.isActive == 1
                            ? DesignTokens.blue600.withValues(alpha: 0.2)
                            : DesignTokens.slate800,
                        child: Icon(
                          t.isActive == 1 ? Icons.repeat : Icons.pause_circle_outline,
                          color: t.isActive == 1
                              ? DesignTokens.blue400
                              : DesignTokens.slate500,
                          size: 22,
                        ),
                      ),
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
          ),
        ],
      ),
    );
  }
}
