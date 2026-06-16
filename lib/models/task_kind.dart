import '../data/db/app_database.dart';

/// Haftalık plandaki kart türü: zamanlı iş vs gün etkinliği (saat şart değil).
abstract final class TaskKind {
  static const work = 'work';
  static const event = 'event';

  static bool isEvent(Task task) => task.taskKind == event;

  static bool isWork(Task task) => task.taskKind != event;
}
