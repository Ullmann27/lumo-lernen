class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.grade,
    required this.createdAt,
    required this.lastActiveAt,
  });

  final String id;
  final String name;
  final int age;
  final int grade;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'grade': grade,
        'createdAt': createdAt.toIso8601String(),
        'lastActiveAt': lastActiveAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'local',
      name: json['name'] as String? ?? 'Kind',
      age: (json['age'] as num?)?.toInt() ?? 7,
      grade: (json['grade'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      lastActiveAt: DateTime.tryParse(json['lastActiveAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? name,
    int? age,
    int? grade,
    DateTime? lastActiveAt,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      grade: grade ?? this.grade,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
