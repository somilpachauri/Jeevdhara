
import 'package:flutter/material.dart';
import '../../../core/utils/location_service.dart';
import '../logic/community_repository.dart';

class NgoRequestDrive extends StatefulWidget {
  const NgoRequestDrive({super.key});

  @override
  State<NgoRequestDrive> createState() => _NgoRequestDriveState();
}

class _NgoRequestDriveState extends State<NgoRequestDrive> {
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;

  final LocationService _locationService = LocationService();
  final CommunityRepository _communityRepository = CommunityRepository();

  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isFetchingGPS = false;

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingGPS = true);
    try {
      final result = await _locationService.getCurrentLocationDetails();
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _addressController.text = result.street;
        _cityController.text = result.city;
      });
    } catch (e) {
      _showSnackBar('GPS Error: $e');
    } finally {
      if (mounted) setState(() => _isFetchingGPS = false);
    }
  }

  Future<void> _submitDrive() async {
    if (_cityController.text.isEmpty || _descController.text.isEmpty || _selectedDate == null) {
      _showSnackBar('Please fill all fields and select a date');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      if (_latitude == null || _longitude == null) {
        final pos = await _locationService.getCoordinatesFromAddress(
            "${_addressController.text}, ${_cityController.text}");
        if (pos != null) {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        }
      }

      await _communityRepository.addPlantationDrive(
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        description: _descController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        roleType: 'ngo',
        driveDate: _selectedDate,
      );

      if (mounted) {
        _showSnackBar('Drive requested successfully! 🌱');
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

    InputDecoration buildInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
        labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        floatingLabelStyle: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.5), width: 2),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Organize Plantation Drive')),
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
                  Icon(Icons.park, size: 60, color: colorScheme.secondary),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _addressController,
                          style: TextStyle(color: colorScheme.onSurface),
                          cursorColor: colorScheme.secondary,
                          decoration: buildInputDecoration('Street Address'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _cityController,
                          style: TextStyle(color: colorScheme.onSurface),
                          cursorColor: colorScheme.secondary,
                          decoration: buildInputDecoration('City'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isFetchingGPS ? null : _getCurrentLocation,
                      icon: _isFetchingGPS
                          ? SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.secondary),
                            )
                          : Icon(Icons.my_location, color: colorScheme.secondary),
                      label: Text(
                        "Auto-Detect GPS",
                        style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.secondary,
                        side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _descController,
                    style: TextStyle(color: colorScheme.onSurface),
                    maxLines: 3,
                    cursorColor: colorScheme.secondary,
                    decoration: buildInputDecoration('Drive Details & Goals'),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    title: Text(
                      _selectedDate == null
                          ? 'Select Drive Date'
                          : 'Date: ${_selectedDate!.toLocal()}'.split(' ')[0],
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    trailing: Icon(Icons.calendar_today, color: colorScheme.secondary),
                    tileColor: colorScheme.onSurface.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: colorScheme.copyWith(
                                primary: colorScheme.secondary,
                                onPrimary: Colors.white,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: colorScheme.secondary,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitDrive,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Publish NGO Drive',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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