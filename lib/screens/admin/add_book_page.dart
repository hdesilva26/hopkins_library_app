import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/book.dart';
import '../../services/book_search_service.dart';

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
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _openManualAdd({BookSearchResult? prefill}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddBookManualPage(prefill: prefill)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ADD BOOK',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 48,
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _runSearch(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Try: "The Hobbit" or "9780547928227"',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  onPressed: _searching ? null : _runSearch,
                  icon: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward, size: 20),
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _openManualAdd(),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text("CAN'T FIND IT? ADD MANUALLY"),
            ),
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.red)),
              child: Text(
                _searchError!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_results.isEmpty && !_searching)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Search results will appear here.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          for (final r in _results)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: ListTile(
                title: Text(
                  r.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  r.subtitleParts,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: Colors.black),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
                onTap: () => _openManualAdd(prefill: r),
              ),
            ),
        ],
      ),
    );
  }
}

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
  final _isbnController = TextEditingController();

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
        isRequired: false,
        isbn: _isbnController.text.trim().isEmpty
            ? null
            : _isbnController.text.trim(),
      );

      await appState.addBook(book);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book added successfully!'),
          backgroundColor: Colors.black,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.prefill == null ? 'ADD MANUALLY' : 'CONFIRM & ADD',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter a title'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(labelText: 'Author *'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter an author'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _genreController,
              decoration: const InputDecoration(labelText: 'Genre *'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter a genre'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pagesController,
              decoration: const InputDecoration(labelText: 'Pages *'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final pages = int.tryParse(value);
                if (pages == null || pages <= 0) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isbnController,
              decoration: const InputDecoration(labelText: 'ISBN (Optional)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('ADD TO LIBRARY'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
