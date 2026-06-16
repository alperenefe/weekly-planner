import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/todo_repository.dart';
import '../../models/todo_category.dart';
import '../../models/todo_item.dart';
import '../../theme/design_tokens.dart';
import '../../theme/planner_shell_layout.dart';
import '../../widgets/planner_dialogs.dart';
import '../../widgets/planner_empty_state.dart';
import '../../widgets/planner_top_bar.dart';
import 'todo_editor_sheet.dart';
import 'todo_list_card.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  List<TodoItem> _todos = [];
  List<TodoCategory> _categories = [];
  int? _filterCategoryId;
  bool _showDone = false;
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
      final repo = context.read<TodoRepository>();
      final cats = await repo.getCategories();
      final todos = await repo.getTodos(
        categoryId: _filterCategoryId,
        includeDone: _showDone,
      );
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _todos = todos;
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

  TodoCategory? _categoryFor(TodoItem item) {
    final id = item.categoryId;
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _openEditor({TodoItem? existing}) async {
    final result = await showTodoEditorSheet(
      context: context,
      categories: _categories,
      initialTitle: existing?.title,
      initialCategoryId: existing?.categoryId,
      initialDeadlineDate: existing?.deadlineDate,
      initialNotes: existing?.notes,
    );
    if (result == null || !mounted) return;
    final repo = context.read<TodoRepository>();
    try {
      if (existing == null) {
        await repo.insertTodo(
          title: result.title,
          categoryId: result.categoryId,
          deadlineDate: result.deadlineDate,
          notes: result.notes,
        );
      } else {
        await repo.updateTodo(
          existing.id,
          title: result.title,
          categoryId: result.categoryId,
          deadlineDate: result.deadlineDate,
          notes: result.notes,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showPlannerErrorSnackBar(context, 'Kaydedilemedi: $e');
      return;
    }
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    showPlannerSnackBar(
      context,
      existing == null ? 'Yapılacak eklendi' : 'Güncellendi',
    );
  }

  Future<void> _toggleDone(TodoItem item) async {
    await context.read<TodoRepository>().setDone(item.id, !item.isDone);
    if (!mounted) return;
    await _reload();
  }

  Future<void> _delete(TodoItem item) async {
    final ok = await PlannerDialogs.confirmDelete(
      context,
      title: 'Silinsin mi?',
      message: '“${item.title}” kalıcı olarak silinir.',
    );
    if (ok != true || !mounted) return;
    await context.read<TodoRepository>().deleteTodo(item.id);
    if (!mounted) return;
    await _reload();
  }

  Future<void> _addCategory() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Yeni kategori'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(hintText: 'Kategori adı'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty || !mounted) return;
    await context.read<TodoRepository>().insertCategory(name);
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('todos_screen'),
      appBar: const PlannerTopBar(title: 'Yapılacaklar'),
      floatingActionButton: _todos.isEmpty
          ? null
          : Padding(
        padding: EdgeInsets.only(bottom: plannerShellFabBottomPadding(context)),
        child: FloatingActionButton.extended(
          key: const Key('todos_add_fab'),
          onPressed: () => unawaited(_openEditor()),
          backgroundColor: DesignTokens.blue600,
          foregroundColor: DesignTokens.white,
          icon: const Icon(Icons.add),
          label: const Text('Ekle'),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            const LinearProgressIndicator(
              key: Key('todos_loading_bar'),
              minHeight: 2,
              backgroundColor: DesignTokens.slate900,
              color: DesignTokens.blue500,
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                FilterChip(
                  key: const Key('todo_filter_all'),
                  label: const Text('Tümü'),
                  selected: _filterCategoryId == null,
                  onSelected: (_) {
                    setState(() => _filterCategoryId = null);
                    unawaited(_reload());
                  },
                ),
                const SizedBox(width: 8),
                for (final c in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      key: Key('todo_filter_cat_${c.id}'),
                      label: Text(c.name),
                      selected: _filterCategoryId == c.id,
                      onSelected: (_) {
                        setState(() => _filterCategoryId = c.id);
                        unawaited(_reload());
                      },
                    ),
                  ),
                ActionChip(
                  key: const Key('todo_add_category'),
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Kategori'),
                  onPressed: () => unawaited(_addCategory()),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SwitchListTile(
              key: const Key('todo_show_done'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Tamamlananları göster'),
              value: _showDone,
              onChanged: (v) {
                setState(() => _showDone = v);
                unawaited(_reload());
              },
            ),
          ),
          Expanded(
            child: _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Liste yüklenemedi.\n$_loadError',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: DesignTokens.slate500,
                        ),
                      ),
                    ),
                  )
                : _todos.isEmpty
                    ? Center(
                        child: PlannerEmptyState(
                          testKey: const Key('todos_empty'),
                          icon: Icons.checklist_rounded,
                          title: 'Henüz yapılacak yok',
                          subtitle:
                              'Deadline ve kategori ile takip et; '
                              'plan ekranından ayrı kalır.',
                          actionLabel: 'İlk yapılacağı ekle',
                          onAction: () => unawaited(_openEditor()),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        itemCount: _todos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final item = _todos[i];
                          return TodoListCard(
                            key: Key('todo_item_${item.id}'),
                            todo: item,
                            category: _categoryFor(item),
                            onTap: () =>
                                unawaited(_openEditor(existing: item)),
                            onToggleDone: () => unawaited(_toggleDone(item)),
                            onDelete: () => unawaited(_delete(item)),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
