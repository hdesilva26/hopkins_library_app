import 'package:flutter/foundation.dart';
import 'book.dart';
import '../services/book_service.dart';

/// Sample books for demonstration when Firestore is empty
/// These books have ISBNs for working cover art from Open Library
final List<Book> _sampleBooks = [
  Book(
    id: 1,
    title: 'The Hobbit',
    author: 'J.R.R. Tolkien',
    genre: 'Fantasy',
    pages: 310,
    rating: 4.8,
    ratingCount: 2500000,
    isCommitteePick: true,
    isRequired: false,
    isbn: '9780547928227',
  ),
  Book(
    id: 2,
    title: 'To Kill a Mockingbird',
    author: 'Harper Lee',
    genre: 'Fiction',
    pages: 281,
    rating: 4.7,
    ratingCount: 5000000,
    isCommitteePick: true,
    isRequired: true,
    isbn: '9780061120084',
  ),
  Book(
    id: 3,
    title: '1984',
    author: 'George Orwell',
    genre: 'Dystopian',
    pages: 328,
    rating: 4.6,
    ratingCount: 3000000,
    isCommitteePick: false,
    isRequired: true,
    isbn: '9780451524935',
  ),
  Book(
    id: 4,
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    genre: 'Romance',
    pages: 279,
    rating: 4.5,
    ratingCount: 2000000,
    isCommitteePick: false,
    isRequired: false,
    isbn: '9780141439518',
  ),
  Book(
    id: 5,
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    genre: 'Classic',
    pages: 180,
    rating: 4.4,
    ratingCount: 3500000,
    isCommitteePick: true,
    isRequired: true,
    isbn: '9780743273565',
  ),
  Book(
    id: 6,
    title: 'Harry Potter and the Sorcerer\'s Stone',
    author: 'J.K. Rowling',
    genre: 'Fantasy',
    pages: 309,
    rating: 4.9,
    ratingCount: 6000000,
    isCommitteePick: true,
    isRequired: false,
    isbn: '9780590353427',
  ),
  Book(
    id: 7,
    title: 'The Catcher in the Rye',
    author: 'J.D. Salinger',
    genre: 'Fiction',
    pages: 234,
    rating: 4.1,
    ratingCount: 1500000,
    isCommitteePick: false,
    isRequired: false,
    isbn: '9780316769488',
  ),
  Book(
    id: 8,
    title: 'Lord of the Flies',
    author: 'William Golding',
    genre: 'Classic',
    pages: 224,
    rating: 4.0,
    ratingCount: 1800000,
    isCommitteePick: false,
    isRequired: true,
    isbn: '9780399501487',
  ),
  Book(
    id: 9,
    title: 'Brave New World',
    author: 'Aldous Huxley',
    genre: 'Dystopian',
    pages: 268,
    rating: 4.3,
    ratingCount: 1200000,
    isCommitteePick: false,
    isRequired: false,
    isbn: '9780060850524',
  ),
  Book(
    id: 10,
    title: 'The Hunger Games',
    author: 'Suzanne Collins',
    genre: 'Sci-Fi',
    pages: 374,
    rating: 4.7,
    ratingCount: 4000000,
    isCommitteePick: true,
    isRequired: false,
    isbn: '9780439023481',
  ),
];

/// Central state management for the app
/// Manages book collection and user's reading shelves (Want to Read, Reading, Finished)
class AppState extends ChangeNotifier {
  // All available books in the library
  final List<Book> _allBooks = [];
  // Maps book keys to their shelf status (Want to Read, Reading, or Finished)
  final Map<String, ShelfStatus> _userShelves = {};
  // Firebase service for book operations
  final BookService _bookService = BookService();
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

  // Update a book's shelf status and notify listeners to rebuild UI
  void setStatus(Book book, ShelfStatus? status) {
    if (status == null) {
      _userShelves.remove(book.key);
    } else {
      _userShelves[book.key] = status;
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
  // Otherwise, show trending books
  List<Book> recommendations() {
    if (finishedBooks.isEmpty) return trendingBooks;
    finishedBooks.sort((a, b) => b.id.compareTo(a.id));
    final lastFinished = finishedBooks.first;
    return booksByGenre(
      lastFinished.genre,
    ).where((b) => b.key != lastFinished.key).take(10).toList();
  }

  /// Load books from Firebase Firestore
  /// Falls back to sample books if Firestore is empty or fails
  Future<void> _loadBooksFromFirebase() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final books = await _bookService.getAllBooksOnce();
      _allBooks.clear();
      if (books.isEmpty) {
        // Use sample books when Firestore is empty
        _allBooks.addAll(_sampleBooks);
      } else {
        _allBooks.addAll(books);
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to load books: $e';
      // Fall back to sample books when Firebase fails
      _allBooks.clear();
      _allBooks.addAll(_sampleBooks);
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

  /// Get the next available book ID
  /// Finds the highest ID and adds 1
  int getNextBookId() {
    if (_allBooks.isEmpty) return 1;
    final maxId = _allBooks.map((b) => b.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }
}
