import 'package:flutter/material.dart';
import '../models/book.dart';
import '../screens/book_detail/book_detail_page.dart';
import 'book_cover_image.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final bool large;

  const BookCard({
    super.key,
    required this.book,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = large ? 140.0 : 120.0;

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookDetailPage(book: book),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCoverImage(
              book: book,
              width: width,
              height: large ? 160 : 140,
              size: large ? 'L' : 'M',
            ),
            const SizedBox(height: 6),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(book.rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '(${book.ratingCount})',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

