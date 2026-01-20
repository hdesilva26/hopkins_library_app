import 'package:flutter/material.dart';
import '../models/book.dart';
import 'bookshelf_book.dart';

/// Bookshelf widget displaying books in a horizontal scrolling row
/// Mimics a physical bookshelf with books arranged side by side
class BookshelfView extends StatelessWidget {
  final List<Book> books;
  final String shelfLabel;

  const BookshelfView({
    super.key,
    required this.books,
    required this.shelfLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No books on this shelf',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Add books to see them here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shelf label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            shelfLabel,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        // Horizontal scrolling bookshelf
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return BookshelfBook(
                book: books[index],
                width: 120,
                height: 180,
              );
            },
          ),
        ),
        // Bookshelf base (visual element)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 8,
          decoration: BoxDecoration(
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

