import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import '../models/enrollment.dart';

/// Service for managing classes and enrollments in Firestore
class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _classesCollection = 'classes';
  final String _enrollmentsCollection = 'enrollments';

  /// Create a new class
  Future<String> createClass({
    required String name,
    required String teacherId,
  }) async {
    final docRef = _firestore.collection(_classesCollection).doc();
    final classModel = ClassModel(
      id: docRef.id,
      name: name,
      teacherId: teacherId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(classModel.toMap());
    return docRef.id;
  }

  /// Get all classes for a specific teacher
  Stream<List<ClassModel>> getTeacherClasses(String teacherId) {
    return _firestore
        .collection(_classesCollection)
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Get a single class by ID
  Future<ClassModel?> getClassById(String classId) async {
    final doc = await _firestore
        .collection(_classesCollection)
        .doc(classId)
        .get();
    if (doc.exists) {
      return ClassModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// Update class name
  Future<void> updateClassName(String classId, String newName) async {
    await _firestore.collection(_classesCollection).doc(classId).update({
      'name': newName,
      'updatedAt': DateTime.now(),
    });
  }

  /// Delete a class and all its enrollments
  Future<void> deleteClass(String classId) async {
    // First, delete all enrollments for this class
    final enrollmentsSnapshot = await _firestore
        .collection(_enrollmentsCollection)
        .where('classId', isEqualTo: classId)
        .get();

    final batch = _firestore.batch();
    for (final doc in enrollmentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the class itself
    batch.delete(_firestore.collection(_classesCollection).doc(classId));

    await batch.commit();
  }

  /// Enroll a student in a class
  Future<String> enrollStudent({
    required String classId,
    required String studentId,
  }) async {
    // Check if student is already enrolled
    final existingEnrollment = await _firestore
        .collection(_enrollmentsCollection)
        .where('classId', isEqualTo: classId)
        .where('studentId', isEqualTo: studentId)
        .get();

    if (existingEnrollment.docs.isNotEmpty) {
      throw Exception('Student is already enrolled in this class');
    }

    final docRef = _firestore.collection(_enrollmentsCollection).doc();
    final enrollment = Enrollment(
      id: docRef.id,
      classId: classId,
      studentId: studentId,
      enrolledAt: DateTime.now(),
    );

    await docRef.set(enrollment.toMap());
    return docRef.id;
  }

  /// Remove a student from a class
  Future<void> removeStudent({
    required String classId,
    required String studentId,
  }) async {
    final enrollmentSnapshot = await _firestore
        .collection(_enrollmentsCollection)
        .where('classId', isEqualTo: classId)
        .where('studentId', isEqualTo: studentId)
        .get();

    if (enrollmentSnapshot.docs.isEmpty) {
      throw Exception('Student is not enrolled in this class');
    }

    await enrollmentSnapshot.docs.first.reference.delete();
  }

  /// Get all enrollments for a class
  Stream<List<Enrollment>> getClassEnrollments(String classId) {
    return _firestore
        .collection(_enrollmentsCollection)
        .where('classId', isEqualTo: classId)
        .orderBy('enrolledAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Enrollment.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Get all classes for a student
  Stream<List<ClassModel>> getStudentClasses(String studentId) {
    return _firestore
        .collection(_enrollmentsCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .asyncMap((enrollmentsSnapshot) async {
          final classIds = enrollmentsSnapshot.docs
              .map((doc) => Enrollment.fromMap(doc.id, doc.data()).classId)
              .toList();

          if (classIds.isEmpty) return <ClassModel>[];

          final classesSnapshot = await _firestore
              .collection(_classesCollection)
              .where(FieldPath.documentId, whereIn: classIds)
              .orderBy('createdAt', descending: true)
              .get();

          return classesSnapshot.docs
              .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Check if a student is enrolled in a specific class
  Future<bool> isStudentEnrolled(String classId, String studentId) async {
    final enrollmentSnapshot = await _firestore
        .collection(_enrollmentsCollection)
        .where('classId', isEqualTo: classId)
        .where('studentId', isEqualTo: studentId)
        .get();

    return enrollmentSnapshot.docs.isNotEmpty;
  }

  /// Get all students enrolled in a class with their user data
  Stream<List<Map<String, dynamic>>> getClassStudents(String classId) {
    return _firestore
        .collection(_enrollmentsCollection)
        .where('classId', isEqualTo: classId)
        .snapshots()
        .asyncMap((enrollmentsSnapshot) async {
          final studentIds = enrollmentsSnapshot.docs
              .map((doc) => Enrollment.fromMap(doc.id, doc.data()).studentId)
              .toList();

          if (studentIds.isEmpty) return <Map<String, dynamic>>[];

          final usersSnapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: studentIds)
              .get();

          return usersSnapshot.docs.map((doc) {
            final userData = doc.data();
            userData['uid'] = doc.id;
            return userData;
          }).toList();
        });
  }
}
