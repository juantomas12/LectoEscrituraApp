class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return UserProfile(
        id: 'LOCAL-USER',
        displayName: 'ESTUDIANTE LOCAL',
        createdAt: DateTime.now(),
      );
    }

    return UserProfile(
      id: (map['id'] ?? 'LOCAL-USER').toString(),
      displayName: (map['displayName'] ?? 'ESTUDIANTE LOCAL').toString(),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
