import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/todo_repository.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = TodoRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('ensureDefaultCategories seeds and insert todo roundtrip', () async {
    final cats = await repo.getCategories();
    expect(cats, isNotEmpty);

    final id = await repo.insertTodo(
      title: 'Vergi öde',
      categoryId: cats.first.id,
      deadlineDate: '2026-06-15',
    );
    final todos = await repo.getTodos();
    expect(todos.any((t) => t.id == id && t.title == 'Vergi öde'), isTrue);

    await repo.setDone(id, true);
    final done = await repo.getTodos(includeDone: true);
    expect(done.singleWhere((t) => t.id == id).isDone, isTrue);

    await repo.deleteTodo(id);
    expect(await repo.getTodos(), isEmpty);
  });
}
