import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/book.dart';
import '../../widgets/book_list_tile.dart';

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
              TabBar(
                tabs: [
                  Tab(text: 'Want to Read'),
                  Tab(text: 'Reading'),
                  Tab(text: 'Finished'),
                ],
              ),
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

class _ShelfListContainer extends StatelessWidget {
  final ShelfStatus type;

  const _ShelfListContainer({required this.type});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

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

    if (books.isEmpty) {
      return const Center(child: Text('No books here yet.'));
    }

    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) => BookListTile(book: books[index]),
    );
  }
}

