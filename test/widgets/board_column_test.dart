import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/theme/design_tokens.dart';
import 'package:weekly_planner/widgets/board_column.dart';

void main() {
  testWidgets('BoardColumn shows title and child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 200,
              child: BoardColumn(
                title: 'Pzt',
                dateShort: '12 Haz',
                badgeCount: 2,
                width: 200,
                child: const Text('inner'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('board_col_title_Pzt')), findsOneWidget);
    expect(find.byKey(const Key('board_col_date_Pzt')), findsOneWidget);
    expect(find.byKey(const Key('board_col_badge_Pzt')), findsOneWidget);
    expect(find.text('inner'), findsOneWidget);
  });

  testWidgets('BoardColumn titleHighlightToday uses blue dot and blue title',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 200,
              child: BoardColumn(
                title: 'Pzt',
                dateShort: '19 May',
                badgeCount: 0,
                width: 200,
                titleHighlightToday: true,
                child: const Text('inner'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('board_col_today_dot_Pzt')), findsOneWidget);
    final title =
        tester.widget<Text>(find.byKey(const Key('board_col_title_Pzt')));
    expect(title.style?.color, DesignTokens.blue400);
    expect(title.style?.decoration, TextDecoration.none);
  });
}
