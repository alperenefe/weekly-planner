import '../data/db/app_database.dart';

class PostponeAnalysis {
  const PostponeAnalysis({
    required this.mostMovedTasks,
    required this.neverMovedCompleted,
    required this.avgMovesPerMovedTask,
  });

  final List<Task> mostMovedTasks;
  final int neverMovedCompleted;
  final double avgMovesPerMovedTask;
}
