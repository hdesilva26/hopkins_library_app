import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_state.dart';
import '../../models/app_state.dart';
import '../../widgets/common_widgets.dart';

/// User profile page displaying account info and reading statistics
/// Shows: User avatar, name, email, reading stats, and sign-out button
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;
    final state = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null)
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  child: Text(
                    (user.displayName?.isNotEmpty == true
                            ? user.displayName![0]
                            : user.email?[0] ?? '?')
                        .toUpperCase(),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Hopkins Student',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),
          const Text(
            'Your Reading Stats',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),
          // Display reading statistics from user's shelves
          StatRow(label: 'Finished', value: state.finishedBooks.length.toString()),
          StatRow(label: 'Reading', value: state.readingBooks.length.toString()),
          StatRow(label: 'Want to Read', value: state.wantToReadBooks.length.toString()),

          const Spacer(),
          
          Center(
            child: ElevatedButton.icon(
              onPressed: () => context.read<AuthState>().signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          )
        ],
      ),
    );
  }
}

