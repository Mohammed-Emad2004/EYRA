import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Mock authentication & first-run state.
///
/// There is no real backend. "Login", "Sign up" and "Reset password" all
/// simulate a short network delay and then succeed locally.
class AuthController extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;
  String? _displayName;

  bool get isLoggedIn => _isLoggedIn;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String? get displayName => _displayName;

  static AuthController of(BuildContext context, {bool listen = false}) {
    return Provider.of<AuthController>(context, listen: listen);
  }

  Future<void> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 900));
    _isLoggedIn = true;
    _displayName ??= email.split('@').first;
    notifyListeners();
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    _isLoggedIn = true;
    _displayName = fullName;
    notifyListeners();
  }

  Future<void> sendPasswordReset({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 900));
  }

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  void logOut() {
    _isLoggedIn = false;
    notifyListeners();
  }
}
