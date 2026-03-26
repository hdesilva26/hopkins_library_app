import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/app_state.dart';
import '../screens/book_detail/book_detail_page.dart';
import 'book_cover_image.dart';

/// List tile widget for displaying books in vertical lists
/// Shows book cover, title, author, rating, genre, shelf status, and quick shelf menu
class BookListTile extends StatelessWidget {
  final Book book;

  const BookListTile({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Get current shelf status to display badge
    final status = state.statusFor(book);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      child: ListTile(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => BookDetailPage(book: book)));
        },
        leading: BookCoverImage(book: book, width: 40, height: 60, size: 'S'),
        title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              book.genre,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            if (status != null)
              Text(
                status.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        // Quick shelf menu button in the trailing position
        trailing: _ShelfMenu(book: book),
      ),
    );
  }
}

/// Popup menu widget for quickly changing book's shelf status
/// Shows checkmark icon if book is on a shelf, plus icon if not
class _ShelfMenu extends StatelessWidget {
  final Book book;

  const _ShelfMenu({required this.book});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final status = state.statusFor(book);

    return PopupMenuButton<ShelfStatus?>(
      initialValue: status,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        HapticFeedback.lightImpact();
        context.read<AppState>().setStatus(book, value);
      },
      itemBuilder: (context) => [
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
              Text('Remove', style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
      child: Icon(
        status == null ? Icons.add : Icons.check,
        color: status == null ? null : Colors.green,
      ),
    );
  }
}
