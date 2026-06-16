part of 'edit_task_sheet.dart';

class _EditTaskSheetBody extends StatelessWidget {
  const _EditTaskSheetBody(this.state);

  final _EditTaskSheetState state;

  EditTaskSheet get sheet => state.widget;

  InputDecoration fieldDec(String label, {String? hint, String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
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
        borderSide: BorderSide(
          color: errorText != null
              ? PlannerDialogs.deleteRed
              : DesignTokens.blue500,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: PlannerDialogs.deleteRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: PlannerDialogs.deleteRed, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const Key('edit_task_sheet'),
      color: DesignTokens.slate950,
      child: SafeArea(
        child: SingleChildScrollView(
          controller: state.scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                state.isEvent ? 'Gün etkinliğini düzenle' : 'İşi düzenle',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: DesignTokens.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                key: const Key('edit_task_kind'),
                segments: const [
                  ButtonSegment(
                    value: TaskKind.work,
                    label: Text('İş'),
                    icon: Icon(Icons.work_outline_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: TaskKind.event,
                    label: Text('Etkinlik'),
                    icon: Icon(Icons.event_outlined, size: 18),
                  ),
                ],
                selected: {state.taskKind},
                onSelectionChanged: state.saving
                    ? null
                    : (s) {
                        state.setState(() {
                          state.taskKind = s.first;
                          if (state.isEvent) {
                            state.useStartTime = false;
                            state.durationController.clear();
                          }
                        });
                      },
              ),
              const SizedBox(height: 16),
              Material(
                color: DesignTokens.slate900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: DesignTokens.slate800),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        key: state.titleFieldKey,
                        child: TextField(
                          key: const Key('edit_task_title'),
                          controller: state.titleController,
                          focusNode: state.titleFocusNode,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: DesignTokens.white,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: DesignTokens.blue400,
                          decoration: fieldDec(
                            'Başlık',
                            hint: 'Etkinlik adını girin...',
                            errorText: state.titleError
                                ? 'Başlık girmelisin'
                                : null,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      if (!state.isEvent) ...[
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('edit_task_duration'),
                          controller: state.durationController,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: DesignTokens.white,
                          ),
                          cursorColor: DesignTokens.blue400,
                          decoration: fieldDec('Süre (dakika)', hint: 'Örn: 30'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.next,
                        ),
                        if (sheet.onStartFocus != null &&
                            sheet.taskEntity != null &&
                            sheet.taskEntity!.status == 'planned') ...[
                          const SizedBox(height: 12),
                          Selector<TaskFocusTimerController, String>(
                            selector: (_, c) {
                              final t = sheet.taskEntity!;
                              final d = int.tryParse(
                                    state.durationController.text.trim(),
                                  ) ??
                                  t.durationMinutes ??
                                  0;
                              if (d <= 0) return 'Süreyi başlat';
                              final goalSec = d * 60;
                              final rem = c.budgetRemainingSeconds(
                                taskId: t.id,
                                goalTotalSeconds: goalSec,
                              );
                              if (rem >= goalSec) return 'Süreyi başlat';
                              final mins = (rem + 59) ~/ 60;
                              return 'Devam et ($mins dk kaldı)';
                            },
                            builder: (context, label, _) {
                              return OutlinedButton.icon(
                                key: const Key('edit_task_start_focus'),
                                onPressed: state.saving
                                    ? null
                                    : state.onStartFocusPressed,
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
                            state.useStartTime
                                ? formatClockMinutes(state.startMinutes)
                                : 'Kapalı',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: DesignTokens.slate400,
                            ),
                          ),
                          value: state.useStartTime,
                          onChanged: state.setUseStartTime,
                          activeThumbColor: DesignTokens.blue400,
                        ),
                        if (state.useStartTime) ...[
                          const SizedBox(height: 8),
                          OutlinedButton(
                            key: const Key('edit_task_start_pick'),
                            onPressed:
                                state.saving ? null : state.pickStartTime,
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
                                  formatClockMinutes(state.startMinutes),
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
                              selected: state.selectedDayIndex == i,
                              onSelected: (_) => state.setSelectedDayIndex(i),
                              selectedColor: DesignTokens.blue600,
                              backgroundColor: DesignTokens.slate900,
                              labelStyle: TextStyle(
                                color: state.selectedDayIndex == i
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
                        controller: state.notesController,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DesignTokens.white,
                        ),
                        cursorColor: DesignTokens.blue400,
                        decoration: fieldDec('Notlar', hint: 'Ekstra detaylar...'),
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
                            onTap: () => state.setAccentArgb(null),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: DesignTokens.slate800,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: state.accentArgb == null
                                      ? DesignTokens.blue400
                                      : DesignTokens.slate600,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: state.accentArgb == null
                                    ? DesignTokens.blue400
                                    : DesignTokens.slate500,
                              ),
                            ),
                          ),
                          for (final argb in DesignTokens.taskAccentArgb)
                            GestureDetector(
                              onTap: () => state.setAccentArgb(argb),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Color(argb),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: state.accentArgb == argb
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
                      if (sheet.onDeletePressed != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            key: const Key('edit_task_delete'),
                            onPressed: state.saving
                                ? null
                                : () async {
                                    await sheet.onDeletePressed!();
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
                      if (sheet.onDeletePressed != null) const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: state.saving
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
                            onPressed: state.saving ? null : state.onSavePressed,
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
                            child: state.saving
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
