import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/periodic_reminder.dart';
import '../../theme/design_tokens.dart';

class PeriodicReminderEditorSheet extends StatefulWidget {
  const PeriodicReminderEditorSheet({
    super.key,
    this.existingTitle,
    this.existingIntervalDays,
  });

  final String? existingTitle;
  final int? existingIntervalDays;

  bool get isEditing => existingTitle != null;

  @override
  State<PeriodicReminderEditorSheet> createState() =>
      _PeriodicReminderEditorSheetState();
}

class _PeriodicReminderEditorSheetState
    extends State<PeriodicReminderEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _customDaysController;
  late int _selectedDays;
  bool _useCustomDays = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTitle ?? '');
    final initialDays = widget.existingIntervalDays ?? 14;
    final isPreset =
        PeriodicReminderIntervals.presets.any((p) => p.days == initialDays);
    _selectedDays = initialDays;
    _useCustomDays = !isPreset;
    _customDaysController = TextEditingController(
      text: isPreset ? '' : '$initialDays',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  int? _resolveIntervalDays() {
    if (_useCustomDays) {
      final parsed = int.tryParse(_customDaysController.text.trim());
      if (parsed == null || parsed < 1) return null;
      return parsed;
    }
    return _selectedDays;
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final days = _resolveIntervalDays();
    if (days == null) return;
    Navigator.of(context).pop((title: title, intervalDays: days));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isEditing ? 'Hatırlatıcıyı düzenle' : 'Yeni hatırlatıcı',
            style: theme.textTheme.titleLarge?.copyWith(
              color: DesignTokens.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('periodic_reminder_title_field'),
            controller: _titleController,
            autofocus: true,
            style: theme.textTheme.bodyLarge?.copyWith(color: DesignTokens.white),
            decoration: InputDecoration(
              hintText: 'Örn. Havluları değiştir',
              hintStyle: TextStyle(color: DesignTokens.slate500),
              filled: true,
              fillColor: DesignTokens.slate950,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: DesignTokens.slate800),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Text(
            'Tekrar aralığı',
            style: theme.textTheme.titleSmall?.copyWith(
              color: DesignTokens.slate400,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in PeriodicReminderIntervals.presets)
                ChoiceChip(
                  key: Key('periodic_interval_${preset.days}'),
                  label: Text(preset.label),
                  selected: !_useCustomDays && _selectedDays == preset.days,
                  onSelected: (_) {
                    setState(() {
                      _useCustomDays = false;
                      _selectedDays = preset.days;
                    });
                  },
                ),
              ChoiceChip(
                key: const Key('periodic_interval_custom'),
                label: const Text('Özel'),
                selected: _useCustomDays,
                onSelected: (_) {
                  setState(() => _useCustomDays = true);
                },
              ),
            ],
          ),
          if (_useCustomDays) ...[
            const SizedBox(height: 12),
            TextField(
              key: const Key('periodic_reminder_custom_days'),
              controller: _customDaysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.bodyLarge?.copyWith(
                color: DesignTokens.white,
              ),
              decoration: InputDecoration(
                hintText: 'Gün sayısı',
                suffixText: 'gün',
                hintStyle: TextStyle(color: DesignTokens.slate500),
                filled: true,
                fillColor: DesignTokens.slate950,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: DesignTokens.slate800),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('periodic_reminder_save'),
            onPressed: _submit,
            child: Text(widget.isEditing ? 'Kaydet' : 'Ekle'),
          ),
        ],
      ),
    );
  }
}

/// Başlık + aralık gün döner; iptal edilirse `null`.
Future<({String title, int intervalDays})?> showPeriodicReminderEditor({
  required BuildContext context,
  String? existingTitle,
  int? existingIntervalDays,
}) {
  return showModalBottomSheet<({String title, int intervalDays})?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTokens.slate900,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => PeriodicReminderEditorSheet(
      existingTitle: existingTitle,
      existingIntervalDays: existingIntervalDays,
    ),
  );
}
