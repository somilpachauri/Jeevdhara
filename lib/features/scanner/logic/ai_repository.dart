// lib/features/scanner/logic/ai_repository.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class AiRepository {
  Future<Map<String, dynamic>?> analyzeBiodiversity({
    required String username,
    required String language,
    required String selectedCity,
    Uint8List? imageBytes,
    bool includeImage = true,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.backendUrl}/analyze-biodiversity'),
      );
      
      // Keep this for now if you are still temporarily using ngrok
      request.headers.addAll({'ngrok-skip-browser-warning': 'true'});

      if (includeImage && imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'scan.jpg',
          ),
        );
      }

      if (selectedCity != 'none') {
        request.fields['nearest_city'] = selectedCity;
      }
      
      request.fields['username'] = username;
      request.fields['language'] = language;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection failed. Is the backend running? Error: $e');
    }
  }
}