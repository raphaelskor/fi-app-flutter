import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';
import '../utils/timezone_utils.dart';

class DailyCacheService {
  static const String _clientsCacheKey = 'daily_clients_cache';
  static const String _clientsCacheDateKey = 'daily_clients_cache_date';

  /// Get today's date as string in YYYY-MM-DD format using Jakarta timezone
  static String get _todayString {
    return TimezoneUtils.formatDateForApi(TimezoneUtils.todayInJakarta());
  }

  /// Check if cached data is still valid for today
  static Future<bool> isCacheValidForToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDate = prefs.getString(_clientsCacheDateKey);
      return cachedDate == _todayString;
    } catch (e) {
      print('Error checking cache validity: $e');
      return false;
    }
  }

  /// Save today's clients to cache
  static Future<bool> saveTodaysClients(List<Client> clients) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert clients to JSON list
      final clientsJson = clients.map((client) => client.toJson()).toList();
      final jsonString = jsonEncode(clientsJson);

      // Debug: Log first client's raw data structure
      if (clients.isNotEmpty) {
        final firstClient = clients.first;
        print(
            '🔍 First client raw data keys: ${firstClient.rawApiData?.keys.toList()}');
        print('🔍 First client skorUserId: ${firstClient.skorUserId}');
        print(
            '🔍 Raw data sample size: ${firstClient.rawApiData?.length ?? 0} fields');
      }

      // Save data and date
      await prefs.setString(_clientsCacheKey, jsonString);
      await prefs.setString(_clientsCacheDateKey, _todayString);

      print('✅ Cached ${clients.length} clients for $_todayString');
      print(
          '📊 Cache size: ${(jsonString.length / 1024).toStringAsFixed(2)} KB');
      return true;
    } catch (e) {
      print('❌ Error saving clients cache: $e');
      return false;
    }
  }

  /// Load cached clients for today
  static Future<List<Client>?> loadCachedClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache is valid for today
      if (!await isCacheValidForToday()) {
        print('📅 Cache is outdated, need to refresh');
        return null;
      }

      final jsonString = prefs.getString(_clientsCacheKey);
      if (jsonString == null) {
        print('📭 No cached data found');
        return null;
      }

      // Parse JSON to clients list
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final clients = jsonList.map((json) => Client.fromJson(json)).toList();

      print('📦 Loaded ${clients.length} cached clients for $_todayString');

      // Log detailed information about loaded data
      if (clients.isNotEmpty) {
        final firstClient = clients[0];
        print('📋 First client data verification:');
        print('   - ID: ${firstClient.id}');
        print('   - Name: ${firstClient.name}');
        print(
            '   - rawApiData: ${firstClient.rawApiData != null ? "✅ Present (${firstClient.rawApiData!.keys.length} keys)" : "❌ Missing"}');
        if (firstClient.rawApiData != null) {
          print(
              '   - rawApiData keys: ${firstClient.rawApiData!.keys.toList()}');
        }
      }

      return clients;
    } catch (e) {
      print('❌ Error loading clients cache: $e');
      return null;
    }
  }

  /// Clear outdated cache (optional, can be called on app startup)
  static Future<void> clearOutdatedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDate = prefs.getString(_clientsCacheDateKey);

      if (cachedDate != null && cachedDate != _todayString) {
        await prefs.remove(_clientsCacheKey);
        await prefs.remove(_clientsCacheDateKey);
        print('🗑️ Cleared outdated cache from $cachedDate');
      }
    } catch (e) {
      print('❌ Error clearing outdated cache: $e');
    }
  }

  /// Manually clear all cache (for debugging or refresh purposes)
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clientsCacheKey);
      await prefs.remove(_clientsCacheDateKey);
      print('🗑️ Cleared all clients cache');
    } catch (e) {
      print('❌ Error clearing all cache: $e');
    }
  }

  /// Get cache info for debugging
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDate = prefs.getString(_clientsCacheDateKey);
      final jsonString = prefs.getString(_clientsCacheKey);

      int clientCount = 0;
      if (jsonString != null) {
        try {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          clientCount = jsonList.length;
        } catch (e) {
          // Ignore parsing errors for info purpose
        }
      }

      return {
        'cachedDate': cachedDate,
        'todayDate': _todayString,
        'isValid': await isCacheValidForToday(),
        'clientCount': clientCount,
        'hasData': jsonString != null,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}
