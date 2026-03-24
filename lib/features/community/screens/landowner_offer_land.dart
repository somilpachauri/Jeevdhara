
import 'package:flutter/material.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/utils/location_service.dart';
import '../logic/community_repository.dart';

class LandownerOfferLand extends StatefulWidget {
  const LandownerOfferLand({super.key});

  @override
  State<LandownerOfferLand> createState() => _LandownerOfferLandState();
}

class _LandownerOfferLandState extends State<LandownerOfferLand> {
  final _areaController = TextEditingController();
  final _locationController = TextEditingController();

  final LocationService _locationService = LocationService();
  final CommunityRepository _communityRepository = CommunityRepository();

  double? _latitude;
  double? _longitude;

  bool _isLoading = false;
  bool _isFetchingLocation = false;

  @override
  void dispose() {
    _areaController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final result = await _locationService.getCurrentLocationDetails();
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationController.text = "${result.street}, ${result.city}";
      });
    } catch (e) {
      _showSnackBar('Location Error: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _submitOffer() async {
    if (_areaController.text.isEmpty || _locationController.text.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      if (_latitude == null || _longitude == null) {
        final pos = await _locationService.getCoordinatesFromAddress(_locationController.text.trim());
        if (pos != null) {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        }
      }

      await _communityRepository.addLandOffer(
        areaSize: _areaController.text.trim(),
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (mounted) {
        _showSnackBar('Land offered successfully! 🌍');
        Navigator.pop(context);
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
                border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Icon(Icons.landscape, size: 60, color: colorScheme.secondary),
                  const SizedBox(height: 24),

                  CustomTextField(
                    controller: _areaController,
                    labelText: 'Land Area (e.g., 200 Sq Foot)',
                    prefixIcon: Icons.square_foot,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _locationController,
                    labelText: 'Exact Location / Address',
                    prefixIcon: Icons.location_on,
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                      icon: _isFetchingLocation
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.my_location, color: colorScheme.secondary),
                      label: Text(
                        _isFetchingLocation ? "Fetching GPS..." : "Auto-Detect My Location",
                        style: TextStyle(color: colorScheme.secondary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          : const Text('Submit Land Offer', style: TextStyle(fontSize: 18)),
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