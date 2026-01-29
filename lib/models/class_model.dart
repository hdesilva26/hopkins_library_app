/// Class model for managing teacher classes
class ClassModel {
  final String id;
  final String name;
  final String teacherId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassModel({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ClassModel from Firestore document
  factory ClassModel.fromMap(String id, Map<String, dynamic> map) {
    return ClassModel(
      id: id,
      name: map['name'] as String,
      teacherId: map['teacherId'] as String,
      createdAt: (map['createdAt'] as dynamic).toDate(),
      updatedAt: (map['updatedAt'] as dynamic).toDate(),
    );
  }

  /// Convert ClassModel to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teacherId': teacherId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create copy with updated fields
  ClassModel copyWith({String? name, String? teacherId, DateTime? updatedAt}) {
    return ClassModel(
      id: id,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassModel &&
        other.id == id &&
        other.name == name &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ teacherId.hashCode;

  @override
  String toString() =>
      'ClassModel(id: $id, name: $name, teacherId: $teacherId)';
}
