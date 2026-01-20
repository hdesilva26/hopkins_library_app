import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/book.dart';
import '../../services/book_search_service.dart';

/// Admin page for adding new books to the library
/// Search-first flow:
/// - Search Open Library
/// - Tap a result to prefill a manual form
/// - Or tap "Can't find it?" to add manually
class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _searchController = TextEditingController();
  final _searchService = BookSearchService();
  List<BookSearchResult> _results = const [];
  bool _searching = false;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _searching = true;
      _searchError = null;
    });

    try {
      final res = await _searchService.search(q);
      if (!mounted) return;
      setState(() => _results = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _searchError = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  Future<void> _openManualAdd({BookSearchResult? prefill}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddBookManualPage(prefill: prefill),
      ),
    );
  }

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _genreController = TextEditingController();
  final _pagesController = TextEditingController();
  final _ratingController = TextEditingController();
  final _ratingCountController = TextEditingController();
  final _isbnController = TextEditingController();
  
  bool _isCommitteePick = false;
  bool _isRequired = false;
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = context.read<AppState>();
      final book = Book(
        id: appState.getNextBookId(),
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _genreController.text.trim(),
        pages: int.parse(_pagesController.text),
        rating: double.parse(_ratingController.text),
        ratingCount: int.parse(_ratingCountController.text),
        isCommitteePick: _isCommitteePick,
        isRequired: _isRequired,
        isbn: _isbnController.text.trim().isEmpty 
            ? null 
            : _isbnController.text.trim(),
      );

      await appState.addBook(book);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Book'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runSearch(),
            decoration: InputDecoration(
              labelText: 'Search books',
              hintText: 'Try: “The Hobbit” or “9780547928227”',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: _searching ? null : _runSearch,
                icon: _searching
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _openManualAdd(),
                icon: const Icon(Icons.edit),
                label: const Text("Can't find it? Add manually"),
              ),
            ],
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 8),
            Text(
              _searchError!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
          const SizedBox(height: 8),
          if (_results.isEmpty && !_searching)
            Text(
              'Search results will appear here.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          for (final r in _results)
            Card(
              child: ListTile(
                title: Text(r.title),
                subtitle: Text(r.subtitleParts),
                trailing: const Icon(Icons.add),
                onTap: () => _openManualAdd(prefill: r),
              ),
            ),
        ],
      ),
    );
  }
}

/// Manual form used when a book is not found (or to confirm/edit search result fields).
class AddBookManualPage extends StatefulWidget {
  final BookSearchResult? prefill;
  const AddBookManualPage({super.key, this.prefill});

  @override
  State<AddBookManualPage> createState() => _AddBookManualPageState();
}

class _AddBookManualPageState extends State<AddBookManualPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _genreController = TextEditingController();
  final _pagesController = TextEditingController();
  final _ratingController = TextEditingController(text: '0');
  final _ratingCountController = TextEditingController(text: '0');
  final _isbnController = TextEditingController();

  bool _isCommitteePick = false;
  bool _isRequired = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _titleController.text = p.title;
      _authorController.text = p.author;
      if (p.pageCount != null) _pagesController.text = p.pageCount.toString();
      if (p.isbn != null) _isbnController.text = p.isbn!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    _pagesController.dispose();
    _ratingController.dispose();
    _ratingCountController.dispose();
    _isbnController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final appState = context.read<AppState>();
      final book = Book(
        id: appState.getNextBookId(),
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _genreController.text.trim(),
        pages: int.parse(_pagesController.text),
        rating: double.parse(_ratingController.text),
        ratingCount: int.parse(_ratingCountController.text),
        isCommitteePick: _isCommitteePick,
        isRequired: _isRequired,
        isbn: _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
      );

      await appState.addBook(book);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add book: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prefill == null ? 'Add Book Manually' : 'Confirm & Add'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Please enter an author' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _genreController,
              decoration: const InputDecoration(
                labelText: 'Genre *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Please enter a genre' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pagesController,
              decoration: const InputDecoration(
                labelText: 'Pages *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final pages = int.tryParse(value);
                if (pages == null || pages <= 0) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ratingController,
                    decoration: const InputDecoration(
                      labelText: 'Rating',
                      border: OutlineInputBorder(),
                      hintText: '0.0 - 5.0',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final rating = double.tryParse(value);
                      if (rating == null || rating < 0 || rating > 5) return '0.0 - 5.0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _ratingCountController,
                    decoration: const InputDecoration(
                      labelText: 'Rating Count',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final count = int.tryParse(value);
                      if (count == null || count < 0) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isbnController,
              decoration: const InputDecoration(
                labelText: 'ISBN (Optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Committee Pick'),
              value: _isCommitteePick,
              onChanged: (value) => setState(() => _isCommitteePick = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Required Reading'),
              value: _isRequired,
              onChanged: (value) => setState(() => _isRequired = value ?? false),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add to Library'),
            ),
          ],
        ),
      ),
    );
  }
}

