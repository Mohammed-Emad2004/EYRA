import '../models/emergency_contact.dart';

/// Abstraction boundary for a user's emergency contacts.
///
/// No screen currently uses this - per product scope, an emergency
/// contacts UI has not been built yet. This interface and its mock
/// implementation exist purely for backend-readiness, so a future
/// Emergency Contacts screen (and a future `RemoteEmergencyContactService`)
/// can be added without further architectural changes.
abstract class EmergencyContactService {
  Future<List<EmergencyContact>> getContacts();
  Future<void> saveContact(EmergencyContact contact);
  Future<void> deleteContact(String contactId);
}
