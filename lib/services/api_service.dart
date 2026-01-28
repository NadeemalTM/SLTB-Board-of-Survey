import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import '../data/models/asset_model.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      // ---------------------------------------------------------
      // FOR CHROME (WEB)
      // Apache default port is 80 (no need to specify port)
      // If using different port like 8080, change to: http://localhost:8080/api
      // ---------------------------------------------------------
      return "http://localhost/api"; 
    } else {
      // FOR ANDROID PHONE
      // Use your computer's IP address where XAMPP is running
      // Port 80 is default for Apache (don't need to specify)
      return "http://172.20.10.3/api"; 
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

  /// Save asset to MySQL database
  /// Returns true if saved successfully, false otherwise
  static Future<bool> saveAssetToMySql(AssetModel asset) async {
    try {
      // Extract just the filename from the image path (temporary solution)
      String? image1Name = _extractFileName(asset.imagePath1);
      String? image2Name = _extractFileName(asset.imagePath2);
      String? image3Name = _extractFileName(asset.imagePath3);

      final Map<String, dynamic> assetData = {
        'serial_no': asset.serialNo,
        'description': asset.description,
        'old_code': asset.oldCode,
        'new_code': asset.newCode,
        'book_balance': asset.bookBalance,
        'physical_balance': asset.physicalBalance,
        'excess': asset.excess,
        'shortage': asset.shortage,
        'remarks': asset.remarks,
        'survey_status': asset.surveyStatus,
        'image_path_1': image1Name, // Store just the image filename
        'image_path_2': image2Name,
        'image_path_3': image3Name,
        'entered_by': asset.enteredBy,
        'entered_date': asset.enteredDate,
        'verified_by': asset.verifiedBy,
        'verified_date': asset.verifiedDate,
        'verification_status': asset.verificationStatus,
        'last_updated_by': asset.lastUpdatedBy,
        'last_updated_date': asset.lastUpdatedDate,
        'is_new_item': asset.isNewItem,
      };

      debugPrint('Sending to: $baseUrl/save_asset.php');
      debugPrint('Data: ${jsonEncode(assetData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/save_asset.php'),
        body: jsonEncode(assetData),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      debugPrint('Failed with status code: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error saving asset to MySQL: $e');
      return false;
    }
  }

  /// Extract filename from full path
  /// e.g., "/data/user/0/com.example/cache/image_123.jpg" -> "image_123.jpg"
  static String? _extractFileName(String? path) {
    if (path == null || path.isEmpty) return null;
    // Get the filename from the path
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : null;
  }
}