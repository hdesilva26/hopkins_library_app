import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_state.dart';
import '../../services/feedback_service.dart';
import '../../models/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../admin/admin_panel_page.dart';
import '../admin/feedback_admin_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _feedbackController = TextEditingController();
  int _wordCount = 0;
  static const int _maxWords = 500;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  void _showFeedbackDialog(BuildContext context) {
    final auth = context.read<AuthState>();
    _feedbackController.clear();
    _wordCount = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Feedback'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Any issues/comments? Feel free to let us know.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _feedbackController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your feedback here...',
                  ),
                  onChanged: (text) {
                    final count = _countWords(text);
                    if (count <= _maxWords) {
                      setDialogState(() {
                        _wordCount = count;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '$_wordCount / $_maxWords words',
                  style: TextStyle(
                    fontSize: 12,
                    color: _wordCount > _maxWords ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: _wordCount > 0 && _wordCount <= _maxWords
                  ? () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      await _feedbackService.submitFeedback(
                        email: auth.user?.email ?? '',
                        text: _feedbackController.text.trim(),
                      );
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Feedback submitted successfully'),
                          backgroundColor: Colors.black,
                        ),
                      );
                    }
                  : null,
              child: const Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;
    final state = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null) ...[
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      (user.displayName?.isNotEmpty == true
                              ? user.displayName![0]
                              : user.email?[0] ?? '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Hopkins Student',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'READING STATS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatRow(
                    label: 'Finished',
                    value: state.finishedBooks.length.toString(),
                  ),
                  StatRow(
                    label: 'Currently Reading',
                    value: state.readingBooks.length.toString(),
                  ),
                  StatRow(
                    label: 'Want to Read',
                    value: state.wantToReadBooks.length.toString(),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (auth.isAdmin)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings, size: 18),
                label: const Text('ADMIN PANEL'),
              ),
            ),
          if (auth.isAdmin) const SizedBox(height: 12),
          if (auth.isAdmin)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FeedbackAdminPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.feedback_outlined, size: 18),
                label: const Text('FEEDBACK'),
              ),
            ),
          if (auth.isAdmin) const SizedBox(height: 12),
          if (auth.isStudent) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _showFeedbackDialog(context),
                icon: const Icon(Icons.feedback_outlined, size: 18),
                label: const Text('FEEDBACK'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.read<AuthState>().signOut(),
              child: const Text('SIGN OUT'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
