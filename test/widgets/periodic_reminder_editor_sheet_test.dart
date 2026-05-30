import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/screens/periodic_reminders/periodic_reminder_editor_sheet.dart';
import 'package:weekly_planner/theme/design_tokens.dart';

void main() {
  testWidgets('geçerli başlık ve gün ile kayıt döner', (tester) async {
  ({String title, int intervalDays})? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  result = await showPeriodicReminderEditor(context: ctx);
                },
                child: const Text('Aç'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('periodic_reminder_title_field')),
      'Havlular',
    );
    await tester.enterText(
      find.byKey(const Key('periodic_reminder_days_field')),
      '21',
    );
    await tester.tap(find.byKey(const Key('periodic_reminder_save')));
    await tester.pumpAndSettle();

    expect(result?.title, 'Havlular');
    expect(result?.intervalDays, 21);
  });

  testWidgets('boş başlık ve geçersiz gün hata gösterir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: DesignTokens.slate950,
          body: PeriodicReminderEditorSheet(),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('periodic_reminder_days_field')),
      '',
    );
    await tester.tap(find.byKey(const Key('periodic_reminder_save')));
    await tester.pump();

    expect(find.text('Başlık girmelisin'), findsOneWidget);
    expect(find.text('1–3650 arası gün sayısı gir'), findsOneWidget);
  });

  testWidgets('0 gün kabul edilmez', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeriodicReminderEditorSheet(),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('periodic_reminder_title_field')),
      'Test',
    );
    await tester.enterText(
      find.byKey(const Key('periodic_reminder_days_field')),
      '0',
    );
    await tester.tap(find.byKey(const Key('periodic_reminder_save')));
    await tester.pump();

    expect(find.text('1–3650 arası gün sayısı gir'), findsOneWidget);
  });
}
