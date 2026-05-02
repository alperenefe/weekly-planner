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
                subtitle: '3 etkinlik',
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
    expect(find.byKey(const Key('board_col_sub_Pzt')), findsOneWidget);
    expect(find.byKey(const Key('board_col_badge_Pzt')), findsOneWidget);
    expect(find.text('inner'), findsOneWidget);
  });

  testWidgets('BoardColumn titleHighlightToday uses blue400 underline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 200,
              child: BoardColumn(
                title: 'Pzt',
                subtitle: null,
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

    final title = tester.widget<Text>(find.byKey(const Key('board_col_title_Pzt')));
    expect(title.style?.color, DesignTokens.blue400);
    expect(title.style?.decoration, TextDecoration.underline);
  });
}
