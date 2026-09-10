import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/device.dart';
import '../device_service.dart';

/// Firestore-backed implementation of [DeviceService].
///
/// Manages the `users/{uid}/devices/{deviceId}` subcollection.
class FirestoreDeviceService implements DeviceService {
  FirestoreDeviceService({
    required String userId,
    FirebaseFirestore? firestore,
  })  : _userId = userId,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final String _userId;
  final FirebaseFirestore _firestore;

  CollectionReference get _devicesCol =>
      _firestore.collection('users').doc(_userId).collection('devices');

  @override
  Future<List<Device>> getDevices() async {
    final snapshot = await _devicesCol.get();
    return snapshot.docs
        .map((doc) => Device.fromFirestore(doc, userId: _userId))
        .toList();
  }

  @override
  Future<Device?> getDevice(String deviceId) async {
    final doc = await _devicesCol.doc(deviceId).get();
    if (!doc.exists) return null;
    return Device.fromFirestore(doc, userId: _userId);
  }

  @override
  Future<void> reconnect(String deviceId) async {
    final docRef = _devicesCol.doc(deviceId);
    await docRef.update({
      'connection_status': 'connected',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
