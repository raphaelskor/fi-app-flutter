import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client_address.dart';

class ClientAddressService {
  static const String _baseUrl =
      'https://n8n-sit.skorcard.app/webhook/aade8018-b9a9-429a-a25e-5816908cbe41';

  static Future<ClientAddressResponse> getClientAddresses(
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
        return ClientAddressResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to load client addresses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching client addresses: $e');
    }
  }
}
