import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weekly_planner/theme/motion_accessibility.dart';
import 'package:weekly_planner/widgets/pressable_scale.dart';

void main() {
  testWidgets('MotionAccessibility reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            expect(
              MotionAccessibility.reduced(context),
              isFalse,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('PressableScale reduced motion scale 1', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: PressableScale(
              onTap: () {},
              child: const Text('kart'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('kart'));
    await tester.pump(const Duration(milliseconds: 200));
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 1);
  });
}
