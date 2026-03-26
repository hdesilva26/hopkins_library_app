import 'package:flutter/foundation.dart';
import 'book.dart';
import '../services/book_service.dart';

final List<Book> _sampleBooks = [
  Book(
    id: 1,
    title: 'The Hobbit',
    author: 'J.R.R. Tolkien',
    genre: 'Fantasy',
    pages: 310,
    isRequired: false,
    isbn: '9780547928227',
  ),
  Book(
    id: 2,
    title: 'To Kill a Mockingbird',
    author: 'Harper Lee',
    genre: 'Fiction',
    pages: 281,
    isRequired: true,
    isbn: '9780061120084',
  ),
  Book(
    id: 3,
    title: '1984',
    author: 'George Orwell',
    genre: 'Dystopian',
    pages: 328,
    isRequired: true,
    isbn: '9780451524935',
  ),
  Book(
    id: 4,
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    genre: 'Romance',
    pages: 279,
    isRequired: false,
    isbn: '9780141439518',
  ),
  Book(
    id: 5,
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    genre: 'Classic',
    pages: 180,
    isRequired: true,
    isbn: '9780743273565',
  ),
  Book(
    id: 6,
    title: 'Harry Potter and the Sorcerer\'s Stone',
    author: 'J.K. Rowling',
    genre: 'Fantasy',
    pages: 309,
    isRequired: false,
    isbn: '9780590353427',
  ),
  Book(
    id: 7,
    title: 'The Catcher in the Rye',
    author: 'J.D. Salinger',
    genre: 'Fiction',
    pages: 234,
    isRequired: false,
    isbn: '9780316769488',
  ),
  Book(
    id: 8,
    title: 'Lord of the Flies',
    author: 'William Golding',
    genre: 'Classic',
    pages: 224,
    isRequired: true,
    isbn: '9780399501487',
  ),
  Book(
    id: 9,
    title: 'Brave New World',
    author: 'Aldous Huxley',
    genre: 'Dystopian',
    pages: 268,
    isRequired: false,
    isbn: '9780060850524',
  ),
  Book(
    id: 10,
    title: 'The Hunger Games',
    author: 'Suzanne Collins',
    genre: 'Sci-Fi',
    pages: 374,
    isRequired: false,
    isbn: '9780439023481',
  ),
];

class AppState extends ChangeNotifier {
  final List<Book> _allBooks = [];
  final Map<String, ShelfStatus> _userShelves = {};
  final BookService _bookService = BookService();
  bool _isLoading = false;
  String? _error;

  AppState() {
    _loadBooksFromFirebase();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Book> get allBooks => List.unmodifiable(_allBooks);

  ShelfStatus? statusFor(Book book) => _userShelves[book.key];

  void setStatus(Book book, ShelfStatus? status) {
    if (status == null) {
      _userShelves.remove(book.key);
    } else {
      _userShelves[book.key] = status;
    }
    notifyListeners();
  }

  List<Book> get wantToReadBooks => _booksWithStatus(ShelfStatus.wantToRead);
  List<Book> get readingBooks => _booksWithStatus(ShelfStatus.reading);
  List<Book> get finishedBooks => _booksWithStatus(ShelfStatus.finished);

  List<Book> _booksWithStatus(ShelfStatus status) {
    return _allBooks.where((b) => _userShelves[b.key] == status).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  List<String> get genres {
    final set = <String>{};
    for (final b in _allBooks) {
      set.add(b.genre);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Book> get trendingBooks {
    final copy = [..._allBooks];
    copy.sort((a, b) => b.title.compareTo(a.title));
    return copy.take(10).toList();
  }

  List<Book> get topRatedBooks {
    final copy = [..._allBooks];
    copy.sort((a, b) => b.title.compareTo(a.title));
    return copy.take(10).toList();
  }

  List<Book> booksByGenre(String? genre) {
    if (genre == null || genre.isEmpty) return allBooks;
    return _allBooks.where((b) => b.genre == genre).toList()
      ..sort((a, b) => b.title.compareTo(a.title));
  }

  List<Book> recommendations() {
    if (finishedBooks.isEmpty) return trendingBooks;
    finishedBooks.sort((a, b) => b.id.compareTo(a.id));
    final lastFinished = finishedBooks.first;
    return booksByGenre(
      lastFinished.genre,
    ).where((b) => b.key != lastFinished.key).take(10).toList();
  }

  Future<void> _loadBooksFromFirebase() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final books = await _bookService.getAllBooksOnce();
      _allBooks.clear();
      if (books.isEmpty) {
        _allBooks.addAll(_sampleBooks);
      } else {
        _allBooks.addAll(books);
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to load books: $e';
      _allBooks.clear();
      _allBooks.addAll(_sampleBooks);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBooks() async {
    await _loadBooksFromFirebase();
  }

  Future<void> addBook(Book book) async {
    try {
      await _bookService.addBook(book);
      await refreshBooks();
    } catch (e) {
      _error = 'Failed to add book: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBook(Book book) async {
    try {
      await _bookService.updateBook(book);
      await refreshBooks();
    } catch (e) {
      _error = 'Failed to update book: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBook(int bookId) async {
    try {
      await _bookService.deleteBook(bookId);
      await refreshBooks();
    } catch (e) {
      _error = 'Failed to delete book: $e';
      notifyListeners();
      rethrow;
    }
  }

  int getNextBookId() {
    if (_allBooks.isEmpty) return 1;
    final maxId = _allBooks.map((b) => b.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }
}
