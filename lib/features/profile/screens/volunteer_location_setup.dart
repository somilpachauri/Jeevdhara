// lib/features/profile/screens/volunteer_location_setup.dart

import 'package:flutter/material.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/utils/location_service.dart';
import '../logic/profile_repository.dart';

class VolunteerLocationSetup extends StatefulWidget {
  const VolunteerLocationSetup({super.key});

  @override
  State<VolunteerLocationSetup> createState() => _VolunteerLocationSetupState();
}

class _VolunteerLocationSetupState extends State<VolunteerLocationSetup> {
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  final LocationService _locationService = LocationService();
  final ProfileRepository _profileRepository = ProfileRepository();

  bool _isLoading = false;
  bool _isFetchingGPS = false;

  @override
  void dispose() {
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _useGPSLocation() async {
    setState(() => _isFetchingGPS = true);
    try {
      final result = await _locationService.getCurrentLocationDetails();
      setState(() {
        _cityController.text = result.city;
        _stateController.text = result.state;
      });
    } catch (e) {
      _showSnackBar('GPS Error: $e');
    } finally {
      if (mounted) setState(() => _isFetchingGPS = false);
    }
  }

  Future<void> _savePreferences() async {
    if (_cityController.text.isEmpty || _stateController.text.isEmpty) {
      _showSnackBar('Please enter City and State');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Convert their typed text into coordinates using our service
      double? lat;
      double? lng;
      
      final pos = await _locationService.getCoordinatesFromAddress(
        "${_cityController.text}, ${_stateController.text}"
      );
      
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
      }

      // Save via Clean Repository
      await _profileRepository.saveProfileLocation(
        _stateController.text.trim(),
        _cityController.text.trim(),
        lat: lat,
        lng: lng,
      );

      if (mounted) {
        _showSnackBar('Preferences Saved!');
        Navigator.pop(context); // Go back to feed
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                Icon(Icons.map_outlined, size: 80, color: colorScheme.secondary),
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
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: Colors.white),
                  label: const Text("Use My Current Location", style: TextStyle(color: Colors.white, fontSize: 16)),
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
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                ),

                // --- REUSABLE WIDGETS ---
                CustomTextField(
                  controller: _cityController,
                  labelText: 'City (e.g., Dehradun)',
                  prefixIcon: Icons.location_city,
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _stateController,
                  labelText: 'State (e.g., Uttarakhand)',
                  prefixIcon: Icons.map,
                ),

                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Save Preferences", style: TextStyle(fontSize: 18)),
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