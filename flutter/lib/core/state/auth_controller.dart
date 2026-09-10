import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firebase/firebase_auth_service.dart';
import '../services/firebase/firestore_user_service.dart';
import '../services/mock/mock_auth_service.dart';

/// Authentication & first-run application state.
///
/// This controller is the abstraction boundary the UI depends on. It
/// never talks to a backend, timer, or storage API directly - it
/// delegates all actual authentication work to an injected [AuthService].
/// By default that is [MockAuthService], but a real backend
/// implementation of [AuthService] can be passed in instead (e.g. in
/// `main.dart`) without changing this class or any screen.
class AuthController extends ChangeNotifier {
  AuthController({
    AuthService? authService,
    FirestoreUserService? userService,
  })  : _authService = authService ?? MockAuthService(),
        _userService = userService {
    if (_authService is FirebaseAuthService) {
      _authStateSubscription = fb.FirebaseAuth.instance
          .authStateChanges()
          .listen(_onAuthStateChanged);
      _checkInitialAuthState();
    }
  }

  final AuthService _authService;
  final FirestoreUserService? _userService;
  StreamSubscription<fb.User?>? _authStateSubscription;

  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;
  User? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  /// The current signed-in user's domain profile, or `null` if signed
  /// out. Never carries a password hash - see [User].
  User? get currentUser => _currentUser;

  /// Convenience accessor kept for existing UI code that only needs a
  /// display name (derived from [currentUser]).
  String? get displayName => _currentUser?.email.split('@').first;

  static AuthController of(BuildContext context, {bool listen = false}) {
    return Provider.of<AuthController>(context, listen: listen);
  }

  /// Checks if a Firebase user is already authenticated on app start.
  /// On legacy recovery, ensures the Firestore user document exists.
  void _checkInitialAuthState() {
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      _currentUser = _mapFirebaseUser(fbUser);
      _isLoggedIn = true;
      // Legacy recovery: ensure user document exists on login
      final userService = _userService;
      if (userService != null) {
        userService.ensureUserDocument(_currentUser!);
      }
      notifyListeners();
    }
  }

  /// Handles Firebase auth state changes (sign-in, sign-out, token refresh).
  void _onAuthStateChanged(fb.User? firebaseUser) {
    if (firebaseUser == null) {
      _currentUser = null;
      _isLoggedIn = false;
    } else {
      _currentUser = _mapFirebaseUser(firebaseUser);
      _isLoggedIn = true;
      // Legacy recovery: ensure user document exists on login
      final userService = _userService;
      if (userService != null) {
        userService.ensureUserDocument(_currentUser!);
      }
    }
    notifyListeners();
  }

  /// Maps a Firebase user to our domain [User] model.
  User _mapFirebaseUser(fb.User firebaseUser) {
    return User(
      userId: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      createdAt: firebaseUser.metadata.creationTime,
      updatedAt: firebaseUser.metadata.lastSignInTime,
    );
  }

  Future<void> login({required String email, required String password}) async {
    final user = await _authService.login(email: email, password: password);
    if (user == null) return;
    _currentUser = user;
    _isLoggedIn = true;
    // Legacy recovery: ensure user document exists on login
    final userService = _userService;
    if (userService != null) {
      await userService.ensureUserDocument(user);
    }
    notifyListeners();
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final user = await _authService.signUp(
      fullName: fullName,
      email: email,
      password: password,
    );
    if (user == null) return;
    // Create Firestore user document as part of normal signup flow
    final userService = _userService;
    if (userService != null) {
      await userService.createUser(user);
    }
    _currentUser = user;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> sendPasswordReset({required String email}) {
    return _authService.sendPasswordReset(email: email);
  }

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  void logOut() {
    unawaited(_authService.logOut());
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
