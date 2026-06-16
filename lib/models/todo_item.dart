class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    this.categoryId,
    this.deadlineDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final int id;
  final String title;
  final int? categoryId;
  /// `YYYY-MM-DD` veya null (deadline yok).
  final String? deadlineDate;
  final String status;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;

  bool get isDone => status == 'done';
}
