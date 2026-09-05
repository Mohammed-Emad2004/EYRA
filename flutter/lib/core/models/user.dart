/// Domain model for an Eyra account.
///
/// Maps to the `users` table in the backend ERD. The UI and controllers
/// only ever see this clean Dart model - never raw database rows or a
/// password hash.
///
/// Database mapping (see ERD `users` table):
/// - `user_id`            -> [id]
/// - `full_name`          -> [fullName]
/// - `email`               -> [email]
/// - `password_hash`      -> intentionally NOT represented here. The UI
///   must never handle or display a password hash; if a future data
///   layer needs it, it belongs on a private DTO in that layer, not on
///   this domain model.
/// - (profile image column) -> [profileImageUrl]. AMBIGUOUS: the ERD
///   renders this column name as "phone_image_url", which does not match
///   any product concept. It is almost certainly a profile/avatar image
///   URL, but the exact column name requires confirmation - see the
///   architecture notes shipped with this refactor.
/// - `account_status`     -> [accountStatus]. The ERD's ENUM values are
///   not legible, so this is kept as a raw string rather than a typed
///   Dart enum, to avoid inventing values.
/// - (email verification column) -> [isEmailVerified]. AMBIGUOUS: the
///   ERD renders this column name as "is_ismail_verified", read here as
///   "is_email_verified" - requires confirmation.
/// - `last_login_at`      -> [lastLoginAt]
/// - `updated_at`         -> [updatedAt]
/// - `created_at` is not clearly visible on this table in the ERD -
///   AMBIGUOUS, see architecture notes.
class User {
  final String id;
  final String fullName;
  final String email;
  final String? profileImageUrl;
  final String accountStatus;
  final bool isEmailVerified;
  final DateTime? lastLoginAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.profileImageUrl,
    this.accountStatus = 'active',
    this.isEmailVerified = false,
    this.lastLoginAt,
    this.updatedAt,
  });
}
