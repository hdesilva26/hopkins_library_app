import 'package:flutter/material.dart';
import '../explore/explore_page.dart';
import '../my_books/my_books_page.dart';
import '../groups/groups_page.dart';
import '../profile/profile_page.dart';
import '../admin/add_book_page.dart';

/// Main navigation screen with bottom navigation bar
/// Manages four main sections: Explore, My Books, Groups, and Profile
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // All four main pages - IndexedStack keeps them in memory for smooth switching
  final _pages = const [
    ExplorePage(),      // Browse and discover books
    MyBooksPage(),      // User's reading shelves
    GroupsPage(),       // Reading groups (coming soon)
    ProfilePage(),      // User profile and stats
  ];

  @override
  Widget build(BuildContext context) {
    final titles = ['Explore', 'My Books', 'Groups', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
      ),
      // IndexedStack preserves state when switching tabs (better UX than TabBarView)
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // Bottom navigation bar for switching between main sections
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        elevation: 4,
        height: 70,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'My Books',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      // Floating action button to add books (only shown on Explore tab)
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddBookPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Book'),
            )
          : null,
    );
  }
}

