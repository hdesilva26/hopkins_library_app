import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../explore/explore_page.dart';
import '../my_books/my_books_page.dart';
import '../required/required_books_page.dart';
import '../profile/profile_page.dart';
import '../admin/add_book_page.dart';
import '../../services/auth_state.dart';

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
        final pages = <Widget>[
          const ExplorePage(),
          const MyBooksPage(),
          const RequiredBooksPage(),
          const ProfilePage(),
        ];

        final destinations = <_NavItem>[
          _NavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: 'EXPLORE',
          ),
          _NavItem(
            icon: Icons.menu_book_outlined,
            selectedIcon: Icons.menu_book,
            label: 'MY BOOKS',
          ),
          _NavItem(
            icon: Icons.school_outlined,
            selectedIcon: Icons.school,
            label: 'REQUIRED',
          ),
          _NavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'PROFILE',
          ),
        ];

        final titles = <String>['Explore', 'My Books', 'Required', 'Profile'];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              titles[_selectedIndex].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
            actions: [
              if (_selectedIndex == 0)
                Consumer<AuthState>(
                  builder: (context, auth, _) {
                    if (!auth.isAdmin) return const SizedBox.shrink();
                    return IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddBookPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Book',
                    );
                  },
                ),
            ],
          ),
          body: IndexedStack(index: _selectedIndex, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey.shade500,
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: destinations
                .map(
                  (item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    activeIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
