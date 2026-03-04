import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/book.dart';
import '../../widgets/bookshelf_view.dart';
import '../../services/auth_state.dart';

/// My Books page - displays user's reading shelves
/// Three tabs: Want to Read, Reading, and Finished
class MyBooksPage extends StatelessWidget {
  const MyBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return DefaultTabController(
          length: 3,
          child: Column(
            children: const [
              // Tab bar for switching between shelf types
              TabBar(
                tabs: [
                  Tab(text: 'Want to Read'),
                  Tab(text: 'Reading'),
                  Tab(text: 'Finished'),
                ],
              ),
              // Tab views showing bookshelf for each shelf type
              Expanded(
                child: TabBarView(
                  children: [
                    _BookshelfContainer(type: ShelfStatus.wantToRead),
                    _BookshelfContainer(type: ShelfStatus.reading),
                    _BookshelfContainer(type: ShelfStatus.finished),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyShelfState extends StatelessWidget {
  final ShelfStatus type;

  const _EmptyShelfState({required this.type});

  String get _message {
    switch (type) {
      case ShelfStatus.wantToRead:
        return 'Start building your reading list';
      case ShelfStatus.reading:
        return 'No books in progress';
      case ShelfStatus.finished:
        return 'Your completed books will appear here';
    }
  }

  String get _subtitle {
    switch (type) {
      case ShelfStatus.wantToRead:
        return 'Explore books and add them to your list';
      case ShelfStatus.reading:
        return 'Mark a book as "Reading" to track your progress';
      case ShelfStatus.finished:
        return 'Mark books as "Finished" when you complete them';
    }
  }

  IconData get _icon {
    switch (type) {
      case ShelfStatus.wantToRead:
        return Icons.bookmark_border;
      case ShelfStatus.reading:
        return Icons.menu_book_outlined;
      case ShelfStatus.finished:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Container widget for displaying a specific shelf's books as a bookshelf
/// Shows bookshelf view with horizontal scrolling book covers
class _BookshelfContainer extends StatelessWidget {
  final ShelfStatus type;

  const _BookshelfContainer({required this.type});

  String get _shelfLabel {
    switch (type) {
      case ShelfStatus.wantToRead:
        return 'Want to Read';
      case ShelfStatus.reading:
        return 'Currently Reading';
      case ShelfStatus.finished:
        return 'Finished';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Get books for the specific shelf type
    List<Book> books;
    switch (type) {
      case ShelfStatus.wantToRead:
        books = state.wantToReadBooks;
        break;
      case ShelfStatus.reading:
        books = state.readingBooks;
        break;
      case ShelfStatus.finished:
        books = state.finishedBooks;
        break;
    }

    // Show bookshelf view without extra vertical scrolling wrapper to avoid
    // scrolling conflicts on some devices.
    return RefreshIndicator(
      onRefresh: () async {
        try {
          final auth = context.read<AuthState>();
          if (auth.user != null) {
            await state.refreshUserShelf(auth.user!.uid);
          }
        } catch (e) {
          // Show error if refresh fails
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to refresh shelf: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: BookshelfView(books: books, shelfLabel: _shelfLabel),
    );
  }
}
