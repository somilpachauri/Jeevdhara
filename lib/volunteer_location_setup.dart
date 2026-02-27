import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class VolunteerLocationSetup extends StatefulWidget {
  const VolunteerLocationSetup({super.key});

  @override
  State<VolunteerLocationSetup> createState() => _VolunteerLocationSetupState();
}

class _VolunteerLocationSetupState extends State<VolunteerLocationSetup> {
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isLoading = false;
  bool _isFetchingGPS = false;

  // --- OPTION 1: AUTO GPS ---
  Future<void> _useGPSLocation() async {
    setState(() => _isFetchingGPS = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() {
          // Fill in just the City and State for privacy
          _cityController.text = placemarks.first.locality ?? '';
          _stateController.text = placemarks.first.administrativeArea ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('GPS Error: $e')));
      }
    } finally {
      setState(() => _isFetchingGPS = false);
    }
  }

  // --- OPTION 2: MANUAL ENTRY TO COORDINATES ---
  Future<void> _savePreferences() async {
    if (_cityController.text.isEmpty || _stateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter City and State')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // FORWARD GEOCODING: Turn their typed text into coordinates!
      double? lat;
      double? lng;
      try {
        List<Location> locations = await locationFromAddress(
          "${_cityController.text}, ${_stateController.text}",
        );
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
        }
      } catch (e) {
        print(
          "Could not exact match the city to coordinates, but saving text anyway.",
        );
      }

      final user = FirebaseAuth.instance.currentUser;
      // Save this to their User Profile document in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
        'preferredCity': _cityController.text.trim(),
        'preferredState': _stateController.text.trim(),
        'searchLatitude': lat,
        'searchLongitude': lng,
        'role': 'volunteer', // Ensures role is maintained
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Preferences Saved!')));
        Navigator.pop(context); // Go back to feed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Set Region Preferences')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.map_outlined,
                  size: 80,
                  color: colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  "Where do you want to help?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  "We use this to show you nearby plantation drives.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 40),

                // Auto GPS Button
                ElevatedButton.icon(
                  onPressed: _isFetchingGPS ? null : _useGPSLocation,
                  icon: _isFetchingGPS
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.my_location, color: Colors.white),
                  label: const Text(
                    "Use My Current Location",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "OR ENTER MANUALLY",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                // Manual Text Fields
                TextField(
                  controller: _cityController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'City (e.g., Dehradun)',
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _stateController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'State (e.g., Uttarakhand)',
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Save Preferences",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
