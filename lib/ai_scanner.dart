import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'app_theme.dart';

class AiScannerScreen extends StatefulWidget {
  const AiScannerScreen({super.key});

  @override
  State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen> {
  XFile? _selectedImage;
  bool _isLoading = false;

  // --- WE NOW TRACK BOTH JSON FOLDERS ---
  Map<String, dynamic>? _analysisResult;
  Map<String, dynamic>? _locationContext;

  final TextEditingController _cityController = TextEditingController(
    text: "Dehradun",
  );
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
        _analysisResult = null;
        _locationContext =
            null; // Clear old location data when new image is picked
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    var uri = Uri.parse(
      'https://nonspottable-margo-tachygraphically.ngrok-free.dev/analyze-biodiversity',
    );
    var request = http.MultipartRequest('POST', uri);

    request.headers.addAll({'ngrok-skip-browser-warning': 'true'});

    request.fields['nearest_city'] = _cityController.text.trim();

    if (kIsWeb) {
      var bytes = await _selectedImage!.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'upload.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedImage!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          // --- UPDATED: Save both parts of the JSON ---
          _analysisResult = data['biodiversity_analysis'];
          _locationContext = data['location_context'];
        });
      } else if (response.statusCode == 429) {
        _showError("System busy, please wait 60 seconds.");
      } else {
        _showError("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Connection failed: Is the Ngrok server running?");
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _parseJsonData(dynamic data, {String fallback = 'N/A'}) {
    if (data == null) return fallback;
    if (data is List) {
      return data.join(', ');
    }
    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        title: const Text('AI Species Scanner'),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: darkGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: darkGreen, width: 2),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImage!.path,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_search, size: 60, color: darkGreen),
                        SizedBox(height: 8),
                        Text(
                          "Upload a photo of flora or fauna",
                          style: TextStyle(color: darkGreen, fontSize: 16),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                  style: ElevatedButton.styleFrom(backgroundColor: darkBrown),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _cityController,
              style: const TextStyle(color: darkGreen),
              decoration: InputDecoration(
                labelText: 'Nearest City (e.g., Dehradun, Rishikesh)',
                labelStyle: const TextStyle(color: darkGreen),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.location_city, color: darkGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading || _selectedImage == null
                    ? null
                    : _analyzeImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: harvestGold,
                  foregroundColor: darkGreen,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: darkGreen)
                    : const Text(
                        "Analyze Biodiversity",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            if (_analysisResult != null) _buildResultsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.eco, color: darkGreen, size: 28),
                SizedBox(width: 8),
                Text(
                  "AI Analysis Complete",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            const Divider(),

            _buildResultRow(
              "Species",
              _parseJsonData(_analysisResult?['species'], fallback: 'Unknown'),
            ),
            _buildResultRow(
              "Scientific Name",
              _parseJsonData(_analysisResult?['scientific_name']),
            ),
            _buildResultRow(
              "Legal Status",
              _parseJsonData(_analysisResult?['legal_status']),
            ),
            _buildResultRow(
              "Tree to Plant",
              _parseJsonData(_analysisResult?['reforestation_tree']),
            ),

            const SizedBox(height: 12),
            const Text(
              "Emergency Steps:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                fontSize: 16,
              ),
            ),
            Text(
              _parseJsonData(
                _analysisResult?['immediate_action_steps'],
                fallback: 'No immediate actions required.',
              ),
              style: const TextStyle(color: Colors.black87),
            ),

            const Divider(),

            const Text(
              "Local Authority Routing:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkGreen,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),

            // --- FIXED: Now pulls from _locationContext instead of _analysisResult ---
            _buildResultRow(
              "Assigned Park",
              _parseJsonData(
                _locationContext?['assigned_park']?['forestName'],
                fallback: 'Routing...',
              ),
            ),

            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: darkBrown, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      // --- FIXED: Pulls phone from _locationContext -> assigned_department ---
                      "Contact: ${_parseJsonData(_locationContext?['assigned_department']?['phone'])}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
