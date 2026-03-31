import 'package:flutter/material.dart';
import '../models/book.dart';
import '../screens/book_detail/book_detail_page.dart';
import 'book_cover_image.dart';

class BookCard extends StatefulWidget {
  final Book book;
  final bool large;

  const BookCard({super.key, required this.book, this.large = false});

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.large ? 130.0 : 110.0;
    final coverHeight = widget.large ? 195.0 : 165.0;
    final totalHeight = coverHeight + 55;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BookDetailPage(book: widget.book)),
        );
      },
      onTapCancel: () => _controller.reverse(),
      child: SizedBox(
        height: totalHeight,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: width,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'book_cover_${widget.book.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: BookCoverImage(
                      book: widget.book,
                      width: width,
                      height: coverHeight,
                      size: widget.large ? 'L' : 'M',
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
