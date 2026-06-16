import 'package:flutter/material.dart';

import '../../models/todo_category.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/planner_dialogs.dart';
import '../../widgets/planner_sheet_handle.dart';

class TodoEditorResult {
  const TodoEditorResult({
    required this.title,
    this.categoryId,
    this.deadlineDate,
    this.notes,
  });

  final String title;
  final int? categoryId;
  final String? deadlineDate;
  final String? notes;
}

Future<TodoEditorResult?> showTodoEditorSheet({
  required BuildContext context,
  required List<TodoCategory> categories,
  String? initialTitle,
  int? initialCategoryId,
  String? initialDeadlineDate,
  String? initialNotes,
}) {
  return showModalBottomSheet<TodoEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: _TodoEditorSheet(
          categories: categories,
          initialTitle: initialTitle,
          initialCategoryId: initialCategoryId,
          initialDeadlineDate: initialDeadlineDate,
          initialNotes: initialNotes,
        ),
      );
    },
  );
}

class _TodoEditorSheet extends StatefulWidget {
  const _TodoEditorSheet({
    required this.categories,
    this.initialTitle,
    this.initialCategoryId,
    this.initialDeadlineDate,
    this.initialNotes,
  });

  final List<TodoCategory> categories;
  final String? initialTitle;
  final int? initialCategoryId;
  final String? initialDeadlineDate;
  final String? initialNotes;

  @override
  State<_TodoEditorSheet> createState() => _TodoEditorSheetState();
}

class _TodoEditorSheetState extends State<_TodoEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  int? _categoryId;
  String? _deadlineIso;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle ?? '');
    _notes = TextEditingController(text: widget.initialNotes ?? '');
    _categoryId = widget.initialCategoryId;
    _deadlineIso = widget.initialDeadlineDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final initial = _deadlineIso != null
        ? DateTime.tryParse(_deadlineIso!)
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
      _deadlineIso =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      showPlannerErrorSnackBar(context, 'Başlık girmelisin');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final notes = _notes.text.trim();
    if (!mounted) return;
    Navigator.of(context).pop(
      TodoEditorResult(
        title: title,
        categoryId: _categoryId,
        deadlineDate: _deadlineIso,
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const Key('todo_editor_sheet'),
      color: DesignTokens.slate950,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PlannerSheetHandle(),
              Text(
                widget.initialTitle == null ? 'Yeni yapılacak' : 'Düzenle',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('todo_editor_title'),
                controller: _title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: DesignTokens.white,
                ),
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Ne yapılacak?',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kategori',
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
                  FilterChip(
                    label: const Text('Yok'),
                    selected: _categoryId == null,
                    onSelected: (_) => setState(() => _categoryId = null),
                  ),
                  for (final c in widget.categories)
                    FilterChip(
                      key: Key('todo_cat_${c.id}'),
                      label: Text(c.name),
                      selected: _categoryId == c.id,
                      selectedColor: Color(c.colorArgb ?? 0xFF64748B)
                          .withValues(alpha: 0.22),
                      checkmarkColor: Color(c.colorArgb ?? 0xFF64748B),
                      side: BorderSide(
                        color: _categoryId == c.id
                            ? Color(c.colorArgb ?? 0xFF64748B)
                            : DesignTokens.slate700,
                      ),
                      onSelected: (_) => setState(() => _categoryId = c.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Son tarih',
                  style: TextStyle(color: DesignTokens.slate400),
                ),
                subtitle: Text(
                  _deadlineIso ?? 'Belirtilmedi',
                  style: TextStyle(
                    color: _deadlineIso == null
                        ? DesignTokens.slate500
                        : DesignTokens.blue400,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_deadlineIso != null)
                      IconButton(
                        onPressed: () => setState(() => _deadlineIso = null),
                        icon: const Icon(Icons.clear, size: 20),
                      ),
                    IconButton(
                      key: const Key('todo_editor_deadline'),
                      onPressed: _pickDeadline,
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('todo_editor_notes'),
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.white,
                ),
                decoration: const InputDecoration(
                  labelText: 'Notlar (isteğe bağlı)',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('todo_editor_save'),
                onPressed: _saving ? null : _save,
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
