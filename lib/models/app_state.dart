import 'package:flutter/foundation.dart';
import 'book.dart';
import '../services/book_service.dart';
import '../services/user_shelf_service.dart';

/// Central state management for the app
/// Manages book collection and user's reading shelves (Want to Read, Reading, Finished)
class AppState extends ChangeNotifier {
  // All available books in the library
  final List<Book> _allBooks = [];
  // Maps book keys to their shelf status (Want to Read, Reading, or Finished)
  final Map<String, ShelfStatus> _userShelves = {};
  // Firebase service for book operations
  final BookService _bookService = BookService();
  final UserShelfService _userShelfService = UserShelfService();
  // Loading state
  bool _isLoading = false;
  String? _error;

  AppState() {
    _loadBooksFromFirebase();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Public getter that returns an unmodifiable copy of all books
  List<Book> get allBooks => List.unmodifiable(_allBooks);

  // Get the current shelf status for a specific book
  ShelfStatus? statusFor(Book book) => _userShelves[book.key];

  // Update a book's shelf status and persist to Firestore
  Future<void> setStatus(
    Book book,
    ShelfStatus? status, {
    String? userId,
  }) async {
    if (status == null) {
      _userShelves.remove(book.key);
      if (userId != null) {
        try {
          await _userShelfService.removeBookFromShelf(userId, book.id);
        } catch (e) {
          _error = 'Failed to remove book from shelf: $e';
          notifyListeners();
          rethrow;
        }
      }
    } else {
      _userShelves[book.key] = status;
      if (userId != null) {
        try {
          await _userShelfService.setBookStatus(
            userId,
            book.id,
            status.toString().split('.').last,
          );
        } catch (e) {
          _error = 'Failed to update book status: $e';
          notifyListeners();
          rethrow;
        }
      }
    }
    notifyListeners();
  }

  // Getter methods for each shelf category
  List<Book> get wantToReadBooks => _booksWithStatus(ShelfStatus.wantToRead);
  List<Book> get readingBooks => _booksWithStatus(ShelfStatus.reading);
  List<Book> get finishedBooks => _booksWithStatus(ShelfStatus.finished);

  // Helper method to filter books by shelf status, sorted alphabetically
  List<Book> _booksWithStatus(ShelfStatus status) {
    return _allBooks.where((b) => _userShelves[b.key] == status).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  // Extract unique genres from all books for filtering
  List<String> get genres {
    final set = <String>{};
    for (final b in _allBooks) {
      set.add(b.genre);
    }
    final list = set.toList()..sort();
    return list;
  }

  // Calculate trending books using a popularity score formula
  // Score = rating × (1 + ratingCount/50) to balance rating and popularity
  List<Book> get trendingBooks {
    final copy = [..._allBooks];
    copy.sort((a, b) {
      final scoreA = a.rating * (1 + a.ratingCount / 50.0);
      final scoreB = b.rating * (1 + b.ratingCount / 50.0);
      return scoreB.compareTo(scoreA);
    });
    return copy.take(10).toList();
  }

  // Get top 10 books sorted by rating alone
  List<Book> get topRatedBooks {
    final copy = [..._allBooks];
    copy.sort((a, b) => b.rating.compareTo(a.rating));
    return copy.take(10).toList();
  }

  // Filter books by genre, sorted by rating
  List<Book> booksByGenre(String? genre) {
    if (genre == null || genre.isEmpty) return allBooks;
    return _allBooks.where((b) => b.genre == genre).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  // Personalized recommendations based on user's reading history
  // If user has finished books, recommend similar books from the same genre
  // Uses most recently finished book (based on timestamp from Firestore)
  Future<List<Book>> recommendations({String? userId}) async {
    if (finishedBooks.isEmpty) return trendingBooks;

    if (userId != null) {
      try {
        // Get most recent finished book by timestamp
        final mostRecent = await _userShelfService.getMostRecentFinishedBook(
          userId,
        );
        if (mostRecent != null) {
          // Find the corresponding book
          final lastFinishedBook = _allBooks.firstWhere(
            (b) => b.id == mostRecent.bookId,
            orElse: () => finishedBooks.first, // Fallback to first in list
          );

          return booksByGenre(
            lastFinishedBook.genre,
          ).where((b) => b.key != lastFinishedBook.key).take(10).toList();
        }
      } catch (e) {
        // Log error but continue with fallback
        print('Error getting recent finished book: $e');
      }
    }

    // Fallback: use the current in-memory state sorted by ID
    finishedBooks.sort((a, b) => b.id.compareTo(a.id));
    final lastFinished = finishedBooks.first;
    return booksByGenre(
      lastFinished.genre,
    ).where((b) => b.key != lastFinished.key).take(10).toList();
  }

  // Synchronous version for backward compatibility
  List<Book> recommendationsSync({String? userId}) {
    if (finishedBooks.isEmpty) return trendingBooks;

    // Fallback: use the current in-memory state sorted by ID
    finishedBooks.sort((a, b) => b.id.compareTo(a.id));
    final lastFinished = finishedBooks.first;
    return booksByGenre(
      lastFinished.genre,
    ).where((b) => b.key != lastFinished.key).take(10).toList();
  }

  /// Load books from Firebase Firestore
  Future<void> _loadBooksFromFirebase() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final books = await _bookService.getAllBooksOnce();
      _allBooks.clear();
      _allBooks.addAll(books);
      _error = null;
    } catch (e) {
      _error = 'Failed to load books: $e';
      // Show empty state if Firebase fails
      _allBooks.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh books from Firebase
  /// Can be called manually to reload the book list
  Future<void> refreshBooks() async {
    await _loadBooksFromFirebase();
  }

  /// Add a new book to Firebase
  /// Returns the next available ID based on existing books
  Future<void> addBook(Book book) async {
    try {
      await _bookService.addBook(book);
      // Refresh the list to include the new book
      await refreshBooks();
    } catch (e) {
      _error = 'Failed to add book: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing book in Firebase
  Future<void> updateBook(Book book) async {
    try {
      await _bookService.updateBook(book);
      // Refresh the list to reflect changes
      await refreshBooks();
    } catch (e) {
      _error = 'Failed to update book: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a book from Firebase
  Future<void> deleteBook(int bookId) async {
    try {
      await _bookService.deleteBook(bookId);
      // Refresh the list to remove the deleted book
      await refreshBooks();
    } catch (e) {
      _error = 'Failed to delete book: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Load user shelf data from Firestore
  Future<void> loadUserShelf(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final shelfEntries = await _userShelfService.getUserShelf(userId);
      _userShelves.clear();

      for (final entry in shelfEntries) {
        // Find the corresponding book and map the status
        final book = _allBooks.firstWhere(
          (b) => b.id == entry.bookId,
          orElse: () => Book(
            id: entry.bookId,
            title: 'Unknown Book',
            author: 'Unknown',
            genre: 'Unknown',
            pages: 0,
            rating: 0.0,
            ratingCount: 0,
          ),
        );

        // Map string status to ShelfStatus enum
        final statusString = entry.shelfStatus.toLowerCase();
        ShelfStatus? status;
        switch (statusString) {
          case 'wanttoread':
            status = ShelfStatus.wantToRead;
            break;
          case 'reading':
            status = ShelfStatus.reading;
            break;
          case 'finished':
            status = ShelfStatus.finished;
            break;
        }

        if (status != null) {
          _userShelves[book.key] = status;
        }
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to load user shelf: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user shelf data
  Future<void> refreshUserShelf(String userId) async {
    await loadUserShelf(userId);
  }

  /// Get the next available book ID
  /// Finds the highest ID and adds 1
  int getNextBookId() {
    if (_allBooks.isEmpty) return 1;
    final maxId = _allBooks.map((b) => b.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }
}
