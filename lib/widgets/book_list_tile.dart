import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => BookDetailPage(book: book)));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCoverImage(book: book, width: 50, height: 75, size: 'S'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          book.genre.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${book.pages} PAGES',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _ShelfMenu(book: book, status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelfMenu extends StatelessWidget {
  final Book book;
  final ShelfStatus? status;

  const _ShelfMenu({required this.book, required this.status});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ShelfStatus?>(
      initialValue: status,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      onSelected: (value) {
        HapticFeedback.lightImpact();
        context.read<AppState>().setStatus(book, value);
      },
      itemBuilder: (context) => [
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
              Text('Remove', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: status != null ? Colors.black : const Color(0xFFF5F5F5),
          border: status != null
              ? null
              : Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Icon(
          status == null ? Icons.add : Icons.check,
          size: 18,
          color: status == null ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}
