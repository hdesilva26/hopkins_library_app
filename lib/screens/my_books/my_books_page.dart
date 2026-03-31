import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/book.dart';
import '../../widgets/bookshelf_view.dart';

class MyBooksPage extends StatelessWidget {
  const MyBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: const TabBar(
                  tabs: [
                    Tab(text: 'WANT TO READ'),
                    Tab(text: 'READING'),
                    Tab(text: 'FINISHED'),
                  ],
                ),
              ),
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

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: BookshelfView(books: books, shelfLabel: _shelfLabel),
    );
  }
}
