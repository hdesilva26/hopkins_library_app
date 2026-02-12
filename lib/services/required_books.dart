import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

/// Service for managing required books in Firestore
/// Handles CRUD operations for required reading books
class RequiredBooksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'books';

  /// Get all required books from Firestore
  /// Returns a Stream that emits List<Book> whenever the collection changes
  Stream<List<Book>> getRequiredBooks() {
    return _firestore
        .collection(_collectionName)
        .where('isRequired', isEqualTo: true)
        .orderBy('title')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Book.fromMap(doc.data())).toList();
        });
  }

  /// Get all required books once (non-streaming)
  /// Useful for initial load or when you don't need real-time updates
  Future<List<Book>> getRequiredBooksOnce() async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('isRequired', isEqualTo: true)
        .orderBy('title')
        .get();

    return snapshot.docs.map((doc) => Book.fromMap(doc.data())).toList();
  }

  /// Get required books by genre
  Stream<List<Book>> getRequiredBooksByGenre(String genre) {
    return _firestore
        .collection(_collectionName)
        .where('isRequired', isEqualTo: true)
        .where('genre', isEqualTo: genre)
        .orderBy('title')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Book.fromMap(doc.data())).toList();
        });
  }

  /// Mark a book as required reading
  Future<void> markAsRequired(int bookId) async {
    await _firestore.collection(_collectionName).doc(bookId.toString()).update({
      'isRequired': true,
    });
  }

  /// Remove required reading status from a book
  Future<void> markAsNotRequired(int bookId) async {
    await _firestore.collection(_collectionName).doc(bookId.toString()).update({
      'isRequired': false,
    });
  }

  /// Get required books count
  Future<int> getRequiredBooksCount() async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('isRequired', isEqualTo: true)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Get required books by grade level (if implemented in Book model)
  /// This method assumes books might have a 'gradeLevel' field
  Stream<List<Book>> getRequiredBooksByGradeLevel(String gradeLevel) {
    return _firestore
        .collection(_collectionName)
        .where('isRequired', isEqualTo: true)
        .where('gradeLevel', isEqualTo: gradeLevel)
        .orderBy('title')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Book.fromMap(doc.data())).toList();
        });
  }

  /// Search required books by title or author
  Future<List<Book>> searchRequiredBooks(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _firestore
        .collection(_collectionName)
        .where('isRequired', isEqualTo: true)
        .orderBy('title')
        .get();

    final q = query.toLowerCase();
    return snapshot.docs
        .map((doc) => Book.fromMap(doc.data()))
        .where(
          (book) =>
              book.title.toLowerCase().contains(q) ||
              book.author.toLowerCase().contains(q),
        )
        .toList();
  }
}
