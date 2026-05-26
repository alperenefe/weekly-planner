import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/services/task_focus_timer_controller.dart';

Task _plannedTask({required int id, int durationMinutes = 25}) {
  return Task(
    id: id,
    title: 'Focus test',
    durationMinutes: durationMinutes,
    status: 'planned',
    weekStart: '2025-01-06',
    movedCount: 0,
    createdAt: '2025-01-01T00:00:00.000Z',
    updatedAt: '2025-01-01T00:00:00.000Z',
    reminderEnabled: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('pauseSession stores partial budget per task', () async {
    const goalSec = 10 * 60;
    final c = TaskFocusTimerController();
    await c.start(_plannedTask(id: 42, durationMinutes: 10));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await c.pauseSession();

    final rem = c.budgetRemainingSeconds(
      taskId: 42,
      goalTotalSeconds: goalSec,
    );
    expect(rem, lessThan(goalSec));
    expect(rem, greaterThan(goalSec - 30));
  });

  test('new controller restores partial budget from disk', () async {
    const goalSec = 10 * 60;
    final first = TaskFocusTimerController();
    await first.start(_plannedTask(id: 7, durationMinutes: 10));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await first.pauseSession();
    final saved = first.budgetRemainingSeconds(
      taskId: 7,
      goalTotalSeconds: goalSec,
    );

    final second = TaskFocusTimerController();
    await second.preloadPartialGoals();
    expect(
      second.budgetRemainingSeconds(taskId: 7, goalTotalSeconds: goalSec),
      saved,
    );
  });

  test('start resumes from stored partial budget', () async {
    const goalSec = 10 * 60;
    final first = TaskFocusTimerController();
    await first.start(_plannedTask(id: 3, durationMinutes: 10));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await first.pauseSession();
    final partial = first.budgetRemainingSeconds(
      taskId: 3,
      goalTotalSeconds: goalSec,
    );

    final second = TaskFocusTimerController();
    await second.preloadPartialGoals();
    await second.start(_plannedTask(id: 3, durationMinutes: 10));

    expect(second.phase, TaskFocusTimerPhase.running);
    final remaining = second.remainingNow().inSeconds;
    expect(remaining, lessThanOrEqualTo(partial + 2));
    expect(remaining, greaterThan(partial - 15));
    await second.pauseSession();
  });
}
