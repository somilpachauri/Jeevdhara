// lib/features/profile/logic/leaderboard_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class LeaderboardRepository {
  
  // Fetch the leaderboard from the Python Backend
  Future<List<dynamic>> fetchLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.backendUrl}/leaderboard'),
        headers: {
          'Content-Type': 'application/json',
          // 'ngrok-skip-browser-warning': 'true', // You won't need this once off ngrok!
        },
      ).timeout(const Duration(seconds: 10)); // Added a timeout so the app doesn't hang forever

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['top_contributors'] ?? [];
      } else {
        throw Exception('Backend returned status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to Python backend: $e');
    }
  }

  // Extract specific user stats locally
  Map<String, dynamic> getUserStats(List<dynamic> leaderboard, String username) {
    for (var entry in leaderboard) {
      // entry[0] is the username, entry[1] is the stats map
      if (entry[0] == username) {
        return entry[1] as Map<String, dynamic>;
      }
    }
    // Return default empty stats if user isn't on the leaderboard yet
    return {
      "points": 0, 
      "badges": [], 
      "uploads": 0
    };
  }
}