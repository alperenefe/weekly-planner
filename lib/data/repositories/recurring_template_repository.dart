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

  Future<List<RecurringTemplate>> getAllTemplates() {
    return (_db.select(_db.recurringTemplates)
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();
  }

  Future<void> updateTemplate(int id, RecurringTemplatesCompanion data) {
    return (_db.update(_db.recurringTemplates)..where((t) => t.id.equals(id)))
        .write(data);
  }

  Future<void> deleteTemplate(int id) {
    return (_db.delete(_db.recurringTemplates)..where((t) => t.id.equals(id))).go();
  }
}
