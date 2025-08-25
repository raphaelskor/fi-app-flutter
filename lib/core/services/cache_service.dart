import 'dart:convert';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry> _cache = {};

  // Default cache duration (5 minutes)
  static const Duration defaultCacheDuration = Duration(minutes: 5);

  /// Get cached data for a specific key
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Set cached data for a specific key
  void set<T>(String key, T data, {Duration? duration}) {
    _cache[key] = CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(duration ?? defaultCacheDuration),
    );
  }

  /// Clear specific cache entry
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Clear expired entries
  void clearExpired() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }

  /// Check if key exists and is not expired
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Get cache size
  int get size => _cache.length;

  /// Generate cache key for API calls
  static String generateApiKey(String endpoint,
      [Map<String, dynamic>? params]) {
    if (params == null || params.isEmpty) {
      return 'api_$endpoint';
    }

    final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

    final paramsString = jsonEncode(sortedParams);
    return 'api_${endpoint}_${paramsString.hashCode}';
  }

  /// Generate cache key for user-specific data
  static String generateUserKey(String userEmail, String dataType) {
    return 'user_${userEmail}_$dataType';
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  CacheEntry({
    required this.data,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
