class ChatGroup {
  final String id;
  final String name;
  final String description;
  final String ownerEmail; // Responsible admin
  final List<String> members; // Allowed operator emails

  ChatGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerEmail,
    required this.members,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerEmail': ownerEmail,
      'members': members,
    };
  }

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    return ChatGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Group',
      description: json['description'] ?? '',
      ownerEmail: json['ownerEmail'] ?? '',
      members: List<String>.from(json['members'] ?? []),
    );
  }
}
