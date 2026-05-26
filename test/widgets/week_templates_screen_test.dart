import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/data/db/app_database.dart';
import 'package:weekly_planner/data/repositories/week_template_repository.dart';

import '../test_support.dart';

void main() {
  testWidgets('empty state shows Henüz kayıtlı plan yok', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_week_templates_row')),
      500,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_week_templates_row')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('week_templates_empty')), findsOneWidget);
    expect(find.text('Henüz kayıtlı plan yok'), findsOneWidget);
  });

  testWidgets('creating a template shows it in the list', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_week_templates_row')),
      500,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_week_templates_row')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('week_templates_new_btn')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Test Şablonu');
    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('Test Şablonu'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    final id = (await WeekTemplateRepository(db).getTemplates()).single.id;
    expect(find.byKey(Key('week_template_row_$id')), findsOneWidget);
  });

  testWidgets('deleting template shows confirmation dialog', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
    });
    final wrepo = WeekTemplateRepository(db);
    final tid = await wrepo.insertTemplate('Silinecek');

    await tester.pumpWidget(plannerAppWithDb(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_week_templates_row')),
      500,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_week_templates_row')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('week_template_delete_$tid')));
    await tester.pumpAndSettle();

    expect(
      find.text('Bu kayıtlı hafta planı silinecek. Emin misin?'),
      findsOneWidget,
    );
  });
}
