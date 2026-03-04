import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_service.dart';
import '../models/app_state.dart';

/// Authentication state management
/// Handles Google Sign-In with domain restriction to Hopkins.edu accounts
/// Manages user roles (student/teacher/admin) LIVE from Firestore
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
  AppState? _appState;

  void setAppState(AppState appState) {
    _appState = appState;
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  AuthState() {
    _user = _auth.currentUser;

    // Start listening to auth changes
    _authSub = _auth.authStateChanges().listen((user) async {
      _user = user;

      if (user == null) {
        _stopUserDocListener();
      if (user != null) {
        _loadUserRole();
        // Load user shelf data when user signs in
        _loadUserShelf();
      } else {
        _userRole = UserService.roleStudent;
        _roleLoaded = false;
        _initializing = false;
        notifyListeners();
        return;
      }

      // Ensure user exists in Firestore + load initial role
      await _ensureUserDocAndInitialRole(user);

      // Listen for live changes to role
      _startUserDocListener(user.uid);

      _initializing = false;
      notifyListeners();
    });

    // If already signed in at startup, kick things off
    if (_user != null) {
      _ensureUserDocAndInitialRole(_user!).then((_) {
        _startUserDocListener(_user!.uid);
        _initializing = false;
        notifyListeners();
      });
    } else {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<void> _ensureUserDocAndInitialRole(User user) async {
  Future<void> _loadUserShelf() async {
    if (_appState != null && _user != null) {
      try {
        await _appState!.loadUserShelf(_user!.uid);
      } catch (e) {
        debugPrint('Error loading user shelf: $e');
      }
    }
  }

  /// Load user role from Firestore
  Future<void> _loadUserRole() async {
    if (_user == null) return;

    try {
      // This creates the doc as student if missing
      _userRole = await _userService.getUserRole(user.uid);
      _roleLoaded = true;

      // Also store/update profile fields you want
      await _userService.updateUserProfile(user.uid, {
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error ensuring user doc / role: $e');
      _userRole = UserService.roleStudent;
      _roleLoaded = true;
      notifyListeners();
    }
  }

  void _startUserDocListener(String uid) {
    _stopUserDocListener();

    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      final newRole = (data?['role'] as String?) ?? UserService.roleStudent;

      if (newRole != _userRole) {
        _userRole = newRole;
        _roleLoaded = true;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('User doc listener error: $e');
    });
  }

  void _stopUserDocListener() {
    _userDocSub?.cancel();
    _userDocSub = null;
  }

  User? get user => _user;
  bool get initializing => _initializing;
  bool get isSignedIn => _user != null;

  String get userRole => _userRole;
  bool get isAdmin => _userRole == UserService.roleAdmin;
  bool get isTeacher => _userRole == UserService.roleTeacher;
  bool get isStudent => _userRole == UserService.roleStudent;

  bool get isTeacher => _userRole == UserService.roleTeacher;
  bool get roleLoaded => _roleLoaded;

  /// Sign in with Google, but only allow Hopkins.edu email addresses
  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final email = googleUser.email.toLowerCase().trim();
      if (email.isEmpty) {
        await _googleSignIn.signOut();
        throw Exception('Unable to get email from Google account.');
      }

      final emailParts = email.split('@');
      if (emailParts.length != 2) {
        debugPrint('Email validation failed: Invalid email format for $email');
        await _googleSignIn.signOut();
        throw Exception(
          'Invalid email format. Please use a valid email address.',
        );
      }

      final domain = emailParts.last.trim();
      final isValidDomain = domain == 'hopkins.edu' || domain.endsWith('.hopkins.edu');
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
        throw Exception('Please use your Hopkins school Google account. (Domain: $domain)');
        throw Exception(
          'Access denied. Please use your Hopkins school Google account. (Attempted domain: $allowedDomain)',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      // Auth listener will handle role + doc listener
      // Store user email in Firestore and load user role after successful sign-in
      if (_auth.currentUser != null) {
        final currentUser = _auth.currentUser!;
        // Store/update user email in Firestore
        await _userService.updateUserProfile(currentUser.uid, {
          'email': currentUser.email ?? '',
          'displayName': currentUser.displayName ?? '',
        });
        await _loadUserRole();
        // Load user shelf data after successful sign-in
        _loadUserShelf();
      }
    } on PlatformException catch (e) {
      debugPrint('Google sign-in PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'sign_in_failed' || e.code == 'sign_in_canceled') {
        throw Exception(
          'Google Sign-In failed. Please check Firebase configuration and ensure the package name matches.',
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
    _stopUserDocListener();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  @override
  void dispose() {
    _stopUserDocListener();
    _authSub?.cancel();
    _authSub = null;
    super.dispose();
  }
}
