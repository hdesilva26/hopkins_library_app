import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/book.dart';
import '../../widgets/book_list_tile.dart';

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
              // Tab views showing books for each shelf
              Expanded(
                child: TabBarView(
                  children: [
                    _ShelfListContainer(type: ShelfStatus.wantToRead),
                    _ShelfListContainer(type: ShelfStatus.reading),
                    _ShelfListContainer(type: ShelfStatus.finished),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icon,
              size: 64,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Container widget for displaying a specific shelf's books
/// Shows empty state if shelf is empty, otherwise displays book list
class _ShelfListContainer extends StatelessWidget {
  final ShelfStatus type;

  const _ShelfListContainer({required this.type});

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

    // Show empty state message if shelf is empty
    if (books.isEmpty) {
      return _EmptyShelfState(type: type);
    }

    // Display scrollable list of books with pull-to-refresh
    return RefreshIndicator(
      onRefresh: () async {
        // Simulate refresh delay for better UX
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: books.length,
        itemBuilder: (context, index) => BookListTile(book: books[index]),
      ),
    );
  }
}

