import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  // 🔴 UPDATED: The exact live Ngrok URL
  static const String backendUrl =
      'https://nonspottable-margo-tachygraphically.ngrok-free.dev';

  static Future<List<dynamic>> fetchLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/leaderboard'),
        // MAGIC FIX 1: Bypass Ngrok warning for the leaderboard
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['top_contributors'] ?? [];
      } else {
        print(
          'Failed to load leaderboard. Status Code: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('API Error fetching leaderboard: $e');
      return [];
    }
  }

  static Map<String, dynamic> getUserStats(
    List<dynamic> leaderboard,
    String username,
  ) {
    for (var entry in leaderboard) {
      if (entry[0] == username) {
        return entry[1] as Map<String, dynamic>;
      }
    }
    return {"points": 0, "badges": [], "uploads": 0};
  }
}
