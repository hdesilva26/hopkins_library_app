import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_state.dart';
import '../../services/user_service.dart';

/// Admin panel for managing user roles
/// Allows admins to change users between student / teacher / admin
class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  // If your UserService doesn't have roleTeacher yet, add it there.
  // Keeping them here as a fallback is also fine.
  static const List<String> _roles = <String>[
    UserService.roleStudent,
    UserService.roleTeacher,
    UserService.roleAdmin,
  ];

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

              final isCurrentUser = userId == auth.user?.uid;

              final email = (userData['email'] as String?) ??
                  (isCurrentUser ? (auth.user?.email ?? 'Unknown') : 'Unknown');

              final roleRaw = userData['role'] as String?;
              final currentRole = _roles.contains(roleRaw)
                  ? roleRaw!
                  : UserService.roleStudent; // safe default

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(email),
                    subtitle: Text('UID: $userId'),
                    trailing: SizedBox(
                      width: 170,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isCurrentUser)
                            Chip(
                              label: const Text('You'),
                              backgroundColor: Colors.blue.shade100,
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: currentRole,
                              isDense: true,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                              ),
                              items: _roles
                                  .map(
                                    (r) => DropdownMenuItem<String>(
                                      value: r,
                                      child: Text(_prettyRole(r)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (newRole) async {
                                if (newRole == null || newRole == currentRole) {
                                  return;
                                }
                                await _changeUserRole(context, userId, newRole);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _prettyRole(String role) {
    switch (role) {
      case UserService.roleAdmin:
        return 'Admin';
      case UserService.roleTeacher:
        return 'Teacher';
      case UserService.roleStudent:
      default:
        return 'Student';
    }
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
          content: Text('User role changed to ${_prettyRole(newRole)}'),
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
