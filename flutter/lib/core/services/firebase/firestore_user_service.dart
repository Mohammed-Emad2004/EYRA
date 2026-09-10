import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user.dart';

/// Firestore service for managing user documents at `users/{uid}`.
///
/// Called by [AuthController] after Firebase Authentication events.
/// Not behind an abstract interface — it is inherently Firebase-specific.
class FirestoreUserService {
  FirestoreUserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Creates the Firestore user document after successful signup.
  /// Called once after Firebase Auth creates the account.
  Future<void> createUser(User user) async {
    final docRef = _firestore.collection('users').doc(user.userId);
    await docRef.set(user.toFirestore());
  }

  /// Reads the existing user document. Returns `null` if not found.
  Future<User?> getUser(String uid) async {
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists) return null;
    return User.fromFirestore(doc);
  }

  /// Ensures the user document exists. If missing (legacy recovery),
  /// creates it from the provided [user]. Returns the document.
  Future<User> ensureUserDocument(User user) async {
    final existing = await getUser(user.userId);
    if (existing != null) return existing;
    await createUser(user);
    return user;
  }
}
