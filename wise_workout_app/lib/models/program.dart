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
    print('🏗️ Creating Program from map: $map with ID: $documentId');
    
    try {
      // Handle different createdAt formats
      DateTime createdAt;
      if (map['createdAt'] != null) {
        if (map['createdAt'] is String) {
          // If it's a string, try to parse it
          try {
            createdAt = DateTime.parse(map['createdAt']);
          } catch (e) {
            print('⚠️ Could not parse createdAt string: ${map['createdAt']}, using now()');
            createdAt = DateTime.now();
          }
        } else {
          // If it's a Timestamp, convert it
          try {
            createdAt = map['createdAt'].toDate();
          } catch (e) {
            print('⚠️ Could not convert createdAt timestamp: ${map['createdAt']}, using now()');
            createdAt = DateTime.now();
          }
        }
      } else {
        createdAt = DateTime.now();
      }
      
      // Extract and validate required fields
      final name = map['name']?.toString().trim() ?? '';
      final description = map['description']?.toString().trim() ?? '';
      final category = map['category']?.toString().trim() ?? '';
      final duration = map['duration']?.toString().trim() ?? 'Duration not specified';
      final createdBy = map['createdBy']?.toString().trim() ?? '';
      final imageUrl = map['imageUrl']?.toString().trim() ?? '';
      
      // Validate essential fields
      if (name.isEmpty) {
        throw Exception('Program name is required');
      }
      if (category.isEmpty) {
        throw Exception('Program category is required');
      }
      if (createdBy.isEmpty) {
        throw Exception('Program createdBy is required');
      }
      
      final program = Program(
        id: documentId,
        name: name,
        description: description,
        category: category,
        duration: duration,
        createdBy: createdBy,
        imageUrl: imageUrl,
        createdAt: createdAt,
        features: List<String>.from(map['features'] ?? []),
        isActive: map['isActive'] ?? true,
      );
      
      print('✅ Program created: ${program.name} (${program.category}) - ${program.duration}');
      return program;
    } catch (e) {
      print('❌ Error creating program from map: $e');
      rethrow;
    }
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
