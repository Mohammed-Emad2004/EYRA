import '../../models/user.dart';
import '../auth_service.dart';

/// Local mock implementation of [AuthService].
///
/// Simulates a short round-trip delay and always succeeds, returning a
/// locally-constructed [User]. There is no real network call, backend,
/// or persistent account store involved - this exists purely so the
/// rest of the app can be built and reasoned about against the
/// [AuthService] interface today, and swapped for a real backend later
/// without touching [AuthController] or any screen.
class MockAuthService implements AuthService {
  @override
  Future<User?> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return User(
      id: 'mock-user-${email.hashCode}',
      fullName: email.split('@').first,
      email: email,
      accountStatus: 'active',
      isEmailVerified: true,
      lastLoginAt: DateTime.now(),
    );
  }

  @override
  Future<User?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return User(
      id: 'mock-user-${email.hashCode}',
      fullName: fullName,
      email: email,
      accountStatus: 'active',
      isEmailVerified: false,
      lastLoginAt: DateTime.now(),
    );
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 900));
  }

  @override
  Future<void> logOut() async {
    // Nothing to revoke locally. A real implementation might call a
    // sign-out endpoint or clear a stored token here.
  }
}
