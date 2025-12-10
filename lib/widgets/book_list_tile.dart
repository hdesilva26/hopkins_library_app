import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/app_state.dart';
import '../screens/book_detail/book_detail_page.dart';
import 'book_cover_image.dart';

class BookListTile extends StatelessWidget {
  final Book book;

  const BookListTile({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final status = state.statusFor(book);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookDetailPage(book: book),
            ),
          );
        },
        leading: BookCoverImage(
          book: book,
          width: 40,
          height: 60,
          size: 'S',
        ),
        title: Text(book.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  '${book.rating.toStringAsFixed(1)} • ${book.genre}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (status != null)
              Text(
                status.label,
                style: const TextStyle(
                    fontSize: 11, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: _ShelfMenu(book: book),
      ),
    );
  }
}

class _ShelfMenu extends StatelessWidget {
  final Book book;

  const _ShelfMenu({required this.book});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final status = state.statusFor(book);

    return PopupMenuButton<ShelfStatus?>(
      initialValue: status,
      onSelected: (value) {
        context.read<AppState>().setStatus(book, value);
      },
      itemBuilder: (context) => const [
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
          child: Text('Remove'),
        ),
      ],
      child: Icon(
        status == null ? Icons.add : Icons.check,
        color: status == null ? null : Colors.green,
      ),
    );
  }
}

