/// Enrollment model for managing student-class relationships
class Enrollment {
  final String id;
  final String classId;
  final String studentId;
  final DateTime enrolledAt;

  const Enrollment({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.enrolledAt,
  });

  /// Create Enrollment from Firestore document
  factory Enrollment.fromMap(String id, Map<String, dynamic> map) {
    return Enrollment(
      id: id,
      classId: map['classId'] as String,
      studentId: map['studentId'] as String,
      enrolledAt: (map['enrolledAt'] as dynamic).toDate(),
    );
  }

  /// Convert Enrollment to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'studentId': studentId,
      'enrolledAt': enrolledAt,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Enrollment &&
        other.id == id &&
        other.classId == classId &&
        other.studentId == studentId;
  }

  @override
  int get hashCode => id.hashCode ^ classId.hashCode ^ studentId.hashCode;

  @override
  String toString() =>
      'Enrollment(id: $id, classId: $classId, studentId: $studentId)';
}
