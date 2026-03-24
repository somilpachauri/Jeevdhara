
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class HomeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getFeedStream(String collectionPath) {
    return _firestore.collection(collectionPath).snapshots();
  }

  Future<void> toggleJoinDrive({
    required String collectionPath,
    required String docId,
    required bool isAlreadyJoined,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final docRef = _firestore.collection(collectionPath).doc(docId);

    if (isAlreadyJoined) {
      await docRef.update({
        'participants': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await docRef.update({
        'participants': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  List<QueryDocumentSnapshot> filterAndSortDocs({
    required List<QueryDocumentSnapshot> docs,
    required String searchQuery,
    required String sortOption,
    required bool isLand,
    double? userLat,
    double? userLng,
  }) {
    List<QueryDocumentSnapshot> filteredDocs = List.from(docs);

    if (searchQuery.isNotEmpty) {
      filteredDocs = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final searchField = isLand ? data['location'] : data['city'];
        return searchField.toString().toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    filteredDocs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      if (sortOption == 'distance' && userLat != null && userLng != null) {
        double distA = Geolocator.distanceBetween(
            userLat, userLng, dataA['latitude'] ?? 0, dataA['longitude'] ?? 0);
        double distB = Geolocator.distanceBetween(
            userLat, userLng, dataB['latitude'] ?? 0, dataB['longitude'] ?? 0);
        return distA.compareTo(distB);
      } else if (sortOption == 'date_asc') {
        return (dataA['createdAt'] as Timestamp? ?? Timestamp.now())
            .compareTo(dataB['createdAt'] as Timestamp? ?? Timestamp.now());
      }
      return (dataB['createdAt'] as Timestamp? ?? Timestamp.now())
          .compareTo(dataA['createdAt'] as Timestamp? ?? Timestamp.now());
    });

    return filteredDocs;
  }
}