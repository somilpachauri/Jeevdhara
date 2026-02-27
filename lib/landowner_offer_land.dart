import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LandownerOfferLand extends StatefulWidget {
  const LandownerOfferLand({super.key});

  @override
  State<LandownerOfferLand> createState() => _LandownerOfferLandState();
}

class _LandownerOfferLandState extends State<LandownerOfferLand> {
  final _areaController = TextEditingController();
  final _locationController =
      TextEditingController(); // Stores the reverse-geocoded address

  // Storing the exact math coordinates for Geohashing later
  double? _latitude;
  double? _longitude;

  bool _isLoading = false;
  bool _isFetchingLocation = false;

  // --- NATIVE REVERSE GEOCODING LOGIC ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      // 1. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // 2. Get Exact GPS Coordinates
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _latitude = position.latitude;
      _longitude = position.longitude;

      // 3. Reverse Geocode into a readable address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          // Auto-fills the text field with a beautiful address string
          _locationController.text =
              "${place.street}, ${place.locality}, ${place.administrativeArea}";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location Error: $e')));
      }
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

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
      await FirebaseFirestore.instance.collection('land_offers').add({
        'landownerId': user?.uid,
        'landownerEmail': user?.email,
        'areaSize': _areaController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': _latitude, // Saves exact coordinates for Geohashing!
        'longitude': _longitude,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Land offered successfully! 🌍')),
        );
        Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Offer Land for Reforestation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.landscape, size: 60, color: colorScheme.secondary),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _areaController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Land Area (e.g., 2 Acres)',
                      filled: true,
                      fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Text Field
                  TextField(
                    controller: _locationController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Exact Location / Address',
                      filled: true,
                      fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- THE MAGIC GPS BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isFetchingLocation
                          ? null
                          : _getCurrentLocation,
                      icon: _isFetchingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.my_location,
                              color: colorScheme.secondary,
                            ),
                      label: Text(
                        _isFetchingLocation
                            ? "Fetching GPS..."
                            : "Auto-Detect My Location",
                        style: TextStyle(color: colorScheme.secondary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: colorScheme.secondary.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitOffer,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit Land Offer',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
