import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/task_repository.dart';
import 'package:weekly_planner/models/task_kind.dart';
import 'package:weekly_planner/widgets/task_card.dart';

void main() {
  testWidgets('checkbox marks task done', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    final repo = TaskRepository(db);
    const week = '2024-10-28';
    final now = DateTime.utc(2024, 10, 28, 14).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'TapDone',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final task = (await repo.getTasksForWeek(week)).single;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: TaskCard(
            task: task,
            onMarkDone: () => repo.markDone(task.id),
            onUnmarkDone: () => repo.unmarkDone(task.id),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(Key('task_card_checkbox_$id')));
    await tester.pumpAndSettle();

    final again = (await repo.getTasksForWeek(week)).single;
    expect(again.status, 'done');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: TaskCard(
            task: again,
            onMarkDone: () => repo.markDone(again.id),
            onUnmarkDone: () => repo.unmarkDone(again.id),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(Key('task_card_unmark_done_$id')));
    await tester.pumpAndSettle();

    final planned = (await repo.getTasksForWeek(week)).single;
    expect(planned.status, 'planned');
  });

  testWidgets('dragSlotWrapper ile sarılı kartta tamamlandı geri alınır', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    final repo = TaskRepository(db);
    const week = '2024-10-28';
    final now = DateTime.utc(2024, 10, 28, 14).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'DragUnmark',
        weekStart: week,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.markDone(id);
    var task = (await repo.getTasksForWeek(week)).single;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: TaskCard(
            task: task,
            onMarkDone: () => repo.markDone(task.id),
            onUnmarkDone: () => repo.unmarkDone(task.id),
            dragSlotWrapper: (dragBody) => LongPressDraggable<Task>(
              data: task,
              feedback: Material(
                child: SizedBox(
                  width: 200,
                  height: 72,
                  child: Center(child: Text(task.title)),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.4, child: dragBody),
              child: dragBody,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(Key('task_card_unmark_done_$id')));
    await tester.pumpAndSettle();

    task = (await repo.getTasksForWeek(week)).single;
    expect(task.status, 'planned');
  });

  testWidgets('etkinlik kartında tik ve atlama yok', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    final repo = TaskRepository(db);
    const week = '2024-10-28';
    final now = DateTime.utc(2024, 10, 28, 14).toIso8601String();
    final id = await repo.insertTask(
      TasksCompanion.insert(
        title: 'Buluşma',
        weekStart: week,
        taskKind: Value(TaskKind.event),
        createdAt: now,
        updatedAt: now,
      ),
    );
    final task = (await repo.getTasksForWeek(week)).single;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: TaskCard(
            task: task,
            onMarkDone: () => repo.markDone(task.id),
            onUnmarkDone: () => repo.unmarkDone(task.id),
            onMarkSkipped: () => repo.markSkipped(task.id),
          ),
        ),
      ),
    );

    expect(find.byKey(Key('task_card_checkbox_$id')), findsNothing);
    expect(find.byKey(Key('task_card_skip_$id')), findsNothing);
    expect(find.byIcon(Icons.event_outlined), findsOneWidget);
  });
}
