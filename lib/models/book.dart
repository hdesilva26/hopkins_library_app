/// Book data model representing a book in the library
/// Contains metadata like title, author, genre, and special flags
class Book {
  final int id;
  final String title;
  final String author;
  final String genre;
  final int pages;
  final bool isRequired;
  final String? isbn;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.pages,
    this.isRequired = false,
    this.isbn,
  });

  String get key => '$id::$title';

  String? getCoverUrl({String size = 'L'}) {
    if (isbn != null && isbn!.isNotEmpty) {
      return 'https://covers.openlibrary.org/b/isbn/$isbn-$size.jpg';
    }
    final encodedTitle = Uri.encodeComponent(title);
    return 'https://covers.openlibrary.org/b/title/$encodedTitle-$size.jpg';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'genre': genre,
      'pages': pages,
      'isRequired': isRequired,
      'isbn': isbn,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int,
      title: map['title'] as String,
      author: map['author'] as String,
      genre: map['genre'] as String,
      pages: map['pages'] as int,
      isRequired: map['isRequired'] as bool? ?? false,
      isbn: map['isbn'] as String?,
    );
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
