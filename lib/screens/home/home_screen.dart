import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../explore/explore_page.dart';
import '../my_books/my_books_page.dart';
import '../required/required_books_page.dart';
import '../groups/groups_page.dart';
import '../profile/profile_page.dart';
import '../admin/add_book_page.dart';
import '../../services/auth_state.dart';

/// Main navigation screen with bottom navigation bar
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, auth, _) {
        // Build pages and destinations dynamically based on user role
        final pages = <Widget>[
          const ExplorePage(),
          const MyBooksPage(),
          const RequiredBooksPage(),
          const GroupsPage(),
          const ProfilePage(),
        ];

        final destinations = <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'My Books',
          ),
          const NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Required',
          ),
          const NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

        final titles = <String>[
          'Explore',
          'My Books',
          'Required',
          'Groups',
          'Profile',
        ];

        return Scaffold(
          appBar: AppBar(title: Text(titles[_selectedIndex])),
          // IndexedStack preserves state when switching tabs
          body: IndexedStack(index: _selectedIndex, children: pages),
          // Bottom navigation bar with dynamic destinations
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            elevation: 4,
            height: 70,
            destinations: destinations,
          ),
          // Floating action button to add books (only shown on Explore tab for admins)
          floatingActionButton: _selectedIndex == 0
              ? Consumer<AuthState>(
                  builder: (context, auth, _) {
                    // Only show Add Book button for admins
                    if (!auth.isAdmin) return const SizedBox.shrink();

                    return FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddBookPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Book'),
                    );
                  },
                )
              : null,
        );
      },
    );
  }
}
