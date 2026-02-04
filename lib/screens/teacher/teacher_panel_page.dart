import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_state.dart';
import 'teacher_class_service.dart';
import 'create_class_page.dart';
import 'classroom_page.dart';

class TeacherPanelPage extends StatelessWidget {
  const TeacherPanelPage({super.key});

  bool _canAccess(AuthState auth) {
    // teachers OR admins can access
    return auth.isAdmin || (auth.userRole == TeacherClassService.roleTeacher);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (!_canAccess(auth)) {
      return Scaffold(
        appBar: AppBar(title: Text('Teacher Panel')),
        body: const Center(
          child: Text('Access Denied. Teacher privileges required.'),
        ),
      );
    }

    final teacherId = auth.user?.uid;
    if (teacherId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Teacher Panel')),
        body: const Center(child: Text('Not signed in')),
      );
    }

    final service = TeacherClassService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Panel'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(28),
          child: Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Manage Your Classes',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateClassPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Class'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.teacherClassesStream(teacherId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No classes yet.\nTap "New Class" to create one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final className = (data['name'] as String?) ?? 'Untitled Class';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(className),
                  subtitle: Text('Class ID: ${doc.id}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassroomPage(
                          classId: doc.id,
                          className: className,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
