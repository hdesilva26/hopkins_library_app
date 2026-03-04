import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/book.dart';
import '../../widgets/book_card.dart';
import '../../widgets/book_list_tile.dart';
import '../../widgets/common_widgets.dart';
import '../admin/add_book_page.dart';
import '../required/required_books_page.dart';
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

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
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
              controller: _scrollController,
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
                            final nextGenre = (genre == _selectedGenre)
                                ? null
                                : genre;

                            setState(() {
                              _selectedGenre = nextGenre;
                            });

                            // Only auto-scroll when selecting a genre (not when clearing)
                            if (nextGenre != null && nextGenre.isNotEmpty) {
                              _scrollToBottom();
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Required Books Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.assignment_turned_in,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Required Reading',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                    Text(
                                      '${state.allBooks.where((b) => b.isRequired).length} books required',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RequiredBooksPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: const Text('View All'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Search mode: show results list (no curated sections)
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

                // Not searching: show curated sections + browse all/browse by genre at the bottom
                if (_searchQuery.isEmpty) ...[
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

                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Because You Finished…',
                      subtitle: 'Recommendations just for you',
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
                      subtitle: _selectedGenre == null
                          ? null
                          : 'Showing ${visibleBooks.length} book${visibleBooks.length == 1 ? '' : 's'}',
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
