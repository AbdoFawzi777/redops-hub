class FieldReport {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? status; // e.g., 'Transmitted', 'Reviewed'

  const FieldReport({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.status = 'Transmitted',
  });

  FieldReport copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? createdAt,
    String? status,
  }) {
    return FieldReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
