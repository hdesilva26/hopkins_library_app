import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

/// Service for managing book data in Firestore
/// Handles CRUD operations for books collection
class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'books';

  /// Get all books from Firestore
  /// Returns a Stream that emits List of Book whenever the collection changes
  Stream<List<Book>> getAllBooks() {
    return _firestore
        .collection(_collectionName)
        .orderBy('title')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Book.fromMap(doc.data())).toList();
        });
  }

  /// Get all books once (non-streaming)
  /// Useful for initial load or when you don't need real-time updates
  Future<List<Book>> getAllBooksOnce() async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .orderBy('title')
        .get();

    return snapshot.docs.map((doc) => Book.fromMap(doc.data())).toList();
  }

  /// Add a new book to Firestore
  /// Uses the book's ID as the document ID for easy lookup
  Future<void> addBook(Book book) async {
    await _firestore
        .collection(_collectionName)
        .doc(book.id.toString())
        .set(book.toMap());
  }

  /// Update an existing book in Firestore
  Future<void> updateBook(Book book) async {
    await _firestore
        .collection(_collectionName)
        .doc(book.id.toString())
        .update(book.toMap());
  }

  /// Delete a book from Firestore
  Future<void> deleteBook(int bookId) async {
    await _firestore
        .collection(_collectionName)
        .doc(bookId.toString())
        .delete();
  }

  /// Get a single book by ID
  Future<Book?> getBookById(int bookId) async {
    final doc = await _firestore
        .collection(_collectionName)
        .doc(bookId.toString())
        .get();

    if (doc.exists) {
      return Book.fromMap(doc.data()!);
    }
    return null;
  }

  /// Batch add multiple books (useful for migration)
  /// This is more efficient than adding books one by one
  Future<void> batchAddBooks(List<Book> books) async {
    final batch = _firestore.batch();

    for (final book in books) {
      final docRef = _firestore
          .collection(_collectionName)
          .doc(book.id.toString());
      batch.set(docRef, book.toMap());
    }

    await batch.commit();
  }
}
