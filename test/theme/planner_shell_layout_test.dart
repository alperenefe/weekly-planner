import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/theme/planner_shell_layout.dart';

void main() {
  testWidgets('plannerShellFabBottomPadding includes nav bar and safe area',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 24)),
          child: Builder(
            builder: (context) {
              final pad = plannerShellFabBottomPadding(context);
              expect(pad, kBottomNavigationBarHeight + 24 + 24);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });
}
