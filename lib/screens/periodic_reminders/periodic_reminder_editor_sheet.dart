import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late final TextEditingController _daysController;
  String? _titleError;
  String? _daysError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTitle ?? '');
    final initialDays = widget.existingIntervalDays;
    _daysController = TextEditingController(
      text: initialDays != null ? '$initialDays' : '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  int? _parseDays() {
    final parsed = int.tryParse(_daysController.text.trim());
    if (parsed == null || parsed < 1 || parsed > 3650) return null;
    return parsed;
  }

  void _submit() {
    final title = _titleController.text.trim();
    final days = _parseDays();
    final titleErr = title.isEmpty ? 'Başlık girmelisin' : null;
    final daysErr = days == null ? '1–3650 arası gün sayısı gir' : null;

    setState(() {
      _titleError = titleErr;
      _daysError = daysErr;
    });
    if (titleErr != null || daysErr != null) return;

    Navigator.of(context).pop((title: title, intervalDays: days!));
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
            style: theme.textTheme.bodyLarge?.copyWith(
              color: DesignTokens.white,
            ),
            decoration: InputDecoration(
              labelText: 'Başlık',
              hintText: 'Örn. Havluları değiştir',
              errorText: _titleError,
              hintStyle: TextStyle(color: DesignTokens.slate500),
              filled: true,
              fillColor: DesignTokens.slate950,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: DesignTokens.slate800),
              ),
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('periodic_reminder_days_field'),
            controller: _daysController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.bodyLarge?.copyWith(
              color: DesignTokens.white,
            ),
            decoration: InputDecoration(
              labelText: 'Tekrar aralığı',
              hintText: 'Gün sayısı',
              errorText: _daysError,
              suffixText: 'gün',
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
          const SizedBox(height: 8),
          Text(
            'Örn. 14 = iki haftada bir, 180 = yaklaşık 6 ayda bir',
            style: theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.slate500,
            ),
          ),
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
