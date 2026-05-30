import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/db/app_database.dart';
import '../date/week_calendar.dart';
import '../plan_day_labels.dart';
import '../services/task_focus_timer_controller.dart';
import '../theme/design_tokens.dart';
import 'planner_dialogs.dart';

part 'edit_task_sheet_body.dart';

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
  late final TextEditingController titleController;
  late final TextEditingController durationController;
  late final TextEditingController notesController;
  final scrollController = ScrollController();
  final titleFocusNode = FocusNode();
  final titleFieldKey = GlobalKey();
  late int selectedDayIndex;
  bool saving = false;
  bool titleError = false;
  late bool useStartTime;
  late int startMinutes;
  int? accentArgb;
  bool _didPreloadFocusBudget = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDayIndex;
    selectedDayIndex = d < 0 || d > 7 ? 0 : d;
    accentArgb = widget.initialAccentColor ?? widget.taskEntity?.accentColor;
    titleController = TextEditingController(text: widget.initialTitle);
    titleController.addListener(onTitleChanged);
    durationController = TextEditingController(
      text: widget.initialDurationMinutes?.toString() ?? '',
    );
    durationController.addListener(onFormFieldsChanged);
    notesController = TextEditingController(text: widget.initialNotes ?? '');
    final sm = widget.initialStartMinutes;
    useStartTime = sm != null;
    startMinutes = startMinutesFromQuarterIndex(
      quarterIndexFromStartMinutes(sm),
    );
  }

  void onTitleChanged() {
    if (titleError && titleController.text.trim().isNotEmpty) {
      setState(() => titleError = false);
    }
  }

  void onFormFieldsChanged() {
    if (mounted) setState(() {});
  }

  void setUseStartTime(bool value) {
    setState(() => useStartTime = value);
  }

  void setSelectedDayIndex(int index) {
    setState(() => selectedDayIndex = index);
  }

  void setAccentArgb(int? value) {
    setState(() => accentArgb = value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPreloadFocusBudget || widget.onStartFocus == null) return;
    _didPreloadFocusBudget = true;
    unawaited(
      context.read<TaskFocusTimerController>().preloadPartialGoals().then((_) {
        if (mounted) setState(() {});
      }),
    );
  }

  @override
  void dispose() {
    titleController.removeListener(onTitleChanged);
    durationController.removeListener(onFormFieldsChanged);
    scrollController.dispose();
    titleFocusNode.dispose();
    titleController.dispose();
    durationController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> revealTitleField() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final fieldContext = titleFieldKey.currentContext;
    if (fieldContext != null) {
      await Scrollable.ensureVisible(
        fieldContext,
        alignment: 0.08,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    titleFocusNode.requestFocus();
  }

  Future<void> onSavePressed() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      setState(() => titleError = true);
      showPlannerErrorSnackBar(context, 'Başlık girmelisin');
      await revealTitleField();
      return;
    }
    if (saving) return;
    setState(() => saving = true);
    try {
      int? duration;
      final d = durationController.text.trim();
      if (d.isNotEmpty) {
        duration = int.tryParse(d);
      }
      final notesRaw = notesController.text.trim();
      final start = useStartTime ? startMinutes : null;
      await widget.onSubmit(
        title,
        duration,
        notesRaw.isEmpty ? null : notesRaw,
        selectedDayIndex,
        start,
        accentArgb,
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> onStartFocusPressed() async {
    final seed = widget.taskEntity;
    final cb = widget.onStartFocus;
    if (seed == null || cb == null || saving) return;
    final d = int.tryParse(durationController.text.trim());
    if (d == null || d <= 0) {
      if (mounted) {
        showPlannerErrorSnackBar(context, 'Önce süre (dakika) gir');
      }
      return;
    }
    final title = titleController.text.trim();
    final draft = seed.copyWith(
      title: title.isEmpty ? seed.title : title,
      durationMinutes: Value(d),
    );
    await cb(draft);
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> pickStartTime() async {
    final initial = TimeOfDay(
      hour: startMinutes ~/ 60,
      minute: startMinutes % 60,
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
      useStartTime = true;
      startMinutes = snappedStartMinutesFromWallClock(
        hour: picked.hour,
        minute: picked.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _EditTaskSheetBody(this);
  }
}
