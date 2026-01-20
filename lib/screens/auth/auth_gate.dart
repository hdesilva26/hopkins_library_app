import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_state.dart';
import '../auth/sign_in_screen.dart';
import '../home/home_screen.dart';

/// Authentication routing widget
/// Determines which screen to show based on authentication status:
/// - Loading: Shows spinner while checking auth state
/// - Not signed in: Shows sign-in screen
/// - Signed in: Shows main home screen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, auth, _) {
        // Show loading indicator while checking authentication state
        if (auth.initializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Route to sign-in screen if user is not authenticated
        if (!auth.isSignedIn) {
          return const SignInScreen();
        }

        // Route to main app if user is authenticated
        return const HomeScreen();
      },
    );
  }
}

