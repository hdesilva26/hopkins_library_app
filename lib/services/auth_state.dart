import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_service.dart';

/// Authentication state management
/// Handles Google Sign-In with domain restriction to Hopkins.edu accounts
/// Manages user roles (student/teacher/admin) LIVE from Firestore
class AuthState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  User? _user;
  bool _initializing = true;

  String _userRole = UserService.roleStudent;
  bool _roleLoaded = false;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  AuthState() {
    _user = _auth.currentUser;

    // Start listening to auth changes
    _authSub = _auth.authStateChanges().listen((user) async {
      _user = user;

      if (user == null) {
        _stopUserDocListener();
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
        await _googleSignIn.signOut();
        throw Exception('Invalid email format.');
      }

      final domain = emailParts.last.trim();
      final isValidDomain = domain == 'hopkins.edu' || domain.endsWith('.hopkins.edu');
      if (!isValidDomain) {
        await _googleSignIn.signOut();
        throw Exception('Please use your Hopkins school Google account. (Domain: $domain)');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      // Auth listener will handle role + doc listener
    } on PlatformException catch (e) {
      debugPrint('Google sign-in PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'sign_in_failed' || e.code == 'sign_in_canceled') {
        throw Exception(
          'Google Sign-In failed. Please check Firebase configuration and ensure the package name matches.',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
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
