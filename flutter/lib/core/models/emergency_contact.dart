/// Domain model for a trusted emergency contact.
///
/// Maps to the emergency-contact table in the backend ERD (rendered in
/// the source diagram as "emergency Contact").
///
/// AMBIGUOUS SCHEMA TABLE: the ERD appears to render this same set of
/// contact-shaped columns (contact id, user id, contact name,
/// relationship, phone number, SMS/call notification flags, created_at)
/// in TWO overlapping boxes - one titled "emergency Contact" (heavily
/// garbled by OCR) and one titled "emergency Incidents" (more legible,
/// but semantically an odd fit for a table meant to represent
/// *incidents* rather than *contacts*). This model is built from the
/// more legible rendering. See the architecture notes shipped with this
/// refactor, and [EmergencyIncident], for the full explanation - this
/// requires confirmation from whoever owns the schema.
///
/// Database mapping (best-effort, see ambiguity note above):
/// - `contact_id`     -> [id]
/// - `user_id`        -> [userId]
/// - `contact_name`   -> [contactName]
/// - `relationship`   -> [relationship]
/// - `phone_number`   -> [phoneNumber]
/// - `notify_by_sms`  -> [notifyBySms]
/// - `notify_by_call` -> [notifyByCall]
/// - `created_at`     -> [createdAt]
class EmergencyContact {
  final String id;
  final String userId;
  final String contactName;
  final String? relationship;
  final String phoneNumber;
  final bool notifyBySms;
  final bool notifyByCall;
  final DateTime? createdAt;

  const EmergencyContact({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.phoneNumber,
    this.relationship,
    this.notifyBySms = true,
    this.notifyByCall = false,
    this.createdAt,
  });
}
