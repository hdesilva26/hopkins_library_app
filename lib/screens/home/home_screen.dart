import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../explore/explore_page.dart';
import '../my_books/my_books_page.dart';
import '../profile/profile_page.dart';
import '../teacher/teacher_panel_page.dart';
import '../admin/add_book_page.dart';
import '../../services/auth_state.dart';

/// Main navigation screen with bottom navigation bar
/// Dynamically shows Classes tab for teachers/admins
/// Main navigation screen with floating pill-shaped navigation bar
/// Manages four main sections: Explore, My Books, Groups, and Profile
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
        // Debug: Print role information
        print('🔍 DEBUG: User role = ${auth.userRole}');
        print('🔍 DEBUG: isTeacher = ${auth.isTeacher}');
        print('🔍 DEBUG: isAdmin = ${auth.isAdmin}');
        print(
          '🔍 DEBUG: Should show Classes = ${auth.isTeacher || auth.isAdmin}',
        );

        // Build pages and destinations dynamically based on user role
        // Build pages and navigation items dynamically based on user role
        final pages = <Widget>[
          const ExplorePage(),
          const MyBooksPage(),
          // Insert Classes page for teachers/admins between My Books and Groups
          if (auth.isTeacher || auth.isAdmin) const TeacherPanelPage(),
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
          // Insert Classes destination for teachers/admins
          if (auth.isTeacher || auth.isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Classes',
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
          if (auth.isTeacher || auth.isAdmin) 'Classes',
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
          const ProfilePage(),
        ];

        final navItems = <Map<String, dynamic>>[
          {
            'icon': Icons.explore_outlined,
            'activeIcon': Icons.explore,
            'label': 'Explore',
          },
          {
            'icon': Icons.menu_book_outlined,
            'activeIcon': Icons.menu_book,
            'label': 'My Books',
          },
          // Insert Classes navigation for teachers/admins
          if (auth.isTeacher || auth.isAdmin)
            {
              'icon': Icons.school_outlined,
              'activeIcon': Icons.school,
              'label': 'Classes',
            },
          {
            'icon': Icons.person_outline,
            'activeIcon': Icons.person,
            'label': 'Profile',
          },
        ];

        final titles = <String>[
          'Explore',
          'My Books',
          if (auth.isTeacher || auth.isAdmin) 'Classes',
          'Profile',
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(titles[_selectedIndex]),
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          // IndexedStack preserves state when switching tabs
          body: Container(
            decoration: const BoxDecoration(color: Color(0xFFF7FAFC)),
            child: IndexedStack(index: _selectedIndex, children: pages),
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
              children: List.generate(
                navItems.length,
                (index) => _buildNavItem(
                  icon: navItems[index]['icon'] as IconData,
                  activeIcon: navItems[index]['activeIcon'] as IconData,
                  label: navItems[index]['label'] as String,
                  index: index,
                ),
              ),
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
                          MaterialPageRoute(
                            builder: (_) => const AddBookPage(),
                          ),
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
      },
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
