import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../models/app_state.dart';
import '../../widgets/book_cover_image.dart';

/// Book detail page showing full information about a book
/// Includes cover image, metadata, and shelf management button
class BookDetailPage extends StatelessWidget {
  final Book book;

  const BookDetailPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Get current shelf status for this book
    final status = state.statusFor(book);

    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'book_cover_${book.id}',
                child: BookCoverImage(
                  book: book,
                  width: 90,
                  height: 130,
                  size: 'L',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.black87),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${book.rating.toStringAsFixed(1)} (${book.ratingCount})',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${book.genre} • ${book.pages} pages',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Button to add/change book's shelf status
                    _ShelfButton(book: book, currentStatus: status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'About this book',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Summary coming soon.', style: TextStyle(fontSize: 14)),
          if (book.isCommitteePick || book.isRequired)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (book.isCommitteePick)
                    Chip(
                      label: const Text('Committee Pick'),
                      avatar: const Icon(
                        Icons.star,
                        size: 18,
                        color: Colors.black,
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.black, width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  if (book.isRequired)
                    Chip(
                      label: const Text('Required Reading'),
                      avatar: const Icon(
                        Icons.assignment,
                        size: 18,
                        color: Colors.black,
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.black, width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Button widget for managing book's shelf status
/// Shows popup menu to add book to Want to Read, Reading, Finished, or remove from shelf
class _ShelfButton extends StatelessWidget {
  final Book book;
  final ShelfStatus? currentStatus;

  const _ShelfButton({required this.book, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        // Provide haptic feedback for better UX
        HapticFeedback.lightImpact();
        // Show popup menu with shelf options
        final newStatus = await showMenu<ShelfStatus?>(
          context: context,
          position: const RelativeRect.fromLTRB(0, 0, 0, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          items: [
            PopupMenuItem(
              value: ShelfStatus.wantToRead,
              child: Row(
                children: const [
                  Icon(Icons.bookmark_border, size: 20),
                  SizedBox(width: 12),
                  Text('Want to Read'),
                ],
              ),
            ),
            PopupMenuItem(
              value: ShelfStatus.reading,
              child: Row(
                children: const [
                  Icon(Icons.menu_book, size: 20),
                  SizedBox(width: 12),
                  Text('Reading'),
                ],
              ),
            ),
            PopupMenuItem(
              value: ShelfStatus.finished,
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline, size: 20),
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
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Remove from shelf',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        );

        // Update book status if user made a selection
        if (!context.mounted) return;
        if (newStatus != null || (newStatus == null && currentStatus != null)) {
          HapticFeedback.mediumImpact();
          // Update state and notify listeners to rebuild UI
          context.read<AppState>().setStatus(book, newStatus);
        }
      },
      icon: Icon(
        currentStatus == null
            ? Icons.add
            : currentStatus == ShelfStatus.wantToRead
            ? Icons.bookmark
            : currentStatus == ShelfStatus.reading
            ? Icons.menu_book
            : Icons.check_circle,
      ),
      label: Text(currentStatus?.label ?? 'Add to shelf'),
      style: ElevatedButton.styleFrom(
        backgroundColor: currentStatus != null
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        foregroundColor: currentStatus != null
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : null,
      ),
    );
  }
}
