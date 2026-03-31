import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_state.dart';
import '../../services/user_service.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  static const List<String> _roles = <String>[
    UserService.roleStudent,
    UserService.roleAdmin,
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('ADMIN PANEL')),
        body: const Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ADMIN PANEL',
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
              final email =
                  userData['email'] as String? ??
                  (isCurrentUser ? (auth.user?.email ?? 'Unknown') : 'Unknown');
              final roleRaw = userData['role'] as String?;
              final currentRole = _roles.contains(roleRaw)
                  ? roleRaw!
                  : UserService.roleStudent;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          (email.isNotEmpty ? email[0].toUpperCase() : '?'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'UID: ${userId.substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentRole,
                            isDense: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            items: _roles
                                .map(
                                  (r) => DropdownMenuItem<String>(
                                    value: r,
                                    child: Text(_prettyRole(r).toUpperCase()),
                                  ),
                                )
                                .toList(),
                            onChanged: (newRole) async {
                              if (newRole != null && newRole != currentRole) {
                                await _changeUserRole(context, userId, newRole);
                              }
                            },
                          ),
                        ),
                      ),
                  ],
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
    try {
      await userService.setUserRole(userId, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User role changed to ${_prettyRole(newRole)}'),
          backgroundColor: Colors.black,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
