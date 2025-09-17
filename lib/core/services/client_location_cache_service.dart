import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client_location.dart';
import '../models/client_address.dart';
import 'client_id_mapping_service.dart';

class ClientLocationCacheService {
  static const String _locationPrefix = 'client_location_';
  static const String _addressPrefix = 'client_address_';
  static const String _clientInfoPrefix = 'client_info_';
  static const String _timestampPrefix = 'location_timestamp_';
  static const Duration _cacheValidDuration = Duration(hours: 24); // 1 hari

  static ClientLocationCacheService? _instance;

  ClientLocationCacheService._();

  static ClientLocationCacheService get instance {
    _instance ??= ClientLocationCacheService._();
    return _instance!;
  }

  // Cache location history for a specific client
  Future<void> cacheClientLocationData({
    required String skorUserId,
    required List<ClientLocation> locations,
    required List<ClientAddress> addresses,
    String? clientId,
    String? clientName,
    String? clientPhone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Save locations
      final locationsJson = locations.map((l) => l.toJson()).toList();
      await prefs.setString(
        '$_locationPrefix$skorUserId',
        jsonEncode(locationsJson),
      );

      // Save addresses
      final addressesJson = addresses.map((a) => a.toJson()).toList();
      await prefs.setString(
        '$_addressPrefix$skorUserId',
        jsonEncode(addressesJson),
      );

      // Save client info
      if (clientId != null || clientName != null || clientPhone != null) {
        final clientInfo = {
          'id': clientId,
          'name': clientName,
          'phone': clientPhone,
        };
        await prefs.setString(
          '$_clientInfoPrefix$skorUserId',
          jsonEncode(clientInfo),
        );
      }

      // Save timestamp
      await prefs.setInt('$_timestampPrefix$skorUserId', timestamp);

      print('📦 Cached location data for skorUserId: $skorUserId');
      print('   └─ Locations: ${locations.length}');
      print('   └─ Addresses: ${addresses.length}');
      if (clientId != null) print('   └─ Client ID: $clientId');
      if (clientName != null) print('   └─ Client Name: $clientName');
      if (clientPhone != null) print('   └─ Client Phone: $clientPhone');
    } catch (e) {
      print('❌ Error caching client location data: $e');
    }
  }

  // Get cached location data for a specific client
  Future<CachedLocationData?> getCachedClientLocationData(
      String skorUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache exists and is valid
      final timestampKey = '$_timestampPrefix$skorUserId';
      final cachedTimestamp = prefs.getInt(timestampKey);

      if (cachedTimestamp == null) {
        print('📦 No cache found for skorUserId: $skorUserId');
        return null;
      }

      final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
      final isExpired = Duration(milliseconds: cacheAge) > _cacheValidDuration;

      if (isExpired) {
        print('⏰ Cache expired for skorUserId: $skorUserId');
        // Clean up expired cache
        await _clearClientCache(skorUserId);
        return null;
      }

      // Load cached data
      final locationsJson = prefs.getString('$_locationPrefix$skorUserId');
      final addressesJson = prefs.getString('$_addressPrefix$skorUserId');
      final clientInfoJson = prefs.getString('$_clientInfoPrefix$skorUserId');

      if (locationsJson == null || addressesJson == null) {
        print('📦 Incomplete cache for skorUserId: $skorUserId');
        return null;
      }

      final locationsList = jsonDecode(locationsJson) as List;
      final addressesList = jsonDecode(addressesJson) as List;

      final locations =
          locationsList.map((json) => ClientLocation.fromJson(json)).toList();

      final addresses =
          addressesList.map((json) => ClientAddress.fromJson(json)).toList();

      // Load client info if available
      String? clientId;
      String? clientName;
      String? clientPhone;
      if (clientInfoJson != null) {
        final clientInfo = jsonDecode(clientInfoJson) as Map<String, dynamic>;
        clientId = clientInfo['id'];
        clientName = clientInfo['name'];
        clientPhone = clientInfo['phone'];
      }

      print('✅ Loaded cached data for skorUserId: $skorUserId');
      print('   └─ Locations: ${locations.length}');
      print('   └─ Addresses: ${addresses.length}');
      if (clientId != null) print('   └─ Client ID: $clientId');
      if (clientName != null) print('   └─ Client Name: $clientName');
      if (clientPhone != null) print('   └─ Client Phone: $clientPhone');
      print('   └─ Cache age: ${Duration(milliseconds: cacheAge).inHours}h');

      return CachedLocationData(
        locations: locations,
        addresses: addresses,
        timestamp: DateTime.fromMillisecondsSinceEpoch(cachedTimestamp),
        clientId: clientId,
        clientName: clientName,
        clientPhone: clientPhone,
      );
    } catch (e) {
      print('❌ Error loading cached client location data: $e');
      return null;
    }
  }

  // Get all cached client location data (for All Client Location screen)
  Future<Map<String, CachedLocationData>> getAllCachedLocationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final Map<String, CachedLocationData> allData = {};

      // Find all location cache keys
      final locationKeys =
          allKeys.where((key) => key.startsWith(_locationPrefix)).toList();

      for (final locationKey in locationKeys) {
        final skorUserId = locationKey.substring(_locationPrefix.length);
        final cachedData = await getCachedClientLocationData(skorUserId);

        if (cachedData != null) {
          allData[skorUserId] = cachedData;
        }
      }

      print('📦 Loaded all cached location data: ${allData.length} clients');
      return allData;
    } catch (e) {
      print('❌ Error loading all cached location data: $e');
      return {};
    }
  }

  // Clear cache for specific client
  Future<void> _clearClientCache(String skorUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_locationPrefix$skorUserId');
      await prefs.remove('$_addressPrefix$skorUserId');
      await prefs.remove('$_clientInfoPrefix$skorUserId');
      await prefs.remove('$_timestampPrefix$skorUserId');
      print('🗑️ Cleared cache for skorUserId: $skorUserId');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  // Clear all location cache
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      final keysToRemove = allKeys
          .where((key) =>
              key.startsWith(_locationPrefix) ||
              key.startsWith(_addressPrefix) ||
              key.startsWith(_clientInfoPrefix) ||
              key.startsWith(_timestampPrefix))
          .toList();

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      print('🗑️ Cleared all location cache (${keysToRemove.length} keys)');
    } catch (e) {
      print('❌ Error clearing all cache: $e');
    }
  }

  // Update Client ID in existing cache using mapping service
  Future<void> updateClientIdInCache() async {
    try {
      final mappingService = ClientIdMappingService.instance;
      final mappings =
          await mappingService.getClientIdMappings(); // skorUserId -> clientId

      if (mappings.isEmpty) {
        print('📦 No Client ID mappings available for cache update');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final clientInfoKeys =
          allKeys.where((key) => key.startsWith(_clientInfoPrefix)).toList();

      int updatedCount = 0;

      for (final clientInfoKey in clientInfoKeys) {
        final skorUserId = clientInfoKey.substring(_clientInfoPrefix.length);

        // Direct lookup: skorUserId -> clientId
        final clientId = mappings[skorUserId];

        if (clientId != null) {
          // Get existing client info
          final existingJson = prefs.getString(clientInfoKey);
          if (existingJson != null) {
            final clientInfo = jsonDecode(existingJson) as Map<String, dynamic>;

            // Update Client ID if it's different or missing
            if (clientInfo['id'] != clientId) {
              clientInfo['id'] = clientId;
              await prefs.setString(clientInfoKey, jsonEncode(clientInfo));
              updatedCount++;

              print(
                  '🔄 Updated cache: Skor User ID $skorUserId → Client ID $clientId');
            }
          }
        }
      }

      if (updatedCount > 0) {
        print('✅ Updated Client ID in cache for $updatedCount clients');
      } else {
        print('📦 No cache updates needed - all Client IDs are current');
      }
    } catch (e) {
      print('❌ Error updating Client ID in cache: $e');
    }
  }

  // Get cache info for debugging
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      final locationKeys =
          allKeys.where((key) => key.startsWith(_locationPrefix)).length;
      final addressKeys =
          allKeys.where((key) => key.startsWith(_addressPrefix)).length;
      final timestampKeys =
          allKeys.where((key) => key.startsWith(_timestampPrefix)).length;

      return {
        'totalClients': timestampKeys,
        'locationKeys': locationKeys,
        'addressKeys': addressKeys,
        'timestampKeys': timestampKeys,
        'cacheValidHours': _cacheValidDuration.inHours,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

class CachedLocationData {
  final List<ClientLocation> locations;
  final List<ClientAddress> addresses;
  final DateTime timestamp;
  final String? clientId;
  final String? clientName;
  final String? clientPhone;

  CachedLocationData({
    required this.locations,
    required this.addresses,
    required this.timestamp,
    this.clientId,
    this.clientName,
    this.clientPhone,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > const Duration(hours: 24);
  }

  Duration get age {
    return DateTime.now().difference(timestamp);
  }
}
