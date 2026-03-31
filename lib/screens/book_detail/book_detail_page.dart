import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../models/app_state.dart';
import '../../widgets/book_cover_image.dart';

class BookDetailPage extends StatelessWidget {
  final Book book;

  const BookDetailPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final status = state.statusFor(book);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'BOOK DETAILS',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'book_cover_${book.id}',
                child: BookCoverImage(
                  book: book,
                  width: 100,
                  height: 150,
                  size: 'L',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoTag(label: book.genre.toUpperCase()),
                        _InfoTag(label: '${book.pages} PAGES'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ShelfButton(book: book, currentStatus: status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ABOUT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Summary coming soon.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (book.isRequired) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black),
              child: Row(
                children: [
                  const Icon(Icons.assignment, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'REQUIRED READING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Center(
            child: Text(
              '* All book info acquired from Open Library',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String label;

  const _InfoTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _ShelfButton extends StatelessWidget {
  final Book book;
  final ShelfStatus? currentStatus;

  const _ShelfButton({required this.book, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: () async {
          HapticFeedback.lightImpact();
          final newStatus = await showMenu<ShelfStatus?>(
            context: context,
            position: const RelativeRect.fromLTRB(0, 0, 0, 0),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            items: [
              PopupMenuItem(
                value: ShelfStatus.wantToRead,
                child: Row(
                  children: const [
                    Icon(Icons.bookmark_border, size: 18),
                    SizedBox(width: 12),
                    Text('Want to Read'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ShelfStatus.reading,
                child: Row(
                  children: const [
                    Icon(Icons.menu_book, size: 18),
                    SizedBox(width: 12),
                    Text('Reading'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ShelfStatus.finished,
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_outline, size: 18),
                    SizedBox(width: 12),
                    Text('Finished'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      Icons.remove_circle_outline,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Remove from shelf',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (!context.mounted) return;
          if (newStatus != null ||
              (newStatus == null && currentStatus != null)) {
            HapticFeedback.mediumImpact();
            context.read<AppState>().setStatus(book, newStatus);
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              currentStatus == null
                  ? Icons.add
                  : currentStatus == ShelfStatus.wantToRead
                  ? Icons.bookmark
                  : currentStatus == ShelfStatus.reading
                  ? Icons.menu_book
                  : Icons.check_circle,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(currentStatus?.label.toUpperCase() ?? 'ADD TO SHELF'),
          ],
        ),
      ),
    );
  }
}
