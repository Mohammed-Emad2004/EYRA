import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../models/user.dart';
import '../auth_service.dart';

/// Firebase Auth implementation of [AuthService].
///
/// Maps Firebase exceptions to clean application-level errors.
/// Firebase UID becomes the application's user identifier.
/// Never stores passwords - Firebase manages credentials.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _firebaseAuth;

  @override
  Future<User?> login({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUser(credential.user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  @override
  Future<User?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(fullName);
      return _mapFirebaseUser(credential.user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  @override
  Future<void> logOut() async {
    await _firebaseAuth.signOut();
  }

  /// Maps a Firebase user to our domain [User] model.
  /// Firebase UID becomes the application's user identifier.
  User? _mapFirebaseUser(fb.User? firebaseUser) {
    if (firebaseUser == null) return null;
    return User(
      userId: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      createdAt: firebaseUser.metadata.creationTime,
      updatedAt: firebaseUser.metadata.lastSignInTime,
    );
  }

  /// Maps Firebase Auth exceptions to clean, user-friendly error messages.
  /// Never exposes raw Firebase error codes to the UI.
  String _mapFirebaseError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

/// Application-level authentication exception.
/// Carries a clean, user-friendly message - never raw Firebase error codes.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
