import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'user.dart';

class AiScannerScreen extends StatefulWidget {
  const AiScannerScreen({super.key});

  @override
  State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen> {
  Uint8List? _imageBytes;
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _cityController = TextEditingController(
    text: 'Dehradun',
  );
  String _selectedLanguage = 'english';

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _analysisResult = null;
      });
    }
  }

  Future<void> _analyzeBiodiversity() async {
    if (_imageBytes == null || _cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image and enter a city.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final username = user?.email?.split('@')[0] ?? "Anonymous";

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${UserService.backendUrl}/analyze-biodiversity'),
      );

      request.headers.addAll({'ngrok-skip-browser-warning': 'true'});
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: 'scan.jpg',
        ),
      );

      request.fields['nearest_city'] = _cityController.text.trim();
      request.fields['username'] = username;
      request.fields['language'] = _selectedLanguage;

      // We explicitly request Gemini. Python will auto-fallback to Llama ONLY if Gemini fails.
      request.fields['model_choice'] = 'gemini';

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        setState(() {
          _analysisResult = json.decode(responseData);
        });
      } else if (response.statusCode == 429) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('System busy, please wait 60 seconds.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect. Is your Ngrok running?')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("AI Biodiversity Scanner")),
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
                    height: 300,
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.secondary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.secondary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      image: _imageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_imageBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageBytes == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.document_scanner_outlined,
                                  size: 50,
                                  color: colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Tap to Scan Flora/Fauna",
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _cityController,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Detected Region',
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: colorScheme.secondary,
                          ),
                          filled: true,
                          fillColor:
                              theme.cardTheme.color ?? colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedLanguage,
                        dropdownColor:
                            theme.cardTheme.color ?? colorScheme.surface,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Language',
                          filled: true,
                          fillColor:
                              theme.cardTheme.color ?? colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'english',
                            child: Text("English"),
                          ),
                          DropdownMenuItem(
                            value: 'hindi',
                            child: Text("Hindi"),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedLanguage = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _analyzeBiodiversity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(width: 16),
                              Text(
                                "AI Engines Processing...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Run Ecosystem Analysis",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                if (_analysisResult != null) ...[
                  const SizedBox(height: 48),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(
                          Icons.remove_red_eye,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          _analysisResult!['metadata']['vision_engine'] ??
                              'Vision AI',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: colorScheme.secondary,
                        side: BorderSide.none,
                      ),
                      Chip(
                        avatar: const Icon(
                          Icons.psychology,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          _analysisResult!['metadata']['reasoning_engine'] ??
                              'Reasoning AI',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.purple.shade400,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    "Species Overview",
                    Icons.biotech,
                    colorScheme,
                  ),
                  _buildDataCard(
                    [
                      _buildDataRow(
                        "Common Name",
                        _analysisResult!['biodiversity_analysis']['species']
                            ?.toString(),
                        colorScheme,
                      ),
                      _buildDataRow(
                        "Scientific Name",
                        _analysisResult!['biodiversity_analysis']['scientific_name']
                            ?.toString(),
                        colorScheme,
                        isItalic: true,
                      ),
                      _buildDataRow(
                        "Ecology Type",
                        _analysisResult!['biodiversity_analysis']['ecological_category']
                            ?.toString(),
                        colorScheme,
                      ),
                    ],
                    theme,
                    colorScheme,
                  ),

                  _buildSectionHeader(
                    "Threat Assessment",
                    Icons.warning_amber,
                    colorScheme,
                    isAlert: true,
                  ),
                  if (_analysisResult!['biodiversity_analysis']['requires_forest_guard_dispatch'] ==
                      true)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "EMERGENCY: Forest Guard Dispatch Required",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildDataCard(
                    [
                      _buildDataRow(
                        "Threat Level",
                        _analysisResult!['biodiversity_analysis']['threat_level']
                            ?.toString(),
                        colorScheme,
                        isAlert: true,
                      ),
                      _buildDataRow(
                        "Legal Status",
                        _analysisResult!['biodiversity_analysis']['legal_status']
                            ?.toString(),
                        colorScheme,
                      ),
                      _buildDataRow(
                        "Rarity Score",
                        "${_analysisResult!['biodiversity_analysis']['rarity_score']}/10",
                        colorScheme,
                      ),
                    ],
                    theme,
                    colorScheme,
                  ),

                  _buildSectionHeader(
                    "Action Plan",
                    Icons.format_list_bulleted,
                    colorScheme,
                  ),
                  _buildDataCard(
                    [
                      _buildDataRow(
                        "Reforestation Match",
                        _analysisResult!['biodiversity_analysis']['reforestation_tree']
                            ?.toString(),
                        colorScheme,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Immediate Action Steps:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_analysisResult!['biodiversity_analysis']['immediate_action_steps']
                                  as List<dynamic>? ??
                              [])
                          .map(
                            (step) => Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "• ",
                                    style: TextStyle(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      step.toString(),
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.8,
                                        ),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                    theme,
                    colorScheme,
                  ),

                  _buildSectionHeader(
                    "Assigned Department",
                    Icons.local_police,
                    colorScheme,
                  ),
                  _buildDataCard(
                    [
                      _buildDataRow(
                        "Park Context",
                        _analysisResult!['location_context']['assigned_park']?['forestName']
                            ?.toString(),
                        colorScheme,
                      ),
                      _buildDataRow(
                        "Dept. Name",
                        _analysisResult!['location_context']['assigned_department']?['name']
                            ?.toString(),
                        colorScheme,
                      ),
                      _buildDataRow(
                        "Emergency Phone",
                        _analysisResult!['location_context']['assigned_department']?['phone']
                            ?.toString(),
                        colorScheme,
                        isAlert: true,
                      ),
                      _buildDataRow(
                        "Address",
                        _analysisResult!['location_context']['assigned_department']?['address']
                            ?.toString(),
                        colorScheme,
                      ),
                    ],
                    theme,
                    colorScheme,
                  ),

                  // --- FIXED: PREMIUM GAMIFICATION CARD ---
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade600, Colors.orange.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            color: Colors.white,
                            size: 45,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Gamification Unlocked!",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "+${_analysisResult!['gamification']['points']} Points Added",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Current Rank: ${_analysisResult!['gamification']['rank']}",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    ColorScheme colorScheme, {
    bool isAlert = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
      child: Row(
        children: [
          Icon(icon, color: isAlert ? Colors.redAccent : colorScheme.secondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(
    List<Widget> children,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String? value,
    ColorScheme colorScheme, {
    bool isItalic = false,
    bool isAlert = false,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isAlert ? Colors.redAccent : colorScheme.onSurface,
                fontWeight: isAlert ? FontWeight.bold : FontWeight.w500,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
