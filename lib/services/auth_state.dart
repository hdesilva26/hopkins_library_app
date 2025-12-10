import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Use ONE GoogleSignIn instance (avoid logout bugs)
  // Configure with web client ID for Android (from Firebase Console)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  User? _user;
  bool _initializing = true;

  AuthState() {
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((user) {
      _user = user;
      _initializing = false;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get initializing => _initializing;
  bool get isSignedIn => _user != null;

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // cancelled

      // Check domain BEFORE signing into Firebase
      final email = googleUser.email?.toLowerCase()?.trim();
      if (email == null || email.isEmpty) {
        await _googleSignIn.signOut();
        throw Exception('Unable to get email from Google account.');
      }

      debugPrint('Sign-in attempt with email: $email');

      // Allow main domain or any subdomain (e.g. students.hopkins.edu)
      final emailParts = email.split('@');
      if (emailParts.length != 2) {
        await _googleSignIn.signOut();
        throw Exception('Invalid email format.');
      }

      final allowedDomain = emailParts.last.trim();
      debugPrint('Extracted domain: $allowedDomain');

      // Check if domain is exactly 'hopkins.edu' or ends with '.hopkins.edu'
      final isValidDomain = allowedDomain == 'hopkins.edu' ||
          (allowedDomain.endsWith('.hopkins.edu') && 
           allowedDomain.length > '.hopkins.edu'.length);

      debugPrint('Domain validation result: $isValidDomain');

      if (!isValidDomain) {
        await _googleSignIn.signOut();
        throw Exception('Please use your Hopkins school Google account. (Domain: $allowedDomain)');
      }

      final googleAuth = await googleUser.authentication;

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

