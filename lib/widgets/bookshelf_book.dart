import 'package:flutter/material.dart';
import '../models/book.dart';
import '../screens/book_detail/book_detail_page.dart';
import 'book_cover_image.dart';

/// Rectangular book widget for bookshelf display
/// Shows book cover with black border, tappable to view details
class BookshelfBook extends StatelessWidget {
  final Book book;
  final double width;
  final double height;

  const BookshelfBook({
    super.key,
    required this.book,
    this.width = 120.0,
    this.height = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => BookDetailPage(book: book)));
      },
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: ClipRect(
          child: BookCoverImage(
            book: book,
            width: width,
            height: height,
            size: 'M',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
