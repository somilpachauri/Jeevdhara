import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; 
import '../../home/repositories/home_repository.dart';
import 'feed_card.dart';

class FeedGrid extends StatelessWidget {
  final String collectionPath;
  final IconData icon;
  final String searchQuery;
  final String sortOption;
  final double? userLat;
  final double? userLng;

  final HomeRepository _repository = HomeRepository();

  FeedGrid({
    super.key,
    required this.collectionPath,
    required this.icon,
    required this.searchQuery,
    required this.sortOption,
    this.userLat,
    this.userLng,
  });

  void _handleToggleJoin(BuildContext context, String docId, bool isAlreadyJoined) async {
    try {
      await _repository.toggleJoinDrive(
        collectionPath: collectionPath,
        docId: docId,
        isAlreadyJoined: isAlreadyJoined,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAlreadyJoined ? 'You have left the drive.' : 'Successfully signed up! 🌿')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isLand = collectionPath == 'land_offers';
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _repository.getFeedStream(collectionPath),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> docs = _repository.filterAndSortDocs(
          docs: snapshot.data!.docs,
          searchQuery: searchQuery,
          sortOption: sortOption,
          isLand: isLand,
          userLat: userLat,
          userLng: userLng,
        );

        if (!isLand) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['driveDate'] == null && data['date'] == null) return true; 
            
            Timestamp? stamp = data['driveDate'] ?? data['date'];
            if (stamp == null) return true;

            final dt = stamp.toDate();
            final driveDay = DateTime(dt.year, dt.month, dt.day);
            
            return !driveDay.isBefore(today);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(child: Text("No results found.", style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            bool isCompany = data['type'] == 'company';
            List<dynamic> participants = data['participants'] ?? [];
            bool hasJoined = participants.contains(currentUserUid);

            String dateString = "Date TBD";
            if (!isLand) {
              if (data['driveDate'] != null) {
                DateTime dt = (data['driveDate'] as Timestamp).toDate();
                dateString = "${dt.day}/${dt.month}/${dt.year}";
              } else if (data['date'] != null) {
                DateTime dt = (data['date'] as Timestamp).toDate();
                dateString = "${dt.day}/${dt.month}/${dt.year}";
              } else if (isCompany) {
                dateString = "Ongoing CSR Initiative";
              }
            }

            String distanceText = "";
            if (userLat != null && data['latitude'] != null) {
              double d = Geolocator.distanceBetween(userLat!, userLng!, data['latitude'], data['longitude']);
              distanceText = " • ${(d / 1000).toStringAsFixed(1)} km";
            }

            String areaString = "";
            if (isLand && data['areaSize'] != null) {
              String rawArea = data['areaSize'].toString();
              areaString = rawArea.toLowerCase().contains(RegExp(r'[a-z]')) ? rawArea : "$rawArea sq feet";
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800), 
                child: FeedCard(
                  data: data,
                  isLand: isLand,
                  isCompany: isCompany,
                  distanceText: distanceText,
                  dateString: dateString,
                  areaString: areaString,
                  participantCount: participants.length,
                  hasJoined: hasJoined,
                  icon: icon,
                  onToggleJoin: () => _handleToggleJoin(context, doc.id, hasJoined),
                ),
              ),
            );
          },
        );
      },
    );
  }
}