import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_state.dart';
import 'teacher_class_service.dart';

class ClassroomPage extends StatefulWidget {
  final String classId;
  final String className;

  const ClassroomPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassroomPage> createState() => _ClassroomPageState();
}

class _ClassroomPageState extends State<ClassroomPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _canAccess(AuthState auth) {
    // allow teacher/admin to view classroom tools
    return auth.isAdmin || auth.userRole == TeacherClassService.roleTeacher;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (!_canAccess(auth)) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.className)),
        body: const Center(child: Text('Access Denied')),
      );
    }

    final teacherId = auth.user?.uid;
    if (teacherId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.className)),
        body: const Center(child: Text('Not signed in')),
      );
    }

    final service = TeacherClassService();

    return Scaffold(
      appBar: AppBar(title: Text(widget.className)),
      body: Column(
        children: [
          // Students header + search
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Students',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Search students by email or name',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),

          // Student list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: service.classStudentsStream(widget.classId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No students added yet.'));
                }

                final query = _searchController.text.trim().toLowerCase();

                final filtered = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final email = (data['email'] as String? ?? '').toLowerCase();
                  final name = (data['displayName'] as String? ?? '')
                      .toLowerCase();
                  if (query.isEmpty) return true;
                  return email.contains(query) || name.contains(query);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final displayName = (data['displayName'] as String?)
                        ?.trim();
                    final email = (data['email'] as String?)?.trim() ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          (displayName != null && displayName.isNotEmpty)
                              ? displayName
                              : email.isNotEmpty
                              ? email
                              : doc.id,
                        ),
                        subtitle: email.isNotEmpty ? Text(email) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );
                            try {
                              await service.removeStudentFromClass(
                                classId: widget.classId,
                                teacherId: teacherId,
                                studentUserId: doc.id,
                              );
                              if (!mounted) return;
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Student removed'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text('Failed to remove: $e')),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
