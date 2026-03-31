import 'package:flutter/material.dart';
import '../models/book.dart';
import '../screens/book_detail/book_detail_page.dart';
import 'book_cover_image.dart';

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
      child: SizedBox(
        width: width,
        height: height,
        child: BookCoverImage(
          book: book,
          width: width,
          height: height,
          size: 'M',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
