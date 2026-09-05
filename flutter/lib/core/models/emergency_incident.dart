/// Domain model for an emergency incident record.
///
/// Maps to the `emergency Incidents` table in the backend ERD.
///
/// AMBIGUOUS SCHEMA TABLE - REQUIRES CONFIRMATION: the box in the ERD
/// titled "emergency Incidents" does not show incident-shaped columns
/// (e.g. an incident type, severity, trigger reason, resolved/acknowledged
/// timestamp, or location). Instead it shows the same contact-shaped
/// columns as the "emergency Contact" box (contact id, user id x2,
/// contact name, relationship, phone number, SMS/call notification
/// flags, created_at). This strongly suggests either:
///   (a) the diagram duplicated the Emergency Contact table and
///       mislabeled one copy as "emergency Incidents", or
///   (b) "emergency Incidents" is genuinely meant to store a
///       per-incident snapshot of which contact was notified, and the
///       real incident-specific columns (type/severity/status/etc.)
///       exist but were not legible in the exported image.
///
/// Per the instruction to never guess at unclear schema, this model
/// intentionally represents ONLY the fields that are actually visible on
/// that ERD box, with NO invented incident-specific fields (no
/// "type", "severity", "status", "resolvedAt", etc.). Do not add such
/// fields until the schema owner confirms which interpretation is
/// correct.
///
/// Database mapping (best-effort, see ambiguity note above):
/// - `contact_id`     -> [contactId]
/// - `user_id`        -> [userId]
/// - `contact_name`   -> [contactName]
/// - `relationship`   -> [relationship]
/// - `phone_number`   -> [phoneNumber]
/// - `notify_by_sms`  -> [notifyBySms]
/// - `notify_by_call` -> [notifyByCall]
/// - `created_at`     -> [createdAt]
class EmergencyIncident {
  final String contactId;
  final String userId;
  final String? contactName;
  final String? relationship;
  final String? phoneNumber;
  final bool? notifyBySms;
  final bool? notifyByCall;
  final DateTime? createdAt;

  const EmergencyIncident({
    required this.contactId,
    required this.userId,
    this.contactName,
    this.relationship,
    this.phoneNumber,
    this.notifyBySms,
    this.notifyByCall,
    this.createdAt,
  });
}
