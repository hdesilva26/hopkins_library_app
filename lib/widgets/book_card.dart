import 'package:flutter/material.dart';
import '../models/book.dart';
import '../screens/book_detail/book_detail_page.dart';
import 'book_cover_image.dart';

/// Book card widget for displaying books in horizontal lists
/// Features: Press animation, Hero animation for navigation, book metadata display
class BookCard extends StatefulWidget {
  final Book book;
  final bool large;  // Use larger size for featured sections

  const BookCard({
    super.key,
    required this.book,
    this.large = false,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.large ? 140.0 : 120.0;

    return GestureDetector(
      // Handle press animations for better user feedback
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        // Navigate to book detail page on tap
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailPage(book: widget.book),
          ),
        );
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero animation for smooth cover image transition to detail page
              Hero(
                tag: 'book_cover_${widget.book.id}',
                child: Material(
                  color: Colors.transparent,
                  child: BookCoverImage(
                    book: widget.book,
                    width: width,
                    height: widget.large ? 160 : 140,
                    size: widget.large ? 'L' : 'M',
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: width,
                child: Text(
                  widget.book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: width,
                child: Text(
                  widget.book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 14, color: Colors.grey.shade700),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      widget.book.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '(${widget.book.ratingCount})',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

