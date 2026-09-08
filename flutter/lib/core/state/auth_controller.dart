import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
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
  AuthController({AuthService? authService})
      : _authService = authService ?? MockAuthService();

  final AuthService _authService;

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

  Future<void> login({required String email, required String password}) async {
    final user = await _authService.login(email: email, password: password);
    if (user == null) return;
    _currentUser = user;
    _isLoggedIn = true;
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
    // Fire-and-forget: today's mock has nothing to await, and logging the
    // UI out should feel instant. A real AuthService implementation can
    // still do async cleanup (e.g. revoke a token) without blocking this.
    unawaited(_authService.logOut());
    _isLoggedIn = false;
    notifyListeners();
  }
}
