import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/book.dart';
import '../../widgets/book_card.dart';
import '../../widgets/book_list_tile.dart';
import '../../widgets/common_widgets.dart';
import '../../services/auth_state.dart';

/// Explore page for discovering books
/// Features: Search, genre filtering, trending books, top rated, and personalized recommendations
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _searchQuery = '';
  String? _selectedGenre;
  List<Book> _recommendations = [];
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final auth = context.read<AuthState>();
    final state = context.read<AppState>();

    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      if (auth.user != null) {
        final recs = await state.recommendations(userId: auth.user!.uid);
        if (mounted) {
          setState(() {
            _recommendations = recs;
            _isLoadingRecommendations = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _recommendations = state.recommendationsSync();
            _isLoadingRecommendations = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recommendations = state.trendingBooks; // Fallback
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        // Start with all books, then apply filters
        List<Book> visibleBooks = state.allBooks;

        // Filter by selected genre
        if (_selectedGenre != null && _selectedGenre!.isNotEmpty) {
          visibleBooks = visibleBooks
              .where((b) => b.genre == _selectedGenre)
              .toList();
        }

        // Filter by search query (searches title and author)
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          visibleBooks = visibleBooks.where((b) {
            return b.title.toLowerCase().contains(q) ||
                b.author.toLowerCase().contains(q);
          }).toList();
        }

        // Get curated book lists for display
        final trending = state.trendingBooks;
        final topRated = state.topRatedBooks;
        final recs = _isLoadingRecommendations ? <Book>[] : _recommendations;

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              try {
                await state.refreshBooks();
              } catch (e) {
                // Show error if refresh fails
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to refresh: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personalized header with user greeting
                        Consumer<AuthState>(
                          builder: (context, auth, _) {
                            final userName = auth.user?.displayName ?? 'Reader';
                            final firstName = userName.split(' ').first;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: const Color(0xFF2D3748),
                                      child: Text(
                                        firstName.isNotEmpty
                                            ? firstName[0].toUpperCase()
                                            : 'R',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hello, $firstName!',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2D3748),
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Find your next great read',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),
                        BookSearchBar(
                          hintText: 'Search by title or author',
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                        const SizedBox(height: 20),
                        GenreChips(
                          genres: state.genres,
                          selected: _selectedGenre,
                          onSelected: (genre) {
                            setState(
                              () => _selectedGenre = genre == _selectedGenre
                                  ? null
                                  : genre,
                            );
                          },
                        ),
                        const SizedBox(height: 24),
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

                // Show curated sections when not searching
                if (_searchQuery.isEmpty) ...[
                  // Trending books section - horizontal scrolling cards
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Trending at Hopkins',
                      subtitle: 'Popular right now',
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 295, // Increased height for larger cards
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: trending.length,
                        itemBuilder: (context, index) {
                          return BookCard(book: trending[index], large: true);
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Top rated books section
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Top Rated',
                      subtitle: 'Highly rated books',
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 265, // Increased height
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: topRated.length,
                        itemBuilder: (context, index) {
                          return BookCard(book: topRated[index]);
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Personalized recommendations based on reading history
                  if (recs.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Because You Finished…',
                        subtitle: 'Recommendations just for you',
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 265, // Increased height
                        child: _isLoadingRecommendations
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: recs.length,
                                itemBuilder: (context, index) {
                                  return BookCard(book: recs[index]);
                                },
                              ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],

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
