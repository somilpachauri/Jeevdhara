
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logic/ai_repository.dart';

class AiScannerScreen extends StatefulWidget {
  const AiScannerScreen({super.key});

  @override
  State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen> {
  final AiRepository _aiRepository = AiRepository();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;

  final List<String> _availableRegions = [
    'none', 'Bihar', 'Himachal Pradesh', 'Punjab', 'Uttarakhand', 'West Bengal'
  ];

  String? _selectedRegion = 'none';
  String _selectedLanguage = 'english';

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _analysisResult = null;
        });
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  Future<void> _analyzeBiodiversity() async {
    if (_imageBytes == null) {
      _showSnackBar('Please select an image.');
      return;
    }
    await _sendToBackend(includeImage: true);
  }

  Future<void> _exploreCityOnly() async {
    if (_selectedRegion == null || _selectedRegion == 'none') {
      _showSnackBar('Please select a specific region first.');
      return;
    }
    setState(() => _imageBytes = null);
    await _sendToBackend(includeImage: false);
  }

  Future<void> _sendToBackend({required bool includeImage}) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final username = user?.email?.split('@')[0] ?? "Anonymous";

      final result = await _aiRepository.analyzeBiodiversity(
        username: username,
        language: _selectedLanguage,
        selectedCity: _selectedRegion!,
        imageBytes: _imageBytes,
        includeImage: includeImage,
      );

      if (mounted) setState(() => _analysisResult = result);
      
    } catch (e) {
      _showSnackBar(e.toString());
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

    final Map<String, dynamic> bio = _analysisResult?['biodiversity_analysis'] is Map ? _analysisResult!['biodiversity_analysis'] : {};
    final Map<String, dynamic> loc = _analysisResult?['location_context'] is Map ? _analysisResult!['location_context'] : {};
    final Map<String, dynamic> gam = _analysisResult?['gamification'] is Map ? _analysisResult!['gamification'] : {};
    
    final rawPoints = gam['points'];
    int points = 0;
    if (rawPoints is int) points = rawPoints;
    if (rawPoints is String) points = int.tryParse(rawPoints) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text("AI & Eco-Explorer")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3), width: 2),
                      image: _imageBytes != null ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover) : null,
                    ),
                    child: _imageBytes == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 50, color: colorScheme.secondary),
                              const SizedBox(height: 16),
                              const Text("Tap to Capture or Upload Species", style: TextStyle(fontSize: 16)),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedRegion,
                        dropdownColor: theme.cardTheme.color ?? colorScheme.surface,
                        decoration: InputDecoration(
                          labelText: 'Select State / Region',
                          prefixIcon: Icon(Icons.location_on, color: colorScheme.secondary),
                          filled: true,
                          fillColor: theme.cardTheme.color ?? colorScheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: _availableRegions.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                        onChanged: (val) => setState(() => _selectedRegion = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedLanguage,
                        dropdownColor: theme.cardTheme.color ?? colorScheme.surface,
                        decoration: InputDecoration(
                          labelText: 'Lang',
                          filled: true,
                          fillColor: theme.cardTheme.color ?? colorScheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'english', child: Text("EN")),
                          DropdownMenuItem(value: 'hindi', child: Text("HI")),
                          DropdownMenuItem(value: 'urdu', child: Text("UR")),
                          DropdownMenuItem(value: 'marathi', child: Text("MR")),
                          DropdownMenuItem(value: 'tamil', child: Text("TM")),
                        ],
                        onChanged: (val) => setState(() => _selectedLanguage = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _exploreCityOnly,
                        icon: const Icon(Icons.travel_explore),
                        label: const Text("City Data Only"),
                        style: OutlinedButton.styleFrom(
                          // --- NEW: FIX VISIBILITY ISSUE FOR THE BUTTON ---
                          foregroundColor: colorScheme.onSurface, 
                          side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _analyzeBiodiversity,
                        icon: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.document_scanner),
                        label: const Text("AI Species Scan"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_analysisResult != null) ...[
                  const SizedBox(height: 40),

                  if (bio['is_stock_photo'] == true)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Stock Image Detected", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  bio['stock_photo_reason'] ?? "Points cannot be awarded for non-original photos.",
                                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (bio.isNotEmpty) ...[
                    Text("AI Vision Results", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: theme.cardTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        leading: const Icon(Icons.biotech, color: Colors.green),
                        title: Text(
                          bio['species'] ?? bio['common name'] ?? 'Unknown Species',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          bio['scientific_name'] ?? '',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow("Common Name", bio['common name'], colorScheme),
                                _buildDetailRow("Category", bio['ecological_category'], colorScheme),
                                _buildDetailRow("Threat Level", bio['threat_level'], colorScheme, isAlert: true),
                                _buildDetailRow("Rarity Score", bio['rarity_score'] != null ? "${bio['rarity_score']}/10" : null, colorScheme),
                                _buildDetailRow(
                                  "Planting Suited",
                                  bio['suitability_for_reforestation'] == true ? "Yes ✅" : "No ❌",
                                  colorScheme,
                                ),
                                if (bio['legal_status'] != null)
                                  _buildDetailRow("Legal Status", bio['legal_status'], colorScheme),
                                const SizedBox(height: 12),
                                const Text("Action Plan:", style: TextStyle(fontWeight: FontWeight.bold)),
                                ...(bio['immediate_action_steps'] is List ? bio['immediate_action_steps'] as List : []).map(
                                  (step) => Padding(padding: const EdgeInsets.only(top: 4.0), child: Text("• $step")),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (loc.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      "${_selectedRegion == 'none' ? 'Local' : _selectedRegion} Ecosystem Report",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.secondary),
                    ),
                    const SizedBox(height: 12),

                    if (loc['assigned_park'] != null && loc['assigned_park'] is Map)
                      _buildInfoCard(
                        title: "Nearby Protected Area",
                        icon: Icons.terrain, color: Colors.green,
                        data: loc['assigned_park'],
                        mainKey: 'forestName', subKey: 'forestType',
                        extraInfo: "Risk: ${loc['assigned_park']['deforestationRisk'] ?? 'Unknown'}",
                        colorScheme: colorScheme,
                      ),

                    if (loc['assigned_department'] != null && loc['assigned_department'] is Map)
                      _buildInfoCard(
                        title: "Authority Contact",
                        icon: Icons.account_balance, color: Colors.blueGrey,
                        data: loc['assigned_department'],
                        mainKey: 'divisionName', subKey: 'circle',
                        extraInfo: "District: ${loc['assigned_department']['district'] ?? 'Unknown'}",
                        colorScheme: colorScheme,
                      ),

                    _buildExpansionMenu(
                      title: "Endangered Fauna", icon: Icons.pets, iconColor: Colors.orange,
                      items: loc['local_endangered_fauna'],
                      theme: theme, colorScheme: colorScheme,
                    ),
                    _buildExpansionMenu(
                      title: "Endangered Flora", icon: Icons.local_florist, iconColor: Colors.pink,
                      items: loc['local_endangered_flora'],
                      theme: theme, colorScheme: colorScheme,
                    ),
                    _buildExpansionMenu(
                      title: "Degraded Lands", icon: Icons.landscape, iconColor: Colors.brown,
                      items: loc['nearby_degraded_lands'],
                      theme: theme, colorScheme: colorScheme, isLand: true,
                    ),
                    _buildExpansionMenu(
                      title: "Active Local NGOs", icon: Icons.groups, iconColor: Colors.blue,
                      items: loc['nearby_ngos'],
                      theme: theme, colorScheme: colorScheme, isNgo: true,
                    ),
                  ],

                  if (gam.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: points > 0 
                            ? [Colors.amber.shade600, Colors.orange.shade700]
                            : [Colors.grey.shade600, Colors.grey.shade800],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            points > 0 ? Icons.workspace_premium : Icons.info_outline, 
                            color: Colors.white, size: 45
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  points > 0 ? "Rank Updated!" : "No Points Awarded", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)
                                ),
                                Text(
                                  gam['message'] ?? "",
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title, required IconData icon, required Color color,
    required Map<String, dynamic> data, required String mainKey, required String subKey,
    required String extraInfo, required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          leading: Icon(icon, color: color, size: 30),
          title: Text(title, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data[mainKey] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(data[subKey] ?? '', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Text(extraInfo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.secondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value, ColorScheme colorScheme, {bool isAlert = false}) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value.toString(), style: TextStyle(color: isAlert ? Colors.redAccent : colorScheme.onSurface))),
        ],
      ),
    );
  }

  Widget _buildExpansionMenu({
    required String title, required IconData icon, required Color iconColor,
    required dynamic items, required ThemeData theme, required ColorScheme colorScheme,
    bool isLand = false, bool isNgo = false,
  }) {
    List<dynamic> itemList = items is List ? items : [];
    if (itemList.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 0, color: theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: ExpansionTile(
          leading: Icon(icon, color: iconColor),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: itemList.map((item) {
            String name = "Unknown"; String sub = "";
            if (isLand) {
              name = item['landName'] ?? item['nearbyForest'] ?? "Land Parcel";
              sub = "Area: ${item['areaAcres'] ?? item['areaSize'] ?? 'Unknown'} Acres";
            } else if (isNgo) {
              name = item['ngoName'] ?? "NGO";
              sub = "Focus: ${item['focus'] ?? 'Conservation'}";
            } else {
              name = item['commonName'] ?? item['scientificName'] ?? "Species";
              sub = "Status: ${item['conservationStatus'] ?? item['category'] ?? 'Unknown'}";
            }
            return ListTile(title: Text(name), subtitle: Text(sub));
          }).toList(),
        ),
      ),
    );
  }
}