import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

/// Authentication state management
/// Handles Google Sign-In with domain restriction to Hopkins.edu accounts
/// Manages user roles (student/admin)
class AuthState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Single GoogleSignIn instance to avoid logout bugs
  // Configured with email scope for user identification
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  User? _user;
  bool _initializing = true;
  String _userRole = UserService.roleStudent;
  bool _roleLoaded = false;

  AuthState() {
    // Check if user is already signed in
    _user = _auth.currentUser;
    if (_user != null) {
      _loadUserRole();
    }
    // Listen for authentication state changes (sign in/out)
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _loadUserRole();
      } else {
        _userRole = UserService.roleStudent;
        _roleLoaded = false;
      }
      _initializing = false;
      notifyListeners();
    });
  }

  /// Load user role from Firestore
  Future<void> _loadUserRole() async {
    if (_user == null) return;

    try {
      _userRole = await _userService.getUserRole(_user!.uid);
      _roleLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user role: $e');
      _userRole = UserService.roleStudent;
      _roleLoaded = true;
      notifyListeners();
    }
  }

  User? get user => _user;
  bool get initializing => _initializing;
  bool get isSignedIn => _user != null;
  String get userRole => _userRole;
  bool get isAdmin => _userRole == UserService.roleAdmin;
  bool get isStudent => _userRole == UserService.roleStudent;
  bool get roleLoaded => _roleLoaded;

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
        debugPrint('Email validation failed: Invalid email format for $email');
        await _googleSignIn.signOut();
        throw Exception(
          'Invalid email format. Please use a valid email address.',
        );
      }

      final allowedDomain = emailParts.last.trim();
      debugPrint('Extracted domain: $allowedDomain');

      // Step 4: Validate domain is Hopkins.edu or subdomain (e.g. students.hopkins.edu)
      final isValidDomain =
          allowedDomain == 'hopkins.edu' ||
          allowedDomain.endsWith('.hopkins.edu');

      debugPrint(
        'Domain validation result: $isValidDomain for domain: $allowedDomain',
      );

      if (!isValidDomain) {
        debugPrint(
          'Security: Rejecting sign-in attempt from non-Hopkins domain: $allowedDomain',
        );
        await _googleSignIn.signOut();
        throw Exception(
          'Access denied. Please use your Hopkins school Google account. (Attempted domain: $allowedDomain)',
        );
      }

      // Step 5: Get authentication credentials from Google
      final googleAuth = await googleUser.authentication;

      // Step 6: Create Firebase credential and sign in
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      // Store user email in Firestore and load user role after successful sign-in
      if (_auth.currentUser != null) {
        final currentUser = _auth.currentUser!;
        // Store/update user email in Firestore
        await _userService.updateUserProfile(currentUser.uid, {
          'email': currentUser.email ?? '',
          'displayName': currentUser.displayName ?? '',
        });
        await _loadUserRole();
      }
    } on PlatformException catch (e) {
      debugPrint('Google sign-in PlatformException: ${e.code} - ${e.message}');
      // Handle specific platform errors
      if (e.code == 'sign_in_failed' || e.code == 'sign_in_canceled') {
        debugPrint(
          'Authentication failed: Platform error ${e.code} - Check Firebase configuration',
        );
        throw Exception(
          'Google Sign-In failed. Please check your Firebase configuration and ensure the package name matches.',
        );
      }
      debugPrint(
        'Unexpected platform error during sign-in: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      debugPrint('Error type: ${e.runtimeType}');
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
