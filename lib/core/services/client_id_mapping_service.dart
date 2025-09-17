import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Service to manage mapping between Client ID and Skor User ID
/// This is crucial for navigation from All Client Location screen to Client Details
class ClientIdMappingService {
  static ClientIdMappingService? _instance;
  static ClientIdMappingService get instance {
    _instance ??= ClientIdMappingService._internal();
    return _instance!;
  }

  ClientIdMappingService._internal();

  static const String _mappingKey = 'client_id_mapping';

  /// Store mapping from contactability data: skorUserId -> clientId
  Future<void> storeClientIdMapping(Map<String, String> mappings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear existing mappings first to ensure clean slate
      await prefs.remove(_mappingKey);

      // Save new mappings
      await prefs.setString(_mappingKey, jsonEncode(mappings));

      debugPrint('💾 Stored Client ID mappings: ${mappings.length} mappings');
      for (final entry in mappings.entries) {
        debugPrint(
            '   └─ Skor User ID: ${entry.key} → Client ID: ${entry.value}');
      }
    } catch (e) {
      debugPrint('❌ Error storing Client ID mappings: $e');
    }
  }

  /// Store single mapping
  Future<void> storeSingleMapping(String clientId, String skorUserId) async {
    await storeClientIdMapping({clientId: skorUserId});
  }

  /// Get all Skor User ID -> Client ID mappings
  Future<Map<String, String>> getClientIdMappings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappingJson = prefs.getString(_mappingKey);

      if (mappingJson == null) {
        debugPrint('📦 No Client ID mappings found');
        return {};
      }

      final mappings = Map<String, String>.from(jsonDecode(mappingJson));
      debugPrint('📦 Loaded ${mappings.length} Client ID mappings');
      return mappings;
    } catch (e) {
      debugPrint('❌ Error loading Client ID mappings: $e');
      return {};
    }
  }

  /// Get Client ID from Skor User ID (direct lookup)
  Future<String?> getClientId(String skorUserId) async {
    final mappings = await getClientIdMappings();
    final clientId = mappings[skorUserId];

    debugPrint('🔍 Skor User ID: $skorUserId → Client ID: $clientId');
    return clientId;
  }

  /// Get Skor User ID from Client ID (reverse lookup)
  Future<String?> getSkorUserId(String clientId) async {
    final mappings = await getClientIdMappings();

    for (final entry in mappings.entries) {
      if (entry.value == clientId) {
        debugPrint('🔍 Client ID: $clientId → Skor User ID: ${entry.key}');
        return entry.key;
      }
    }

    debugPrint('🔍 Client ID: $clientId → Skor User ID: not found');
    return null;
  }

  /// Clear all mappings
  Future<void> clearMappings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_mappingKey);
      debugPrint('🗑️ Cleared all Client ID mappings');
    } catch (e) {
      debugPrint('❌ Error clearing Client ID mappings: $e');
    }
  }

  /// Get mapping statistics
  Future<Map<String, int>> getMappingStats() async {
    final mappings = await getClientIdMappings();
    return {
      'totalMappings': mappings.length,
    };
  }
}
