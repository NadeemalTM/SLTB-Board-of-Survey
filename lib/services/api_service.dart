import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Needed for kIsWeb

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      // ---------------------------------------------------------
      // FOR CHROME (WEB)
      // Check your XAMPP Port! If Apache is on port 80, remove ":3307"
      // ---------------------------------------------------------
      return "http://localhost:3307/api"; 
    } else {
      // FOR ANDROID PHONE
      return "http://172.20.10.3:3307/api"; 
    }
  }

  static Future<List<dynamic>> fetchAllAssets() async {
    try {
      // For Web, we sometimes need to bypass browser caching
      final uri = Uri.parse('$baseUrl/sync.php?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection Failed: $e');
    }
  }

  static Future<bool> uploadChanges(List<Map<String, dynamic>> offlineChanges) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync.php'),
        body: jsonEncode({"updates": offlineChanges}), 
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          // These headers help prevent CORS errors on Web
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Headers": "Access-Control-Allow-Origin, Accept",
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}