import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/book.dart';
import '../../widgets/bookshelf_view.dart';

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
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: BookshelfView(books: books, shelfLabel: _shelfLabel),
    );
  }
}
