
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class LeaderboardRepository {
  
  Future<List<dynamic>> fetchLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.backendUrl}/leaderboard'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

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

  Map<String, dynamic> getUserStats(List<dynamic> leaderboard, String username) {
    for (var entry in leaderboard) {
      if (entry[0] == username) {
        return entry[1] as Map<String, dynamic>;
      }
    }
    return {
      "points": 0, 
      "badges": [], 
      "uploads": 0
    };
  }
}