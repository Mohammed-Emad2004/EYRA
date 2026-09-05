import '../models/user.dart';

/// Abstraction boundary for authentication.
///
/// [AuthController] depends only on this interface, never on a concrete
/// implementation. Today the only implementation is [MockAuthService]
/// (see `mock/mock_auth_service.dart`), which simulates a short delay and
/// always succeeds locally. A future real backend (REST, GraphQL,
/// Firebase Auth, etc.) can implement this same interface and be swapped
/// in at the [AuthController] construction site - no screen or controller
/// code needs to change.
///
/// Methods return the domain [User] model (see `models/user.dart`), never
/// a raw database row or password hash - the UI must never handle or
/// display a password hash.
abstract class AuthService {
  /// Attempts to log in with an email/password pair.
  ///
  /// Returns the authenticated [User] on success, or `null`/throws on
  /// failure (a real implementation would throw for bad credentials,
  /// network errors, etc.).
  Future<User?> login({required String email, required String password});

  /// Registers a new account and returns the created [User].
  Future<User?> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  /// Requests a password-reset email/flow for the given address.
  Future<void> sendPasswordReset({required String email});

  /// Signs the current user out. A real implementation might revoke a
  /// token or call a sign-out endpoint here.
  Future<void> logOut();
}
