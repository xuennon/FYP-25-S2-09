class Program {
  final String id;
  final String name;
  final String description;
  final String category;
  final String duration; // e.g., "8 weeks", "2 weeks"
  final String createdBy;
  final String imageUrl;
  final DateTime createdAt;
  final List<String> features;
  final bool isActive;

  Program({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.duration,
    required this.createdBy,
    this.imageUrl = '',
    required this.createdAt,
    this.features = const [],
    this.isActive = true,
  });

  factory Program.fromMap(Map<String, dynamic> map, String documentId) {
    return Program(
      id: documentId,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      duration: map['duration']?.toString() ?? '',
      createdBy: map['createdBy']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      features: List<String>.from(map['features'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'duration': duration,
      'createdBy': createdBy,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'features': features,
      'isActive': isActive,
    };
  }
}
