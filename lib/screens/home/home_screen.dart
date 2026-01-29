import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../explore/explore_page.dart';
import '../my_books/my_books_page.dart';
import '../groups/groups_page.dart';
import '../profile/profile_page.dart';
import '../admin/add_book_page.dart';
import '../../services/auth_state.dart';

/// Main navigation screen with floating pill-shaped navigation bar
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
    ExplorePage(), // Browse and discover books
    MyBooksPage(), // User's reading shelves
    GroupsPage(), // Reading groups (coming soon)
    ProfilePage(), // User profile and stats
  ];

  @override
  Widget build(BuildContext context) {
    final titles = ['Explore', 'My Books', 'Groups', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      // IndexedStack preserves state when switching tabs (better UX than TabBarView)
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFF7FAFC)),
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      // Floating pill-shaped navigation bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
              label: 'Explore',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book,
              label: 'My Books',
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.group_outlined,
              activeIcon: Icons.group,
              label: 'Groups',
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              index: 3,
            ),
          ],
        ),
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
                      MaterialPageRoute(builder: (_) => const AddBookPage()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Book'),
                  backgroundColor: const Color(0xFF2D3748),
                  foregroundColor: Colors.white,
                );
              },
            )
          : null,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2D3748).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? const Color(0xFF2D3748) : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF2D3748)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
