class TodoCategory {
  const TodoCategory({
    required this.id,
    required this.name,
    this.colorArgb,
    required this.sortOrder,
    required this.createdAt,
  });

  final int id;
  final String name;
  final int? colorArgb;
  final int sortOrder;
  final String createdAt;
}
