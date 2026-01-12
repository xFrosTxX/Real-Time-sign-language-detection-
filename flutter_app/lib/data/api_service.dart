import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // For Laptop running backend
  // static const String laptopBaseUrl = 'http://localhost:8000';

  // For Physical Android Device (use your PC’s IP)
  static const String baseUrl = 'http://192.168.1.78:8000';

/// Predict hand sign from image bytes
/// Returns the predicted label and confidence


  /// Predict hand sign from image bytes
  /// Returns the predicted label and confidence
  Future<Map<String, dynamic>> predictHandSign(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse('$baseUrl/predict');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'label': data['label'],
          'confidence': data['confidence'],
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }

  /// Check if the server is running
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}