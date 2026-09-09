import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model for an Eyra account.
///
/// Maps to the `users` table in the backend schema. The UI and
/// controllers only ever see this clean Dart model - never raw database
/// rows or a password hash.
///
/// Database mapping (`users` table):
/// - `user_id`     -> [id]
/// - `email`       -> [email]
/// - `password_hash` intentionally NOT represented here.
/// - `created_at`  -> [createdAt]
/// - `updated_at`  -> [updatedAt]
class User {
  final String userId;
  final String email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.userId,
    required this.email,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Serializes for Firestore `users/{uid}` document.
  /// Omits `user_id` — the document ID is the UID.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// Deserializes from a Firestore `users/{uid}` document.
  /// The UID comes from [doc.id], not the document body.
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      userId: doc.id,
      email: data['email'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
