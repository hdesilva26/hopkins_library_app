import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing user roles and profiles in Firestore
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  /// User roles
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher'; // ADD THIS
  static const String roleAdmin = 'admin';

  /// Get user role from Firestore
  /// Returns 'student' by default if user doesn't exist or has no role
  Future<String> getUserRole(String userId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(userId).get();

      if (doc.exists) {
        final role = doc.data()?['role'] as String?;
        return role ?? roleStudent;
      }

      // If user doesn't exist in Firestore, create them as student
      await _firestore.collection(_collectionName).doc(userId).set({
        'role': roleStudent,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return roleStudent;
    } catch (e) {
      // On error, default to student
      return roleStudent;
    }
  }

  /// Set user role (admin only operation)
  /// Accepts: student | teacher | admin
  Future<void> setUserRole(String userId, String role) async {
    await _firestore.collection(_collectionName).doc(userId).set({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Check if user is admin
  Future<bool> isAdmin(String userId) async {
    final role = await getUserRole(userId);
    return role == roleAdmin;
  }

  /// Check if user is teacher
  Future<bool> isTeacher(String userId) async {
    final role = await getUserRole(userId);
    return role == roleTeacher;
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(userId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection(_collectionName).doc(userId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
