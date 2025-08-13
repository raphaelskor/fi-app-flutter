import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contact.dart';
import '../models/contactability.dart';

class ApiService {
  static const String baseUrl = 'https://your-api-url.com/api';
  
  // Get today's clients optimized by distance
  Future<List<Contact>> getTodaysClients() async {
    final response = await http.get(
      Uri.parse('$baseUrl/contacts/today'),
      headers: {'Authorization': 'Bearer ${await getToken()}'},
    );
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Contact.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load clients');
    }
  }
  
  // Create contactability record
  Future<void> createContactability(Contactability contactability) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contactability'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await getToken()}',
      },
      body: json.encode(contactability.toJson()),
    );
    
    if (response.statusCode != 201) {
      throw Exception('Failed to create contactability record');
    }
  }
  
  // Get contactability history
  Future<List<Contactability>> getContactabilityHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/contactability/history'),
      headers: {'Authorization': 'Bearer ${await getToken()}'},
    );
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Contactability.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load history');
    }
  }
  
  Future<String> getToken() async {
    // Implement token retrieval from secure storage
    return 'your-auth-token';
  }
}