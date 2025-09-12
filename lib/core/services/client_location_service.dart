import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client_location.dart';

class ClientLocationService {
  static const String _baseUrl =
      'https://n8n-sit.skorcard.app/webhook/f811b60c-4f72-4872-ab99-80ddac180bd0';

  static Future<ClientLocationResponse> getClientLocationHistory(
      String skorUserId) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'skor_user_id': skorUserId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ClientLocationResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to load location history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching location history: $e');
    }
  }
}
