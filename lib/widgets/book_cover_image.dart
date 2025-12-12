import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';

class BookCoverImage extends StatelessWidget {
  final Book book;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String size;

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
    final coverUrl = book.getCoverUrl(size: size);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade300,
            Colors.indigo.shade400,
          ],
        ),
      ),
      child: coverUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: coverUrl,
                width: width,
                height: height,
                fit: fit,
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade200,
                        Colors.indigo.shade300,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholder(),
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 100),
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade300,
            Colors.indigo.shade400,
          ],
        ),
      ),
      child: Center(
        child: Text(
          book.title.isNotEmpty ? book.title[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

