import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/theme/design_tokens.dart';
import 'package:weekly_planner/widgets/day_events_collapsible_strip.dart';

void main() {
  testWidgets('DayEventsCollapsibleStrip expands on tap', (tester) async {
    final events = [
      Task(
        id: 1,
        title: 'Toplantı',
        status: 'planned',
        weekStart: '2025-01-06',
        movedCount: 0,
        createdAt: '2025-01-01T00:00:00.000Z',
        updatedAt: '2025-01-01T00:00:00.000Z',
        reminderEnabled: 0,
        taskKind: 'event',
        priority: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DayEventsCollapsibleStrip(
            events: events,
            columnKeySuffix: 'Sal',
            itemBuilder: (t) => Text(t.title),
          ),
        ),
      ),
    );

    expect(find.text('Toplantı'), findsNothing);
    expect(find.byKey(const Key('day_events_strip_Sal')), findsOneWidget);

    await tester.tap(find.byKey(const Key('day_events_strip_Sal')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Toplantı'), findsOneWidget);

    await tester.tap(find.byKey(const Key('day_events_strip_Sal')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Toplantı'), findsNothing);
  });

  testWidgets('DayEventsCollapsibleStrip hidden when no events', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DayEventsCollapsibleStrip(
            events: [],
            columnKeySuffix: 'Çar',
            itemBuilder: _noop,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('day_events_strip_Çar')), findsNothing);
  });
}

Widget _noop(Task _) => const SizedBox.shrink();
