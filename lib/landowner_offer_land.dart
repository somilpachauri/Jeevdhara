import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';

class LandownerOfferLand extends StatefulWidget {
  const LandownerOfferLand({super.key});

  @override
  State<LandownerOfferLand> createState() => _LandownerOfferLandState();
}

class _LandownerOfferLandState extends State<LandownerOfferLand> {
  final _areaController = TextEditingController(); // e.g., 2 Acres
  final _locationController = TextEditingController(); // e.g., Near Mussoorie
  bool _isLoading = false;

  Future<void> _submitOffer() async {
    if (_areaController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Verification: Check if user is actually logged in
      if (user == null) {
        throw Exception("No user logged in");
      }

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('land_offers')
          .add({
            'ownerId': user.uid,
            'ownerEmail': user.email,
            'areaSize': _areaController.text.trim(),
            'location': _locationController.text.trim(),
            'status': 'available',
            'createdAt': FieldValue.serverTimestamp(),
          });

      print("Successfully added land offer with ID: ${docRef.id}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Land listed successfully!'),
            backgroundColor: darkGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Firestore Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to list land: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        title: const Text('Offer Your Land'),
        backgroundColor: darkGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.landscape, size: 50, color: darkBrown),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Exact Location',
                  ),
                ),
                TextField(
                  controller: _areaController,
                  decoration: const InputDecoration(
                    labelText: 'Area Size (e.g. 500 sq yards)',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitOffer,
                  style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("List My Land"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
