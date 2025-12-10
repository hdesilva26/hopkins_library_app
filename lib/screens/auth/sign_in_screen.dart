import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_state.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthState>().signInWithGoogle();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded,
                  size: 72, color: colorScheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Hopkins Reads',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in with your Hopkins Google account to track your summer reading.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: 260,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _handleSignIn,
                  icon: const Icon(Icons.login),
                  label: Text(_loading ? 'Signing in…' : 'Sign in with Hopkins'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

