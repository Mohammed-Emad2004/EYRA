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
}
