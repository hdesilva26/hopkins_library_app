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
              title: const Text('Required Books'),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Required by Class',
                                style: Theme.of(context).textTheme.titleMedium
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
                            'Browse required books for your classes',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search classes...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No classes match your search'
                                : 'No classes available',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
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
                          if (_selectedClass?.id == classModel.id) {
                            _selectedClass = null;
                          } else {
                            _selectedClass = classModel;
                          }
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
        title: const Text('Create Class'),
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
            child: const Text('Cancel'),
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
            child: const Text('Create'),
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

    Book? selectedBook;

    return showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Book to ${classModel.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: availableBooks.isEmpty
                ? const Text('All books already added to this class')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableBooks.length,
                    itemBuilder: (context, index) {
                      final book = availableBooks[index];
                      final isSelected = selectedBook?.id == book.id;
                      return ListTile(
                        leading: isSelected
                            ? const Icon(Icons.check_circle)
                            : const Icon(Icons.book),
                        title: Text(book.title),
                        subtitle: Text(book.author),
                        selected: isSelected,
                        onTap: () {
                          setDialogState(() => selectedBook = book);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
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
              child: const Text('Add'),
            ),
          ],
        ),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.class_,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              classModel.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: classModel.subject != null
                ? Text(classModel.subject!)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${classModel.requiredBooks.length} books',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: onTap,
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            if (classModel.requiredBooks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No required books for this class'),
              )
            else
              ...classModel.requiredBooks.map(
                (book) => BookListTile(book: book),
              ),
            if (isAdmin) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton.icon(
                  onPressed: onAddBook,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Book to Class'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
