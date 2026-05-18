import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/db/app_database.dart';
import '../date/week_calendar.dart';
import '../plan_day_labels.dart';
import '../services/task_focus_timer_controller.dart';
import '../theme/design_tokens.dart';

typedef EditTaskSubmit = Future<void> Function(
  String title,
  int? durationMinutes,
  String? notes,
  int dayIndex,
  int? startMinutes,
  int? accentColorArgb,
);

typedef EditTaskDeletePressed = Future<void> Function();

class EditTaskSheet extends StatefulWidget {
  const EditTaskSheet({
    super.key,
    required this.initialTitle,
    required this.initialDurationMinutes,
    required this.initialNotes,
    required this.initialDayIndex,
    required this.initialStartMinutes,
    this.initialAccentColor,
    required this.onSubmit,
    this.taskEntity,
    this.onStartFocus,
    this.onDeletePressed,
  });

  final String initialTitle;
  final int? initialDurationMinutes;
  final String? initialNotes;
  final int initialDayIndex;
  final int? initialStartMinutes;
  final int? initialAccentColor;
  final EditTaskSubmit onSubmit;
  final Task? taskEntity;
  final Future<void> Function(Task draft)? onStartFocus;
  final EditTaskDeletePressed? onDeletePressed;

  @override
  State<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<EditTaskSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;
  late final TextEditingController _notesController;
  late int _selectedDayIndex;
  bool _saving = false;
  late bool _useStartTime;
  late int _startMinutes;
  int? _accentArgb;
  bool _didPreloadFocusBudget = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDayIndex;
    _selectedDayIndex = d < 0 || d > 7 ? 0 : d;
    _accentArgb = widget.initialAccentColor ?? widget.taskEntity?.accentColor;
    _titleController = TextEditingController(text: widget.initialTitle);
    _durationController = TextEditingController(
      text: widget.initialDurationMinutes?.toString() ?? '',
    );
    _durationController.addListener(_onFormFieldsChanged);
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    final sm = widget.initialStartMinutes;
    _useStartTime = sm != null;
    _startMinutes = startMinutesFromQuarterIndex(
      quarterIndexFromStartMinutes(sm),
    );
  }

  void _onFormFieldsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _durationController.removeListener(_onFormFieldsChanged);
    _titleController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPreloadFocusBudget || widget.onStartFocus == null) return;
    _didPreloadFocusBudget = true;
    context.read<TaskFocusTimerController>().preloadPartialGoals().then((_) {
      if (mounted) setState(() {});
    });
  }

  InputDecoration _fieldDec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: DesignTokens.slate400,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
      hintStyle: TextStyle(color: DesignTokens.slate600.withValues(alpha: 0.8)),
      filled: true,
      fillColor: DesignTokens.slate950,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DesignTokens.slate800),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DesignTokens.slate800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DesignTokens.blue500, width: 1.5),
      ),
    );
  }

  Future<void> _onSavePressed() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      int? duration;
      final d = _durationController.text.trim();
      if (d.isNotEmpty) {
        duration = int.tryParse(d);
      }
      final notesRaw = _notesController.text.trim();
      final startMinutes = _useStartTime ? _startMinutes : null;
      await widget.onSubmit(
        title,
        duration,
        notesRaw.isEmpty ? null : notesRaw,
        _selectedDayIndex,
        startMinutes,
        _accentArgb,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _onStartFocusPressed() async {
    final seed = widget.taskEntity;
    final cb = widget.onStartFocus;
    if (seed == null || cb == null || _saving) return;
    final d = int.tryParse(_durationController.text.trim());
    if (d == null || d <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce süre (dakika) gir')),
        );
      }
      return;
    }
    final title = _titleController.text.trim();
    final draft = seed.copyWith(
      title: title.isEmpty ? seed.title : title,
      durationMinutes: Value(d),
    );
    await cb(draft);
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _pickStartTime() async {
    final initial = TimeOfDay(
      hour: _startMinutes ~/ 60,
      minute: _startMinutes % 60,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: DesignTokens.blue500,
              brightness: Brightness.dark,
            ).copyWith(surface: DesignTokens.slate900),
          ),
          child: child!,
        );
      },
    );
    if (!mounted || picked == null) return;
    setState(() {
      _useStartTime = true;
      _startMinutes = snappedStartMinutesFromWallClock(
        hour: picked.hour,
        minute: picked.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const Key('edit_task_sheet'),
      color: DesignTokens.slate950,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Etkinliği düzenle',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: DesignTokens.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: DesignTokens.slate900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DesignTokens.slate800),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        key: const Key('edit_task_title'),
                        controller: _titleController,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: DesignTokens.white,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: DesignTokens.blue400,
                        decoration: _fieldDec('Başlık', hint: 'Etkinlik adını girin...'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: const Key('edit_task_duration'),
                        controller: _durationController,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DesignTokens.white,
                        ),
                        cursorColor: DesignTokens.blue400,
                        decoration: _fieldDec('Süre (dakika)', hint: 'Örn: 30'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.next,
                      ),
                      if (widget.onStartFocus != null &&
                          widget.taskEntity != null &&
                          widget.taskEntity!.status == 'planned') ...[
                        const SizedBox(height: 12),
                        Selector<TaskFocusTimerController, (int, int)>(
                          selector: (_, c) {
                            final t = widget.taskEntity!;
                            final d = int.tryParse(
                                  _durationController.text.trim(),
                                ) ??
                                t.durationMinutes ??
                                0;
                            if (d <= 0) return (-1, -1);
                            final g = d * 60;
                            final rem = c.budgetRemainingSeconds(
                              taskId: t.id,
                              goalTotalSeconds: g,
                            );
                            return (g, rem);
                          },
                          builder: (context, pair, _) {
                            final goalSec = pair.$1;
                            final remSec = pair.$2;
                            final String label;
                            if (goalSec <= 0) {
                              label = 'Süreyi başlat';
                            } else if (remSec < goalSec) {
                              label =
                                  'Devam et (${(remSec + 59) ~/ 60} dk kaldı)';
                            } else {
                              label = 'Süreyi başlat';
                            }
                            return OutlinedButton.icon(
                              key: const Key('edit_task_start_focus'),
                              onPressed:
                                  _saving ? null : _onStartFocusPressed,
                              icon: const Icon(
                                Icons.play_circle_outline,
                                color: DesignTokens.blue400,
                              ),
                              label: Text(label),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: DesignTokens.blue400,
                                side: const BorderSide(
                                  color: DesignTokens.slate700,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      SwitchListTile(
                        key: const Key('edit_task_start_toggle'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Başlangıç saati',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: DesignTokens.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _useStartTime
                              ? formatClockMinutes(_startMinutes)
                              : 'Kapalı',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: DesignTokens.slate400,
                          ),
                        ),
                        value: _useStartTime,
                        onChanged: (v) => setState(() => _useStartTime = v),
                        activeThumbColor: DesignTokens.blue400,
                      ),
                      if (_useStartTime) ...[
                        const SizedBox(height: 8),
                        OutlinedButton(
                          key: const Key('edit_task_start_pick'),
                          onPressed: _saving ? null : _pickStartTime,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DesignTokens.white,
                            side: const BorderSide(color: DesignTokens.slate700),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 20,
                                color: DesignTokens.blue400,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                formatClockMinutes(_startMinutes),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: DesignTokens.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Değiştir',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: DesignTokens.slate400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'Gün',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: DesignTokens.slate400,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < kPlanDayLabels.length; i++)
                            ChoiceChip(
                              key: Key('edit_task_day_${kPlanDayLabels[i]}'),
                              label: Text(kPlanDayLabels[i]),
                              selected: _selectedDayIndex == i,
                              onSelected: (_) {
                                setState(() => _selectedDayIndex = i);
                              },
                              selectedColor: DesignTokens.blue600,
                              backgroundColor: DesignTokens.slate900,
                              labelStyle: TextStyle(
                                color: _selectedDayIndex == i
                                    ? DesignTokens.white
                                    : DesignTokens.slate400,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              side: const BorderSide(color: DesignTokens.slate800),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: const Key('edit_task_notes'),
                        controller: _notesController,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DesignTokens.white,
                        ),
                        cursorColor: DesignTokens.blue400,
                        decoration: _fieldDec('Notlar', hint: 'Ekstra detaylar...'),
                        minLines: 3,
                        maxLines: 6,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vurgu rengi',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: DesignTokens.slate400,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _accentArgb = null),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: DesignTokens.slate800,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _accentArgb == null
                                      ? DesignTokens.blue400
                                      : DesignTokens.slate600,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: _accentArgb == null
                                    ? DesignTokens.blue400
                                    : DesignTokens.slate500,
                              ),
                            ),
                          ),
                          for (final argb in DesignTokens.taskAccentArgb)
                            GestureDetector(
                              onTap: () => setState(() => _accentArgb = argb),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Color(argb),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _accentArgb == argb
                                        ? DesignTokens.white
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Divider(height: 1, color: DesignTokens.slate800),
                      ),
                      const SizedBox(height: 12),
                      if (widget.onDeletePressed != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            key: const Key('edit_task_delete'),
                            onPressed: _saving
                                ? null
                                : () async {
                                    await widget.onDeletePressed!();
                                  },
                            child: Text(
                              'Sil',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: const Color(0xFFF87171),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (widget.onDeletePressed != null)
                        const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).maybePop(),
                            child: Text(
                              'İptal',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: DesignTokens.blue400,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            key: const Key('edit_task_save'),
                            onPressed: _saving ? null : _onSavePressed,
                            style: FilledButton.styleFrom(
                              backgroundColor: DesignTokens.blue600,
                              foregroundColor: DesignTokens.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: DesignTokens.white,
                                    ),
                                  )
                                : const Text('Kaydet'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
