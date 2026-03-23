// lib/features/profile/logic/profile_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Fetch current user data
  Future<Map<String, dynamic>?> fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
    }
    return null;
  }

  // 2. Fetch Corporate Impact (Drives hosted & total volunteers)
  Future<Map<String, int>> fetchCorporateImpact() async {
    final user = _auth.currentUser;
    if (user == null) return {'drives': 0, 'volunteers': 0};

    final drives = await _firestore
        .collection('plantation_requests')
        .where('organizerId', isEqualTo: user.uid)
        .get();

    int realVolunteerCount = 0;
    for (var doc in drives.docs) {
      List<dynamic> participants = doc.data()['participants'] ?? [];
      realVolunteerCount += participants.length;
    }

    return {
      'drives': drives.docs.length,
      'volunteers': realVolunteerCount,
    };
  }

  // 3. Save preferred location
Future<void> saveProfileLocation(String state, String city, {double? lat, double? lng}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in.");

    Map<String, dynamic> dataToSave = {
      'preferredState': state,
      'preferredCity': city,
    };
    
    if (lat != null) dataToSave['searchLatitude'] = lat;
    if (lng != null) dataToSave['searchLongitude'] = lng;

    await _firestore.collection('users').doc(user.uid).set(dataToSave, SetOptions(merge: true));
  }
  Future<void> logout() async {
    await _auth.signOut();
  }
}