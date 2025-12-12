import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/book.dart';
import '../../widgets/book_card.dart';
import '../../widgets/book_list_tile.dart';
import '../../widgets/common_widgets.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _searchQuery = '';
  String? _selectedGenre;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        List<Book> visibleBooks = state.allBooks;

        if (_selectedGenre != null && _selectedGenre!.isNotEmpty) {
          visibleBooks =
              visibleBooks.where((b) => b.genre == _selectedGenre).toList();
        }

        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          visibleBooks = visibleBooks.where((b) {
            return b.title.toLowerCase().contains(q) ||
                b.author.toLowerCase().contains(q);
          }).toList();
        }

        final trending = state.trendingBooks;
        final topRated = state.topRatedBooks;
        final recs = state.recommendations();

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              // Simulate refresh delay
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookSearchBar(
                        hintText: 'Search by title or author',
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 12),
                      GenreChips(
                        genres: state.genres,
                        selected: _selectedGenre,
                        onSelected: (genre) {
                          setState(() =>
                              _selectedGenre = genre == _selectedGenre ? null : genre);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              if (_searchQuery.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Search Results',
                    subtitle:
                        '${visibleBooks.length} book${visibleBooks.length == 1 ? '' : 's'} found',
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        BookListTile(book: visibleBooks[index]),
                    childCount: visibleBooks.length,
                  ),
                ),
              ],

              if (_searchQuery.isEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Trending at Hopkins',
                    subtitle: 'Popular right now',
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 230,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: trending.length,
                      itemBuilder: (context, index) {
                        return BookCard(book: trending[index], large: true);
                      },
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Top Rated',
                    subtitle: 'Highly rated books',
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 210,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: topRated.length,
                      itemBuilder: (context, index) {
                        return BookCard(book: topRated[index]);
                      },
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Because You Finished…',
                    subtitle: 'Recommendations just for you',
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 210,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: recs.length,
                      itemBuilder: (context, index) {
                        return BookCard(book: recs[index]);
                      },
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: _selectedGenre == null
                        ? 'Browse All'
                        : 'Browse: $_selectedGenre',
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        BookListTile(book: visibleBooks[index]),
                    childCount: visibleBooks.length,
                  ),
                ),
              ],
            ],
            ),
          ),
        );
      },
    );
  }
}

