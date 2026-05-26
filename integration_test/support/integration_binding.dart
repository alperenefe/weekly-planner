import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/test_pump.dart';

export '../../test/test_pump.dart' show pumpSettleBounded;

/// Integration test girişi: cihaz/host binding + temiz SharedPreferences.
void ensurePlannerIntegrationBinding() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
}

/// `pumpAndSettle` sonsuz beklemesin (odak sayacı vb.).
Future<void> integrationPumpSettle(WidgetTester tester) =>
    pumpSettleBounded(tester, timeout: const Duration(seconds: 8));
