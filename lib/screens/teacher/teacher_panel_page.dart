import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_state.dart';
import '../../services/user_service.dart';
import '../../services/class_service.dart';
import 'create_class_page.dart';
import '../../models/class_model.dart';
// import 'student_profile_page.dart'; // Will create this next
import '../../models/book.dart';

/// Teacher panel for managing students and classes
/// Allows teachers to view all students, add them to classes, and see their reading profiles
class TeacherPanelPage extends StatefulWidget {
  const TeacherPanelPage({super.key});

  @override
  State<TeacherPanelPage> createState() => _TeacherPanelPageState();
}

class _TeacherPanelPageState extends State<TeacherPanelPage> {
  final TextEditingController _searchController = TextEditingController();
  final ClassService _classService = ClassService();
  String _selectedClassId = '';

  @override
  void initState() {
    super.initState();
    // No need to load classes manually, StreamBuilder will handle it
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    // Only teachers can access this page
    if (!auth.isTeacher && !auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Teacher Panel')),
        body: const Center(
          child: Text('Access Denied. Teacher privileges required.'),
        ),
      );
    }

    // Get the stream of classes
    final classesStream = _classService.getTeacherClasses(auth.user?.uid ?? '');

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
                'Manage Students & Classes',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ), // PreferredSize
      ), // AppBar
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateClassPage()),
          );
          // StreamBuilder updates automatically, no need to manually refresh
        },
        icon: const Icon(Icons.add),
        label: const Text('New Class'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ClassModel>>(
        stream: classesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading classes: ${snapshot.error}\n\nMake sure the Firestore index exists.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final classes = snapshot.data ?? [];

          // Convert to the map format the rest of the file expects, or refactor the rest
          // Let's refactor the _teacherClasses logic to rely on this data

          // Logic to update _teacherClasses and _selectedClassId
          // This is a bit tricky inside build.
          // Better approach: Use the snapshot data directly in the UI.

          // However, to keep minimal changes, I will rebuild the UI here.

          if (classes.isEmpty) {
            return const Center(
              child: Text("No classes yet. Tap 'New Class' to create one."),
            );
          }

          // Auto-select first class if none selected
          if (_selectedClassId.isEmpty && classes.isNotEmpty) {
            // Defer state update
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedClassId.isEmpty) {
                setState(() {
                  _selectedClassId = classes.first.id;
                });
              }
            });
          }

          return Column(
            children: [
              // Class selection and search bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class selector
                    const Text(
                      'Select Class:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value:
                          _selectedClassId.isNotEmpty &&
                              classes.any((c) => c.id == _selectedClassId)
                          ? _selectedClassId
                          : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Choose a class',
                      ),
                      items: classes.map((cls) {
                        String teacherName = cls.teacherName;
                        if (teacherName == 'Unknown Teacher' &&
                            cls.teacherId == auth.user?.uid) {
                          teacherName =
                              auth.user?.displayName ??
                              auth.user?.email ??
                              'Me';
                        }
                        return DropdownMenuItem<String>(
                          value: cls.id,
                          child: Text('$teacherName - ${cls.name}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClassId = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Search bar for adding students
                    const Text(
                      'Add Student to Class:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Search by email or name...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchAndAddStudent,
                        ),
                      ),
                      onSubmitted: (_) => _searchAndAddStudent(),
                    ),
                  ],
                ),
              ),

              // Students list
              Expanded(
                child: _selectedClassId.isEmpty
                    ? const Center(child: Text('Please select a class'))
                    : _buildStudentsList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_selectedClassId.isEmpty) {
      return const Center(
        child: Text('No classes available. Create your first class!'),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _classService.getClassStudents(_selectedClassId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No students in this class yet.\nUse the search bar above to add students!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final students = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final studentId = student['uid'] as String;
            final email = student['email'] as String? ?? 'Unknown';
            final displayName = student['displayName'] as String? ?? email;
            final role = student['role'] as String? ?? 'student';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(displayName),
                subtitle: Text(email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(role.toUpperCase()),
                      backgroundColor: role == 'student'
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () =>
                          _removeStudentFromClass(studentId, displayName),
                      tooltip: 'Remove from class',
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () =>
                          _viewStudentProfile(studentId, displayName),
                      tooltip: 'View reading profile',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _searchAndAddStudent() async {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty || _selectedClassId.isEmpty) return;

    try {
      // Search for user by email or display name
      QuerySnapshot userSnapshot;

      if (searchTerm.contains('@')) {
        // Search by email
        userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: searchTerm.toLowerCase())
            .get();
      } else {
        // Search by display name
        userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('displayName', isGreaterThanOrEqualTo: searchTerm)
            .where('displayName', isLessThanOrEqualTo: searchTerm + '\uf8ff')
            .get();
      }

      if (userSnapshot.docs.isEmpty) {
        _showMessage('No user found with: $searchTerm', isError: true);
        return;
      }

      final userDoc = userSnapshot.docs.first;
      final studentId = userDoc.id;
      final studentData = userDoc.data() as Map<String, dynamic>;
      final studentEmail = studentData['email'] as String? ?? 'Unknown';
      final studentName = studentData['displayName'] as String? ?? studentEmail;

      // Check if already enrolled
      final isEnrolled = await _classService.isStudentEnrolled(
        _selectedClassId,
        studentId,
      );
      if (isEnrolled) {
        _showMessage(
          '$studentName is already enrolled in this class',
          isError: true,
        );
        return;
      }

      // Add student to class
      await _classService.enrollStudent(
        classId: _selectedClassId,
        studentId: studentId,
      );

      _searchController.clear();
      _showMessage('$studentName added to class successfully!');
    } catch (e) {
      _showMessage('Failed to add student: $e', isError: true);
    }
  }

  Future<void> _removeStudentFromClass(
    String studentId,
    String studentName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text(
          'Are you sure you want to remove $studentName from this class?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _classService.removeStudent(
          classId: _selectedClassId,
          studentId: studentId,
        );
        _showMessage('$studentName removed from class');
      } catch (e) {
        _showMessage('Failed to remove student: $e', isError: true);
      }
    }
  }

  void _viewStudentProfile(String studentId, String studentName) {
    // TODO: Implement StudentProfilePage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student profile view coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
    /*
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentProfilePage(
          studentId: studentId,
          studentName: studentName,
        ),
      ),
    );
    */
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
