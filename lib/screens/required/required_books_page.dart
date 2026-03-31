import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/class_model.dart';
import '../../models/book.dart';
import '../../services/class_service.dart';
import '../../services/auth_state.dart';
import '../../services/book_service.dart';
import '../../widgets/book_list_tile.dart';

class RequiredBooksPage extends StatefulWidget {
  const RequiredBooksPage({super.key});

  @override
  State<RequiredBooksPage> createState() => _RequiredBooksPageState();
}

class _RequiredBooksPageState extends State<RequiredBooksPage> {
  final ClassService _classService = ClassService();
  final BookService _bookService = BookService();
  String _searchQuery = '';
  ClassModel? _selectedClass;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text(
                'REQUIRED BOOKS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              floating: true,
              snap: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.black),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'REQUIRED BY CLASS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Browse required books for your classes',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search classes...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search, size: 20),
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
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<ClassModel>>(
              stream: _classService.getClasses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }

                final classes = snapshot.data ?? [];
                final filteredClasses = _searchQuery.isEmpty
                    ? classes
                    : classes
                          .where(
                            (c) =>
                                c.name.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ||
                                (c.subject?.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ??
                                    false),
                          )
                          .toList();

                if (filteredClasses.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.class_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No classes match your search'
                                : 'No classes available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final classModel = filteredClasses[index];
                    return _ClassCard(
                      classModel: classModel,
                      isExpanded: _selectedClass?.id == classModel.id,
                      isAdmin: auth.isAdmin,
                      onTap: () {
                        setState(() {
                          _selectedClass = _selectedClass?.id == classModel.id
                              ? null
                              : classModel;
                        });
                      },
                      onAddBook: () => _showAddBookDialog(context, classModel),
                    );
                  }, childCount: filteredClasses.length),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: context.watch<AuthState>().isAdmin
          ? FloatingActionButton(
              onPressed: () => _showCreateClassDialog(context),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _showCreateClassDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'CREATE CLASS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Class Name',
                hintText: 'e.g., AP English Literature',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject (optional)',
                hintText: 'e.g., English',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await _classService.createClass(
                  name,
                  subject: subjectController.text.trim().isEmpty
                      ? null
                      : subjectController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddBookDialog(
    BuildContext context,
    ClassModel classModel,
  ) async {
    final books = await _bookService.getAllBooksOnce();
    if (!context.mounted) return;
    if (books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No books available in library')),
      );
      return;
    }

    final existingBookIds = classModel.requiredBooks.map((b) => b.id).toSet();
    final availableBooks = books
        .where((b) => !existingBookIds.contains(b.id))
        .toList();

    if (availableBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All books already added to this class')),
      );
      return;
    }

    final searchController = TextEditingController();
    Book? selectedBook;

    return showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final query = searchController.text.toLowerCase();
          final filteredBooks = query.isEmpty
              ? availableBooks
              : availableBooks
                    .where(
                      (b) =>
                          b.title.toLowerCase().contains(query) ||
                          b.author.toLowerCase().contains(query),
                    )
                    .toList();

          return AlertDialog(
            title: Text(
              'ADD BOOK TO ${classModel.name.toUpperCase()}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search books...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredBooks.isEmpty
                        ? const Center(child: Text('No books found'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = filteredBooks[index];
                              final isSelected = selectedBook?.id == book.id;
                              return ListTile(
                                leading: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.black,
                                      )
                                    : const Icon(Icons.book),
                                title: Text(
                                  book.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(book.author),
                                selected: isSelected,
                                onTap: () =>
                                    setDialogState(() => selectedBook = book),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: selectedBook == null
                    ? null
                    : () async {
                        await _classService.addRequiredBook(
                          classModel.id,
                          selectedBook!,
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      },
                child: const Text('ADD'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassModel classModel;
  final bool isExpanded;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onAddBook;

  const _ClassCard({
    required this.classModel,
    required this.isExpanded,
    required this.isAdmin,
    required this.onTap,
    required this.onAddBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(
                      Icons.class_,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classModel.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (classModel.subject != null)
                          Text(
                            classModel.subject!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(color: Colors.black),
                    child: Text(
                      '${classModel.requiredBooks.length} BOOKS',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(height: 1, color: const Color(0xFFE0E0E0)),
            if (classModel.requiredBooks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No required books for this class',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ...classModel.requiredBooks.map(
                (book) => BookListTile(book: book),
              ),
            if (isAdmin) ...[
              Container(height: 1, color: const Color(0xFFE0E0E0)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onAddBook,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('ADD BOOK TO CLASS'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
