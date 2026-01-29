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
  bool _isPressed = false;
  bool _isFavorited = false;
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
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        // Navigate to book detail page on tap
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BookDetailPage(book: widget.book)),
        );
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
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
                // Hero animation with modern rounded corners and shadow
                Hero(
                  tag: 'book_cover_${widget.book.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24.0),
                          child: BookCoverImage(
                            book: widget.book,
                            width: width,
                            height: coverHeight,
                            size: widget.large ? 'L' : 'M',
                          ),
                        ),
                        // Favorite overlay button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _isFavorited = !_isFavorited);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isFavorited
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 16,
                                color: _isFavorited
                                    ? Colors.red.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.large ? 12 : 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.large ? 10 : 9,
                    color: const Color(0xFF718096),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.amber.shade600),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.book.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        '(${widget.book.ratingCount})',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF718096),
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
      ),
    );
  }
}
