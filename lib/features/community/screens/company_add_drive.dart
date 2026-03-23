// lib/features/community/screens/company_add_drive.dart

import 'package:flutter/material.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/utils/location_service.dart';
import '../logic/community_repository.dart';

class CompanyAddDrive extends StatefulWidget {
  const CompanyAddDrive({super.key});

  @override
  State<CompanyAddDrive> createState() => _CompanyAddDriveState();
}

class _CompanyAddDriveState extends State<CompanyAddDrive> {
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _descController = TextEditingController();
  final _collabDetailsController = TextEditingController();

  final LocationService _locationService = LocationService();
  final CommunityRepository _communityRepository = CommunityRepository();

  bool _isLoading = false;
  bool _isFetchingGPS = false;
  bool _openForCollab = false;

  double? _latitude;
  double? _longitude;

  final Map<String, bool> _resources = {
    'Refreshments': false,
    'Seeds & Saplings': false,
    'Tools/Machinery': false,
    'Transport': false,
  };

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _descController.dispose();
    _collabDetailsController.dispose();
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
    if (_cityController.text.isEmpty || _addressController.text.isEmpty) {
      _showSnackBar('Please fill Address and City');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Handle manual address entry if GPS wasn't used
      if (_latitude == null || _longitude == null) {
        final pos = await _locationService.getCoordinatesFromAddress(
            "${_addressController.text}, ${_cityController.text}");
        if (pos != null) {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        }
      }

      List<String> providedResources = _resources.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      // Use the Clean Repository
      await _communityRepository.addPlantationDrive(
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        description: _descController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        roleType: 'company',
        resourcesProvided: providedResources,
        openForCollab: _openForCollab,
        collabDetails: _openForCollab ? _collabDetailsController.text.trim() : "",
      );

      if (mounted) {
        _showSnackBar('Corporate Drive Posted Successfully!');
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
      appBar: AppBar(title: const Text('Host a Corporate Drive')),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(Icons.business_center, size: 60, color: colorScheme.secondary),
                  ),
                  const SizedBox(height: 24),

                  // Location Controls utilizing CustomTextField
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          controller: _addressController,
                          labelText: 'Street Address',
                          prefixIcon: Icons.home,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: CustomTextField(
                          controller: _cityController,
                          labelText: 'City',
                          prefixIcon: Icons.location_city,
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
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: const Text("Auto-Detect GPS"),
                      style: OutlinedButton.styleFrom(
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
                    decoration: InputDecoration(
                      labelText: 'Drive Details & Goals',
                      filled: true,
                      fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resources
                  Text(
                    "Resources Provided by Company",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _resources.keys.map((String key) => FilterChip(
                      label: Text(key),
                      selected: _resources[key]!,
                      selectedColor: colorScheme.secondary.withValues(alpha: 0.3),
                      checkmarkColor: colorScheme.secondary,
                      onSelected: (bool value) => setState(() => _resources[key] = value),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Collab
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text("Open for CSR Collaboration?"),
                          subtitle: const Text("Allow other companies to join."),
                          value: _openForCollab,
                          activeThumbColor: colorScheme.primary,
                          onChanged: (val) => setState(() => _openForCollab = val),
                        ),
                        if (_openForCollab) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _collabDetailsController,
                            style: TextStyle(color: colorScheme.onSurface),
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'What extra resources do you need?',
                              filled: true,
                              fillColor: colorScheme.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitDrive,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Publish Corporate Drive", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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