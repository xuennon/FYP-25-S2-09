class Team {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> members;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isActive;

  Team({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.members,
    this.imageUrl,
    required this.createdAt,
    this.isActive = true,
  });

  factory Team.fromMap(Map<String, dynamic> map, String id) {
    return Team(
      id: id,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      createdBy: map['createdBy']?.toString() ?? '',
      members: List<String>.from(map['members'] ?? []),
      imageUrl: map['imageUrl']?.toString(),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'members': members,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  int get memberCount => members.length;

  bool isMember(String userId) {
    return members.contains(userId);
  }

  bool isCreator(String userId) {
    return createdBy == userId;
  }

  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    List<String>? members,
    String? imageUrl,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
