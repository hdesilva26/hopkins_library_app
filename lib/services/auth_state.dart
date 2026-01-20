import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Authentication state management
/// Handles Google Sign-In with domain restriction to Hopkins.edu accounts
class AuthState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Single GoogleSignIn instance to avoid logout bugs
  // Configured with email scope for user identification
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  User? _user;
  bool _initializing = true;

  AuthState() {
    // Check if user is already signed in
    _user = _auth.currentUser;
    // Listen for authentication state changes (sign in/out)
    _auth.authStateChanges().listen((user) {
      _user = user;
      _initializing = false;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get initializing => _initializing;
  bool get isSignedIn => _user != null;

  /// Sign in with Google, but only allow Hopkins.edu email addresses
  /// Validates domain before completing Firebase authentication
  Future<void> signInWithGoogle() async {
    try {
      // Step 1: Initiate Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled sign-in

      // Step 2: Extract and validate email domain BEFORE Firebase sign-in
      final email = googleUser.email?.toLowerCase()?.trim();
      if (email == null || email.isEmpty) {
        await _googleSignIn.signOut();
        throw Exception('Unable to get email from Google account.');
      }

      debugPrint('Sign-in attempt with email: $email');

      // Step 3: Parse email to extract domain
      final emailParts = email.split('@');
      if (emailParts.length != 2) {
        await _googleSignIn.signOut();
        throw Exception('Invalid email format.');
      }

      final allowedDomain = emailParts.last.trim();
      debugPrint('Extracted domain: $allowedDomain');

      // Step 4: Validate domain is Hopkins.edu or subdomain (e.g. students.hopkins.edu)
      final isValidDomain = allowedDomain == 'hopkins.edu' ||
          allowedDomain.endsWith('.hopkins.edu');

      debugPrint('Domain validation result: $isValidDomain');

      if (!isValidDomain) {
        await _googleSignIn.signOut();
        throw Exception('Please use your Hopkins school Google account. (Domain: $allowedDomain)');
      }

      // Step 5: Get authentication credentials from Google
      final googleAuth = await googleUser.authentication;

      // Step 6: Create Firebase credential and sign in
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on PlatformException catch (e) {
      debugPrint('Google sign-in PlatformException: ${e.code} - ${e.message}');
      // Handle specific platform errors
      if (e.code == 'sign_in_failed' || e.code == 'sign_in_canceled') {
        throw Exception('Google Sign-In failed. Please check your Firebase configuration and ensure the package name matches.');
      }
      rethrow;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}

