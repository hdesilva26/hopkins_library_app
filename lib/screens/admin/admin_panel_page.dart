import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_state.dart';
import '../../services/user_service.dart';

/// Admin panel for managing user roles
/// Allows admins to promote users to admin or demote them to student
class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    
    // Only admins can access this page
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Panel')),
        body: const Center(
          child: Text('Access Denied. Admin privileges required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(28),
          child: Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Manage User Roles',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userId = userDoc.id;
              final userData = userDoc.data() as Map<String, dynamic>;
              // Try to get email from Firestore, fallback to Firebase Auth user email
              String email = userData['email'] as String? ?? 
                            (userId == auth.user?.uid ? (auth.user?.email ?? 'Unknown') : 'Unknown');
              final role = userData['role'] as String? ?? UserService.roleStudent;
              final isCurrentUser = userId == auth.user?.uid;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(email),
                  subtitle: Text('Role: ${role.toUpperCase()}'),
                  trailing: isCurrentUser
                      ? Chip(
                          label: const Text('You'),
                          backgroundColor: Colors.blue.shade100,
                        )
                      : role == UserService.roleAdmin
                          ? ElevatedButton(
                              onPressed: () => _changeUserRole(
                                context,
                                userId,
                                UserService.roleStudent,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('Make Student'),
                            )
                          : ElevatedButton(
                              onPressed: () => _changeUserRole(
                                context,
                                userId,
                                UserService.roleAdmin,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Make Admin'),
                            ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _changeUserRole(
    BuildContext context,
    String userId,
    String newRole,
  ) async {
    final userService = UserService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await userService.setUserRole(userId, newRole);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('User role changed to ${newRole.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to change role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

