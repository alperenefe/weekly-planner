import 'package:drift/drift.dart';

import '../db/app_database.dart';

class RecurringTemplateRepository {
  RecurringTemplateRepository(this._db);

  final AppDatabase _db;

  Future<int> insertTemplate(RecurringTemplatesCompanion data) {
    return _db.into(_db.recurringTemplates).insert(data);
  }

  Future<List<RecurringTemplate>> getActiveTemplates() {
    return (_db.select(_db.recurringTemplates)
          ..where((t) => t.isActive.equals(1)))
        .get();
  }

  Future<void> deactivateTemplate(int id) {
    return (_db.update(_db.recurringTemplates)..where((t) => t.id.equals(id))).write(
          const RecurringTemplatesCompanion(isActive: Value(0)),
        );
  }
}
