import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCoverImage(
                book: book,
                width: 90,
                height: 130,
                size: 'L',
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${book.rating.toStringAsFixed(1)} (${book.ratingCount})',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    Text(
                      '${book.genre} • ${book.pages} pages',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final newStatus =
                            await showMenu<ShelfStatus?>(
                          context: context,
                          position:
                              const RelativeRect.fromLTRB(0, 0, 0, 0),
                          items: const [
                            PopupMenuItem(
                              value: ShelfStatus.wantToRead,
                              child: Text('Want to Read'),
                            ),
                            PopupMenuItem(
                              value: ShelfStatus.reading,
                              child: Text('Reading'),
                            ),
                            PopupMenuItem(
                              value: ShelfStatus.finished,
                              child: Text('Finished'),
                            ),
                            PopupMenuDivider(),
                            PopupMenuItem(
                              value: null,
                              child: Text('Remove from shelf'),
                            ),
                          ],
                        );

                        if (newStatus != null ||
                            (newStatus == null && status != null)) {
                          context
                              .read<AppState>()
                              .setStatus(book, newStatus);
                        }
                      },
                      icon: Icon(
                        status == null ? Icons.add : Icons.check,
                      ),
                      label: Text(status?.label ?? 'Add to shelf'),
                    ),
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
          const Text(
            'Summary coming soon.',
            style: TextStyle(fontSize: 14),
          ),
          if (book.isCommitteePick || book.isRequired)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (book.isCommitteePick)
                    const Chip(
                      label: Text('Committee Pick'),
                      avatar: Icon(Icons.star, size: 16),
                    ),
                  if (book.isRequired)
                    const Chip(
                      label: Text('Required Reading'),
                      avatar: Icon(Icons.assignment, size: 16),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

