import 'package:flutter/material.dart';

import '../../plan_day_labels.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/planner_dialogs.dart';
import '../../widgets/planner_sheet_handle.dart';

class WeekTemplateTaskEditorResult {
  const WeekTemplateTaskEditorResult({
    required this.title,
    this.durationMinutes,
    this.notes,
    required this.targetWeekday,
  });

  final String title;
  final int? durationMinutes;
  final String? notes;
  /// `null` = havuz; 1–7 = Pazartesi–Pazar.
  final int? targetWeekday;
}

Future<WeekTemplateTaskEditorResult?> showWeekTemplateTaskEditorSheet({
  required BuildContext context,
  WeekTemplateTaskEditorResult? initial,
}) {
  return showModalBottomSheet<WeekTemplateTaskEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _WeekTemplateTaskEditorSheet(initial: initial),
      );
    },
  );
}

class _WeekTemplateTaskEditorSheet extends StatefulWidget {
  const _WeekTemplateTaskEditorSheet({this.initial});

  final WeekTemplateTaskEditorResult? initial;

  @override
  State<_WeekTemplateTaskEditorSheet> createState() =>
      _WeekTemplateTaskEditorSheetState();
}

class _WeekTemplateTaskEditorSheetState
    extends State<_WeekTemplateTaskEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _duration;
  late final TextEditingController _notes;
  late int _selectedDayIndex;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _duration = TextEditingController(
      text: initial?.durationMinutes?.toString() ?? '',
    );
    _notes = TextEditingController(text: initial?.notes ?? '');
    _selectedDayIndex = _dayIndexFromTargetWeekday(initial?.targetWeekday);
  }

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  int _dayIndexFromTargetWeekday(int? tw) {
    if (tw == null) return 0;
    if (tw < 1 || tw > 7) return 0;
    return tw;
  }

  int? _targetWeekdayFromDayIndex(int index) {
    if (index == 0) return null;
    return index;
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      showPlannerErrorSnackBar(context, 'Başlık girmelisin');
      return;
    }
    int? duration;
    final ds = _duration.text.trim();
    if (ds.isNotEmpty) {
      duration = int.tryParse(ds);
      if (duration == null) {
        showPlannerErrorSnackBar(context, 'Süre sayı olmalı');
        return;
      }
    }
    final notesRaw = _notes.text.trim();
    if (!mounted) return;
    Navigator.of(context).pop(
      WeekTemplateTaskEditorResult(
        title: title,
        durationMinutes: duration,
        notes: notesRaw.isEmpty ? null : notesRaw,
        targetWeekday: _targetWeekdayFromDayIndex(_selectedDayIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const Key('week_template_task_editor_sheet'),
      color: DesignTokens.slate950,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PlannerSheetHandle(),
              Text(
                _isEdit ? 'Görevi düzenle' : 'Görev ekle',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('week_tpl_task_title'),
                controller: _title,
                autofocus: !_isEdit,
                style: const TextStyle(color: DesignTokens.white),
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  labelStyle: TextStyle(color: DesignTokens.slate400),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('week_tpl_task_duration'),
                controller: _duration,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: DesignTokens.white),
                decoration: const InputDecoration(
                  labelText: 'Süre (dk, isteğe bağlı)',
                  labelStyle: TextStyle(color: DesignTokens.slate400),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('week_tpl_task_notes'),
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(color: DesignTokens.white),
                decoration: const InputDecoration(
                  labelText: 'Notlar (isteğe bağlı)',
                  labelStyle: TextStyle(color: DesignTokens.slate400),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Gün',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: DesignTokens.slate400,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < kPlanDayLabels.length; i++)
                    FilterChip(
                      key: Key('week_tpl_day_$i'),
                      label: Text(kPlanDayLabels[i]),
                      selected: _selectedDayIndex == i,
                      onSelected: (_) => setState(() => _selectedDayIndex = i),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('week_tpl_task_save_btn'),
                onPressed: _save,
                child: Text(_isEdit ? 'Kaydet' : 'Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
