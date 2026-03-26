import 'package:flutter/material.dart';
import '../models/book.dart';
import '../screens/book_detail/book_detail_page.dart';
import 'book_cover_image.dart';

/// Book card widget for displaying books in horizontal lists
/// Features: Press animation, Hero animation for navigation, book metadata display
class BookCard extends StatefulWidget {
  final Book book;
  final bool large; // Use larger size for featured sections

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
    // Set up press animation for tactile feedback
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Make the large cards big enough to clearly showcase the full cover
    // while keeping small cards compact in other sections.
    final width = widget.large ? 140.0 : 120.0;
    // Use book cover aspect ratio (approximately 1.5:1 height to width)
    final coverHeight = widget.large ? 210.0 : 180.0;
    final totalHeight =
        coverHeight +
        65; // Optimized space for title and metadata to prevent overflow

    return GestureDetector(
      // Handle press animations for better user feedback
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        // Navigate to book detail page on tap
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BookDetailPage(book: widget.book)),
        );
      },
      onTapCancel: () {
        _controller.reverse();
      },
      // Give the card proper book cover proportions with flexible height
      child: SizedBox(
        height: totalHeight,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: width,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero animation for smooth cover image transition to detail page
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
                const SizedBox(height: 4),
                Text(
                  widget.book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
