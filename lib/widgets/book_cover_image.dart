import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';

/// Book cover image widget with loading and error states
/// Uses cached network images for performance and shows placeholder if image unavailable
class BookCoverImage extends StatelessWidget {
  final Book book;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String size;  // Image size: 'S' (small), 'M' (medium), or 'L' (large)

  const BookCoverImage({
    super.key,
    required this.book,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.size = 'L', // S, M, or L
  });

  @override
  Widget build(BuildContext context) {
    // Get cover image URL from Open Library API
    final coverUrl = book.getCoverUrl(size: size);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.black, width: 1),
      ),
      // Show cached network image if URL is available, otherwise show placeholder
      child: coverUrl != null
          ? CachedNetworkImage(
                imageUrl: coverUrl,
                width: width,
                height: height,
                fit: fit,
                // Show loading indicator while image loads
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    color: Colors.grey.shade200,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                  ),
                ),
                // Show placeholder if image fails to load
                errorWidget: (context, url, error) => _buildPlaceholder(),
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 100),
              )
          : _buildPlaceholder(),
    );
  }

  /// Build placeholder widget showing first letter of book title
  /// Used when cover image is unavailable or fails to load
  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Center(
        child: Text(
          book.title.isNotEmpty ? book.title[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

