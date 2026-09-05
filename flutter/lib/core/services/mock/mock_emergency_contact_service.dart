import '../../models/emergency_contact.dart';
import '../emergency_contact_service.dart';

/// Local in-memory mock implementation of [EmergencyContactService].
///
/// Not wired into any screen today (no emergency-contacts UI exists yet
/// per product scope) - kept purely for backend-readiness.
class MockEmergencyContactService implements EmergencyContactService {
  final List<EmergencyContact> _contacts = [];

  @override
  Future<List<EmergencyContact>> getContacts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_contacts);
  }

  @override
  Future<void> saveContact(EmergencyContact contact) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _contacts.removeWhere((c) => c.id == contact.id);
    _contacts.add(contact);
  }

  @override
  Future<void> deleteContact(String contactId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _contacts.removeWhere((c) => c.id == contactId);
  }
}
