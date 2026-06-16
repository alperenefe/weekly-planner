import 'package:drift/drift.dart';

import '../../models/todo_category.dart';
import '../../models/todo_item.dart';
import '../db/app_database.dart';

class TodoRepository {
  TodoRepository(this._db);

  final AppDatabase _db;

  static const defaultCategories = [
    ('Genel', 0xFF64748B),
    ('İş', 0xFF2563EB),
    ('Kişisel', 0xFF8B5CF6),
    ('Alışveriş', 0xFFEA580C),
  ];

  TodoCategory _categoryFromRow(QueryRow r) {
    return TodoCategory(
      id: r.read<int>('id'),
      name: r.read<String>('name'),
      colorArgb: r.readNullable<int>('color_argb'),
      sortOrder: r.read<int>('sort_order'),
      createdAt: r.read<String>('created_at'),
    );
  }

  TodoItem _todoFromRow(QueryRow r) {
    return TodoItem(
      id: r.read<int>('id'),
      title: r.read<String>('title'),
      categoryId: r.readNullable<int>('category_id'),
      deadlineDate: r.readNullable<String>('deadline_date'),
      status: r.read<String>('status'),
      notes: r.readNullable<String>('notes'),
      createdAt: r.read<String>('created_at'),
      updatedAt: r.read<String>('updated_at'),
      completedAt: r.readNullable<String>('completed_at'),
    );
  }

  Future<void> ensureDefaultCategories() async {
    final count = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM todo_categories',
      readsFrom: const {},
    ).getSingle();
    if (count.read<int>('c') > 0) return;

    final now = DateTime.now().toUtc().toIso8601String();
    for (var i = 0; i < defaultCategories.length; i++) {
      final (name, color) = defaultCategories[i];
      await _db.customStatement(
        'INSERT INTO todo_categories (name, color_argb, sort_order, created_at) '
        'VALUES (?, ?, ?, ?)',
        [name, color, i, now],
      );
    }
  }

  Future<List<TodoCategory>> getCategories() async {
    await ensureDefaultCategories();
    final rows = await _db.customSelect(
      'SELECT id, name, color_argb, sort_order, created_at '
      'FROM todo_categories ORDER BY sort_order ASC, id ASC',
      readsFrom: const {},
    ).get();
    return rows.map(_categoryFromRow).toList();
  }

  Future<int> insertCategory(String name, {int? colorArgb}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final row = await _db.customSelect(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_idx FROM todo_categories',
      readsFrom: const {},
    ).getSingle();
    await _db.customStatement(
      'INSERT INTO todo_categories (name, color_argb, sort_order, created_at) '
      'VALUES (?, ?, ?, ?)',
      [name, colorArgb, row.read<int>('next_idx'), now],
    );
    final idRow = await _db.customSelect(
      'SELECT last_insert_rowid() AS id',
      readsFrom: const {},
    ).getSingle();
    return idRow.read<int>('id');
  }

  Future<void> deleteCategory(int id) async {
    await _db.customStatement(
      'UPDATE todos SET category_id = NULL WHERE category_id = ?',
      [id],
    );
    await _db.customStatement('DELETE FROM todo_categories WHERE id = ?', [id]);
  }

  Future<List<TodoItem>> getTodos({int? categoryId, bool includeDone = true}) async {
    await ensureDefaultCategories();
    final vars = <Variable>[];
    final parts = <String>[];
    if (categoryId != null) {
      parts.add('category_id = ?');
      vars.add(Variable<int>(categoryId));
    }
    if (!includeDone) {
      parts.add("status = 'planned'");
    }
    final where = parts.isEmpty ? '' : 'WHERE ${parts.join(' AND ')}';
    final rows = await _db.customSelect(
      'SELECT id, title, category_id, deadline_date, priority, status, notes, '
      'created_at, updated_at, completed_at FROM todos $where '
      'ORDER BY '
      "CASE WHEN status = 'done' THEN 1 ELSE 0 END, "
      'CASE WHEN deadline_date IS NULL THEN 1 ELSE 0 END, '
      'deadline_date ASC, created_at DESC',
      variables: vars,
      readsFrom: const {},
    ).get();
    return rows.map(_todoFromRow).toList();
  }

  Future<int> insertTodo({
    required String title,
    int? categoryId,
    String? deadlineDate,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.customStatement(
      'INSERT INTO todos (title, category_id, deadline_date, priority, status, notes, '
      'created_at, updated_at, completed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        title,
        categoryId,
        deadlineDate,
        0,
        'planned',
        notes,
        now,
        now,
        null,
      ],
    );
    final idRow = await _db.customSelect(
      'SELECT last_insert_rowid() AS id',
      readsFrom: const {},
    ).getSingle();
    return idRow.read<int>('id');
  }

  Future<void> updateTodo(
    int id, {
    required String title,
    int? categoryId,
    String? deadlineDate,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.customStatement(
      'UPDATE todos SET title = ?, category_id = ?, deadline_date = ?, '
      'notes = ?, updated_at = ? WHERE id = ?',
      [title, categoryId, deadlineDate, notes, now, id],
    );
  }

  Future<void> setDone(int id, bool done) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.customStatement(
      'UPDATE todos SET status = ?, completed_at = ?, updated_at = ? WHERE id = ?',
      [done ? 'done' : 'planned', done ? now : null, now, id],
    );
  }

  Future<void> deleteTodo(int id) async {
    await _db.customStatement('DELETE FROM todos WHERE id = ?', [id]);
  }
}
