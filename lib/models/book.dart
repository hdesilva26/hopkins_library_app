/// Book data model representing a book in the library
/// Contains metadata like title, author, genre, ratings, and special flags
class Book {
  final int id;
  final String title;
  final String author;
  final String genre;
  final int pages;
  final double rating;
  final int ratingCount;
  final bool isCommitteePick;  // Special designation by reading committee
  final bool isRequired;        // Required reading for students
  final String? isbn;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.pages,
    required this.rating,
    required this.ratingCount,
    this.isCommitteePick = false,
    this.isRequired = false,
    this.isbn,
  });

  // Unique identifier combining ID and title for state management
  String get key => '$id::$title';

  /// Generate cover image URL from Open Library Covers API
  /// Uses ISBN if available (most reliable), otherwise falls back to title-based lookup
  /// Size options: S (small), M (medium), L (large)
  String? getCoverUrl({String size = 'L'}) {
    if (isbn != null && isbn!.isNotEmpty) {
      return 'https://covers.openlibrary.org/b/isbn/$isbn-$size.jpg';
    }
    // Fallback: try title-based lookup (less reliable)
    final encodedTitle = Uri.encodeComponent(title);
    return 'https://covers.openlibrary.org/b/title/$encodedTitle-$size.jpg';
  }

  /// Convert Book to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'genre': genre,
      'pages': pages,
      'rating': rating,
      'ratingCount': ratingCount,
      'isCommitteePick': isCommitteePick,
      'isRequired': isRequired,
      'isbn': isbn,
    };
  }

  /// Create Book from Firestore document data
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int,
      title: map['title'] as String,
      author: map['author'] as String,
      genre: map['genre'] as String,
      pages: map['pages'] as int,
      rating: (map['rating'] as num).toDouble(),
      ratingCount: map['ratingCount'] as int,
      isCommitteePick: map['isCommitteePick'] as bool? ?? false,
      isRequired: map['isRequired'] as bool? ?? false,
      isbn: map['isbn'] as String?,
    );
  }
}

/// User's reading shelf status for a book
enum ShelfStatus { wantToRead, reading, finished }

extension ShelfStatusText on ShelfStatus {
  String get label {
    switch (this) {
      case ShelfStatus.wantToRead:
        return 'Want to Read';
      case ShelfStatus.reading:
        return 'Reading';
      case ShelfStatus.finished:
        return 'Finished';
    }
  }
}

