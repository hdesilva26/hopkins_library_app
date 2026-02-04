import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherClassService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleAdmin = 'admin';

  /// Create a class owned by a teacher
  Future<String> createClass({
    required String teacherId,
    required String className,
  }) async {
    final doc = await _db.collection('classes').add({
      'name': className.trim(),
      'teacherId': teacherId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  /// Delete a class (and its students). Use carefully.
  Future<void> deleteClass({
    required String classId,
    required String teacherId,
  }) async {
    final classRef = _db.collection('classes').doc(classId);
    final classSnap = await classRef.get();

    if (!classSnap.exists) throw Exception('Class not found');
    final data = classSnap.data() as Map<String, dynamic>;
    if (data['teacherId'] != teacherId) throw Exception('Not authorized');

    // Delete students subcollection docs
    final studentsSnap = await classRef.collection('students').get();
    final batch = _db.batch();
    for (final doc in studentsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(classRef);
    await batch.commit();
  }

  /// Add a student to a class (creates/overwrites doc with id = userId)
  Future<void> addStudentToClass({
    required String classId,
    required String teacherId,
    required String studentUserId,
    required String email,
    String? displayName,
  }) async {
    final classRef = _db.collection('classes').doc(classId);
    final classSnap = await classRef.get();

    if (!classSnap.exists) throw Exception('Class not found');
    final data = classSnap.data() as Map<String, dynamic>;
    if (data['teacherId'] != teacherId) throw Exception('Not authorized');

    await classRef.collection('students').doc(studentUserId).set({
      'userId': studentUserId,
      'email': email,
      'displayName': displayName ?? '',
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeStudentFromClass({
    required String classId,
    required String teacherId,
    required String studentUserId,
  }) async {
    final classRef = _db.collection('classes').doc(classId);
    final classSnap = await classRef.get();

    if (!classSnap.exists) throw Exception('Class not found');
    final data = classSnap.data() as Map<String, dynamic>;
    if (data['teacherId'] != teacherId) throw Exception('Not authorized');

    await classRef.collection('students').doc(studentUserId).delete();
  }

  /// Query: teacher’s classes
  Stream<QuerySnapshot> teacherClassesStream(String teacherId) {
    return _db
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Query: roster for a class
  Stream<QuerySnapshot> classStudentsStream(String classId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('students')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  /// Search students in users collection by email/name prefix.
  /// NOTE: Firestore doesn’t support "contains" well without extra indexing.
  /// This uses a prefix search via range query.
  Future<List<QueryDocumentSnapshot>> searchStudents({
    required String query,
    int limit = 25,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    // Try email prefix search
    final emailSnap = await _db
        .collection('users')
        .where('role', isEqualTo: roleStudent)
        .orderBy('emailLower') // You should store emailLower for easy search
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .limit(limit)
        .get();

    if (emailSnap.docs.isNotEmpty) return emailSnap.docs;

    // Fallback: displayName prefix search (if you store displayNameLower)
    final nameSnap = await _db
        .collection('users')
        .where('role', isEqualTo: roleStudent)
        .orderBy('displayNameLower')
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .limit(limit)
        .get();

    return nameSnap.docs;
  }
}
