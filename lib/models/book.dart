class Book {
  final int id;
  final String title;
  final String author;
  final String genre;
  final int pages;
  final double rating;
  final int ratingCount;
  final bool isCommitteePick;
  final bool isRequired;
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

  String get key => '$id::$title';

  /// Generate cover image URL from Open Library Covers API
  /// Size options: S (small), M (medium), L (large)
  String? getCoverUrl({String size = 'L'}) {
    if (isbn != null && isbn!.isNotEmpty) {
      return 'https://covers.openlibrary.org/b/isbn/$isbn-$size.jpg';
    }
    // Fallback: try title-based lookup (less reliable)
    final encodedTitle = Uri.encodeComponent(title);
    return 'https://covers.openlibrary.org/b/title/$encodedTitle-$size.jpg';
  }
}

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

