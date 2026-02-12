import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/book.dart';
import '../../widgets/book_card.dart';
import '../../widgets/book_list_tile.dart';
import '../../widgets/common_widgets.dart';
import '../../services/required_books.dart';

/// Required Books page for viewing mandatory reading materials
/// Shows all books marked as required reading with search and filtering capabilities
class RequiredBooksPage extends StatefulWidget {
  const RequiredBooksPage({super.key});

  @override
  State<RequiredBooksPage> createState() => _RequiredBooksPageState();
}

class _RequiredBooksPageState extends State<RequiredBooksPage> {
  final RequiredBooksService _requiredBooksService = RequiredBooksService();
  String _searchQuery = '';
  String? _selectedGenre;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        // Start with all books, then filter for required books and other criteria
        List<Book> visibleBooks = state.allBooks
            .where((book) => book.isRequired)
            .toList();

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

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text('Required Reading'),
                  floating: true,
                  snap: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  elevation: 0,
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Required books info card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.assignment_turned_in,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Required Reading',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Books that must be read for your courses',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.8),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${visibleBooks.length} book${visibleBooks.length == 1 ? '' : 's'} available',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        BookSearchBar(
                          hintText: 'Search required books...',
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),

                        const SizedBox(height: 12),

                        GenreChips(
                          genres: state.genres,
                          selected: _selectedGenre,
                          onSelected: (genre) {
                            setState(() {
                              _selectedGenre = (genre == _selectedGenre)
                                  ? null
                                  : genre;
                            });
                          },
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Empty state when no required books found
                if (visibleBooks.isEmpty) ...[
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No required books match your search'
                                : 'No required books available',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                              child: const Text('Clear search'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                // Required books list
                if (visibleBooks.isNotEmpty) ...[
                  if (_searchQuery.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Search Results',
                        subtitle:
                            '${visibleBooks.length} required book${visibleBooks.length == 1 ? '' : 's'} found',
                      ),
                    ),
                  ] else if (_selectedGenre != null &&
                      _selectedGenre!.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Required: $_selectedGenre',
                        subtitle:
                            '${visibleBooks.length} book${visibleBooks.length == 1 ? '' : 's'}',
                      ),
                    ),
                  ] else ...[
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'All Required Books',
                        subtitle: 'Complete reading list for this term',
                      ),
                    ),
                  ],

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
