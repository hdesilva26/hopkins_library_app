import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_shelf_entry.dart';

/// Service for managing user book shelves in Firestore
/// Each shelf entry is stored in: users/{userId}/shelf/{bookId}
class UserShelfService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get reference to a user's shelf sub-collection
  CollectionReference<Map<String, dynamic>> _userShelfRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('shelf');
  }

  /// Get all shelf entries for a user
  Future<List<UserShelfEntry>> getUserShelf(String userId) async {
    try {
      final snapshot = await _userShelfRef(userId).get();
      return snapshot.docs
          .map((doc) => UserShelfEntry.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load user shelf: $e');
    }
  }

  /// Add or update a book in user's shelf
  Future<void> setBookStatus(
    String userId,
    int bookId,
    String shelfStatus,
  ) async {
    try {
      final entry = UserShelfEntry(
        userId: userId,
        bookId: bookId,
        shelfStatus: shelfStatus,
        updatedAt: DateTime.now(),
      );

      await _userShelfRef(userId).doc(bookId.toString()).set(entry.toMap());
    } catch (e) {
      throw Exception('Failed to update book status: $e');
    }
  }

  /// Remove a book from user's shelf
  Future<void> removeBookFromShelf(String userId, int bookId) async {
    try {
      await _userShelfRef(userId).doc(bookId.toString()).delete();
    } catch (e) {
      throw Exception('Failed to remove book from shelf: $e');
    }
  }

  /// Get books for a specific shelf status
  Future<List<int>> getBooksByStatus(String userId, String shelfStatus) async {
    try {
      final snapshot = await _userShelfRef(
        userId,
      ).where('shelfStatus', isEqualTo: shelfStatus).get();

      return snapshot.docs.map((doc) => doc.data()['bookId'] as int).toList();
    } catch (e) {
      throw Exception('Failed to get books by status: $e');
    }
  }

  /// Get the most recently finished book for a user
  Future<UserShelfEntry?> getMostRecentFinishedBook(String userId) async {
    try {
      final snapshot = await _userShelfRef(userId)
          .where('shelfStatus', isEqualTo: 'finished')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return UserShelfEntry.fromMap(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get most recent finished book: $e');
    }
  }

  /// Clear all entries for a user (useful for testing)
  Future<void> clearUserShelf(String userId) async {
    try {
      final snapshot = await _userShelfRef(userId).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to clear user shelf: $e');
    }
  }
}
