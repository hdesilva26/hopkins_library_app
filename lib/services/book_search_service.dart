import 'dart:convert';
import 'package:http/http.dart' as http;

/// Minimal search result from Open Library.
class BookSearchResult {
  final String title;
  final String author;
  final int? firstPublishYear;
  final int? pageCount;
  final String? isbn;

  const BookSearchResult({
    required this.title,
    required this.author,
    this.firstPublishYear,
    this.pageCount,
    this.isbn,
  });

  String get subtitleParts {
    final parts = <String>[];
    if (author.isNotEmpty) parts.add(author);
    if (firstPublishYear != null) parts.add(firstPublishYear.toString());
    if (pageCount != null) parts.add('${pageCount} pages');
    if (isbn != null && isbn!.isNotEmpty) parts.add('ISBN ${isbn!}');
    return parts.join(' • ');
  }
}

/// Simple Open Library search client.
/// Uses the public Search API (no key required).
class BookSearchService {
  static const String _base = 'https://openlibrary.org';

  Future<List<BookSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final uri = Uri.parse('$_base/search.json').replace(queryParameters: {
      'q': q,
      'limit': '20',
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Search failed (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final docs = (decoded['docs'] as List<dynamic>? ?? const []);

    BookSearchResult? mapDoc(dynamic raw) {
      final doc = raw as Map<String, dynamic>;
      final title = (doc['title'] as String?)?.trim() ?? '';
      if (title.isEmpty) return null;

      final authors = (doc['author_name'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [];
      final author = authors.isNotEmpty ? authors.first : 'Unknown author';

      final year = (doc['first_publish_year'] as int?);
      final pages = (doc['number_of_pages_median'] as int?);
      final isbns = (doc['isbn'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [];
      final isbn = isbns.isNotEmpty ? isbns.first : null;

      return BookSearchResult(
        title: title,
        author: author,
        firstPublishYear: year,
        pageCount: pages,
        isbn: isbn,
      );
    }

    final results = <BookSearchResult>[];
    for (final d in docs) {
      final mapped = mapDoc(d);
      if (mapped != null) results.add(mapped);
    }
    return results;
  }
}


