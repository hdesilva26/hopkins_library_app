import 'package:flutter/foundation.dart';
import 'book.dart';

class AppState extends ChangeNotifier {
  final List<Book> _allBooks = [];
  final Map<String, ShelfStatus> _userShelves = {};

  AppState() {
    _loadSampleData();
  }

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
    return _allBooks
        .where((b) => _userShelves[b.key] == status)
        .toList()
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
    copy.sort((a, b) {
      final scoreA = a.rating * (1 + a.ratingCount / 50.0);
      final scoreB = b.rating * (1 + b.ratingCount / 50.0);
      return scoreB.compareTo(scoreA);
    });
    return copy.take(10).toList();
  }

  List<Book> get topRatedBooks {
    final copy = [..._allBooks];
    copy.sort((a, b) => b.rating.compareTo(a.rating));
    return copy.take(10).toList();
  }

  List<Book> booksByGenre(String? genre) {
    if (genre == null || genre.isEmpty) return allBooks;
    return _allBooks.where((b) => b.genre == genre).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  List<Book> recommendations() {
    if (finishedBooks.isEmpty) return trendingBooks;
    finishedBooks.sort((a, b) => b.id.compareTo(a.id));
    final lastFinished = finishedBooks.first;
    return booksByGenre(lastFinished.genre)
        .where((b) => b.key != lastFinished.key)
        .take(10)
        .toList();
  }

  void _loadSampleData() {
    _allBooks.addAll([
      Book(
        id: 1,
        title: 'The Book Thief',
        author: 'Markus Zusak',
        genre: 'Historical Fiction',
        pages: 552,
        rating: 4.6,
        ratingCount: 4800,
        isCommitteePick: true,
        isbn: '9780375831003',
      ),
      Book(
        id: 2,
        title: 'The Hate U Give',
        author: 'Angie Thomas',
        genre: 'Realistic Fiction',
        pages: 464,
        rating: 4.7,
        ratingCount: 7600,
        isCommitteePick: true,
        isbn: '9780062498533',
      ),
      Book(
        id: 3,
        title: 'Educated',
        author: 'Tara Westover',
        genre: 'Memoir',
        pages: 352,
        rating: 4.5,
        ratingCount: 6000,
        isCommitteePick: true,
        isbn: '9780399590504',
      ),
      Book(
        id: 4,
        title: 'Sapiens',
        author: 'Yuval Noah Harari',
        genre: 'Nonfiction',
        pages: 498,
        rating: 4.4,
        ratingCount: 8500,
        isbn: '9780062316097',
      ),
      Book(
        id: 5,
        title: 'Dune',
        author: 'Frank Herbert',
        genre: 'Science Fiction',
        pages: 688,
        rating: 4.3,
        ratingCount: 12000,
        isbn: '9780441013593',
      ),
      Book(
        id: 6,
        title: 'The Hobbit',
        author: 'J.R.R. Tolkien',
        genre: 'Fantasy',
        pages: 310,
        rating: 4.7,
        ratingCount: 9000,
        isCommitteePick: true,
        isbn: '9780547928227',
      ),
      Book(
        id: 7,
        title: 'Stamped',
        author: 'Jason Reynolds & Ibram X. Kendi',
        genre: 'Nonfiction',
        pages: 320,
        rating: 4.4,
        ratingCount: 2200,
        isRequired: true,
        isbn: '9780316453691',
      ),
      Book(
        id: 8,
        title: 'The Things They Carried',
        author: "Tim O'Brien",
        genre: 'Historical Fiction',
        pages: 246,
        rating: 4.3,
        ratingCount: 5000,
        isCommitteePick: true,
        isbn: '9780618706419',
      ),
      Book(
        id: 9,
        title: 'They Both Die at the End',
        author: 'Adam Silvera',
        genre: 'Realistic Fiction',
        pages: 384,
        rating: 4.1,
        ratingCount: 7000,
        isbn: '9780062457790',
      ),
      Book(
        id: 10,
        title: 'Project Hail Mary',
        author: 'Andy Weir',
        genre: 'Science Fiction',
        pages: 496,
        rating: 4.6,
        ratingCount: 10000,
        isbn: '9780593135204',
      ),
    ]);
  }
}

