import 'package:flutter_test/flutter_test.dart';

/// Odak zamanlayıcısı vb. nedeniyle `pumpAndSettle` takılırsa en fazla [timeout] bekler.
Future<void> pumpSettleBounded(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  await tester.pumpAndSettle(
    timeout,
    EnginePhase.sendSemanticsUpdate,
    const Duration(milliseconds: 50),
  );
}
