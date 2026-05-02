import 'package:flutter/foundation.dart';

class PlanDataRevision extends ChangeNotifier {
  void bump() => notifyListeners();
}
