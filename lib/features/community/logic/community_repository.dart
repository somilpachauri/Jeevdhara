
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

 Future<void> addPlantationDrive({
    required String address,
    required String city,
    required String description,
    required double? latitude,
    required double? longitude,
    required String roleType,
    DateTime? driveDate, 
    List<String>? resourcesProvided,
    bool openForCollab = false,
    String collabDetails = "",
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User must be logged in to post.");

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    
    String organizerName = 'Organizer';
    if (roleType == 'company') {
      organizerName = userDoc.data()?['companyName'] ?? 'Corporate Partner';
    } else if (roleType == 'ngo') {
      organizerName = userDoc.data()?['ngoName'] ?? 'NGO Partner'; 
    }

    await _firestore.collection('plantation_requests').add({
      'organizerId': user.uid,
      'organizerEmail': user.email,
      'companyName': organizerName,
      'type': roleType,
      'address': address,
      'city': city,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'driveDate': driveDate != null ? Timestamp.fromDate(driveDate) : null, // ADDED THIS
      'resourcesProvided': resourcesProvided ?? [],
      'openForCollab': openForCollab,
      'collabDetails': collabDetails,
      'participants': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  Future<void> addLandOffer({
    required String areaSize,
    required String location,
    required double? latitude,
    required double? longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User must be logged in to offer land.");

    await _firestore.collection('land_offers').add({
      'landownerId': user.uid,
      'landownerEmail': user.email,
      'areaSize': areaSize,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'available',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
}