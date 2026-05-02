import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/db/app_database.dart';
import '../date/week_calendar.dart';
import '../plan_day_labels.dart';
import '../theme/design_tokens.dart';

typedef PlanShiftApply = Future<void> Function(
  String plannedDateIso,
  int anchorStartMinutes,
  int shiftMinutes,
);

class PlanShiftSheet extends StatefulWidget {
  const PlanShiftSheet({
    super.key,
    required this.weekStart,
    required this.loadDayTasks,
    required this.onApply,
    this.clock,
  });

  final String weekStart;
  final Future<List<Task>> Function(String plannedIso) loadDayTasks;
  final PlanShiftApply onApply;
  final DateTime Function()? clock;

  @override
  State<PlanShiftSheet> createState() => _PlanShiftSheetState();
}

class _PlanShiftSheetState extends State<PlanShiftSheet> {
  int? _dayIndex;
  List<int> _anchors = [];
  int? _selectedAnchor;
  bool _loadingAnchors = false;
  final TextEditingController _shiftController =
      TextEditingController(text: '30');
  bool _busy = false;

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _dayIndex = _initialDayIndex();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_reloadAnchors());
    });
  }

  @override
  void dispose() {
    _shiftController.dispose();
    super.dispose();
  }

  int? _initialDayIndex() {
    final todayIso = toIsoDate(_now());
    final isos = weekdayIsosFromMonday(widget.weekStart);
    final todayInWeek = chipIndexForPlannedDate(widget.weekStart, todayIso);
    if (todayInWeek != 0) return todayInWeek;
    for (var i = 0; i < 7; i++) {
      if (isos[i].compareTo(todayIso) >= 0) return i + 1;
    }
    return null;
  }

  Future<void> _reloadAnchors() async {
    if (_dayIndex == null) return;
    final plannedIso = plannedDateForChipIndex(widget.weekStart, _dayIndex!);
    if (plannedIso == null) return;
    setState(() {
      _loadingAnchors = true;
      _anchors = [];
      _selectedAnchor = null;
    });
    final tasks = await widget.loadDayTasks(plannedIso);
    if (!mounted) return;
    final todayIso = toIsoDate(_now());
    final seen = <int>{};
    final mins = <int>[];
    for (final t in tasks) {
      final sm = t.startMinutes;
      if (sm == null) continue;
      if (!seen.add(sm)) continue;
      mins.add(sm);
    }
    mins.sort();
    if (plannedIso.compareTo(todayIso) < 0) {
      mins.clear();
    }
    setState(() {
      _loadingAnchors = false;
      _anchors = mins;
      _selectedAnchor = mins.isEmpty ? null : mins.first;
    });
  }

  Future<void> _onApply() async {
    if (_dayIndex == null || _selectedAnchor == null || _busy) return;
    final plannedIso =
        plannedDateForChipIndex(widget.weekStart, _dayIndex!);
    if (plannedIso == null) return;
    final raw = _shiftController.text.trim();
    final shift = int.tryParse(raw);
    if (shift == null || shift <= 0) return;
    setState(() => _busy = true);
    try {
      await widget.onApply(plannedIso, _selectedAnchor!, shift);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayIso = toIsoDate(_now());
    final isos = weekdayIsosFromMonday(widget.weekStart);
    final canPickDay = isos.any((iso) => iso.compareTo(todayIso) >= 0);
    final applyEnabled = !_busy &&
        !_loadingAnchors &&
        _dayIndex != null &&
        _selectedAnchor != null &&
        _anchors.isNotEmpty;

    return Material(
      key: const Key('plan_shift_sheet'),
      color: DesignTokens.slate950,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Planı kaydır',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  color: DesignTokens.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                canPickDay
                    ? 'Gün seçin; çapa yalnızca o günkü saatli etkinliklerin başlangıç saatlerinden gelir (gün içinde saat ilerlemiş olsa da).'
                    : 'Bu haftanın tüm günleri geçmiş; bu hafta için kaydırma uygulanamaz.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DesignTokens.slate400,
                  height: 1.35,
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
                      Text(
                        'Gün',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: DesignTokens.slate400,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 1; i <= 7; i++)
                            Builder(
                              builder: (context) {
                                final iso =
                                    plannedDateForChipIndex(
                                        widget.weekStart, i);
                                final selectable = iso != null &&
                                    iso.compareTo(todayIso) >= 0;
                                return FilterChip(
                                  key: Key('plan_shift_day_$i'),
                                  label: Text(kPlanDayLabels[i]),
                                  selected: _dayIndex == i,
                                  onSelected: !selectable || _busy
                                      ? null
                                      : (sel) {
                                          if (!sel) return;
                                          setState(() => _dayIndex = i);
                                          unawaited(_reloadAnchors());
                                        },
                                  showCheckmark: false,
                                  selectedColor:
                                      DesignTokens.blue600.withValues(
                                          alpha: 0.35),
                                  labelStyle: TextStyle(
                                    color: selectable
                                        ? DesignTokens.slate200
                                        : DesignTokens.slate600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  side: BorderSide(
                                    color: _dayIndex == i
                                        ? DesignTokens.blue500
                                        : DesignTokens.slate700,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Kaydırma başlangıcı (çapa)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: DesignTokens.slate400,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_loadingAnchors)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DesignTokens.blue400,
                              ),
                            ),
                          ),
                        ),
                      if (!_loadingAnchors &&
                          _dayIndex != null &&
                          _anchors.isEmpty)
                        Text(
                          'Bu gün için uygun çapa yok (saatli etkinlik yok veya hepsi geçmiş).',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: DesignTokens.slate500,
                            height: 1.35,
                          ),
                        ),
                      if (!_loadingAnchors && _anchors.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final m in _anchors)
                              FilterChip(
                                key: Key('plan_shift_anchor_$m'),
                                label: Text(formatClockMinutes(m)),
                                selected: _selectedAnchor == m,
                                onSelected: _busy
                                    ? null
                                    : (sel) {
                                        if (!sel) return;
                                        setState(
                                            () => _selectedAnchor = m);
                                      },
                                showCheckmark: false,
                                selectedColor:
                                    DesignTokens.blue600.withValues(
                                        alpha: 0.35),
                                labelStyle: TextStyle(
                                  color: DesignTokens.slate200,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                side: BorderSide(
                                  color: _selectedAnchor == m
                                      ? DesignTokens.blue500
                                      : DesignTokens.slate700,
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Kaydırma (dakika)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: DesignTokens.slate400,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('plan_shift_minutes'),
                        controller: _shiftController,
                        enabled: !_busy,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DesignTokens.white,
                        ),
                        cursorColor: DesignTokens.blue400,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: 'Örn: 30',
                          hintStyle: TextStyle(
                            color: DesignTokens.slate600
                                .withValues(alpha: 0.8),
                          ),
                          filled: true,
                          fillColor: DesignTokens.slate950,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: DesignTokens.slate800),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: DesignTokens.slate800),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: DesignTokens.blue500,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in [15, 30, 45, 60])
                            ActionChip(
                              key: Key('plan_shift_preset_$m'),
                              label: Text('$m dk'),
                              onPressed: _busy
                                  ? null
                                  : () {
                                      setState(() {
                                        _shiftController.text = '$m';
                                      });
                                    },
                              backgroundColor: DesignTokens.slate900,
                              labelStyle: TextStyle(
                                color: DesignTokens.slate400,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              side: const BorderSide(
                                  color: DesignTokens.slate700),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _busy
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
                            key: const Key('plan_shift_apply'),
                            onPressed: applyEnabled ? _onApply : null,
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
                            child: _busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: DesignTokens.white,
                                    ),
                                  )
                                : const Text('Uygula'),
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
