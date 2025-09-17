import 'package:flutter/foundation.dart';
import '../models/client_location.dart';
import '../models/client_address.dart';
import '../models/operational_area.dart';
import '../services/client_location_service.dart';
import '../services/client_address_service.dart';
import '../services/operational_area_service.dart';
import '../services/client_location_cache_service.dart';

enum ClientLocationLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class ClientLocationController extends ChangeNotifier {
  ClientLocationLoadingState _loadingState = ClientLocationLoadingState.initial;
  List<ClientLocation> _locations = [];
  List<ClientAddress> _addresses = [];
  List<OperationalArea> _operationalAreas = [];
  String? _errorMessage;
  String? _skorUserId;
  String? _clientId;
  String? _clientName;
  String? _clientPhone;
  bool _showOperationalAreas = true;
  bool _isDataFromCache = false;

  ClientLocationLoadingState get loadingState => _loadingState;
  List<ClientLocation> get locations => _locations;
  List<ClientAddress> get addresses => _addresses;
  List<OperationalArea> get operationalAreas => _operationalAreas;
  String? get errorMessage => _errorMessage;
  String? get skorUserId => _skorUserId;
  bool get showOperationalAreas => _showOperationalAreas;
  bool get isDataFromCache => _isDataFromCache;

  bool get isLoading => _loadingState == ClientLocationLoadingState.loading;
  bool get hasError => _loadingState == ClientLocationLoadingState.error;
  bool get hasData =>
      _loadingState == ClientLocationLoadingState.loaded &&
      (_locations.isNotEmpty || _addresses.isNotEmpty);

  void initialize(String skorUserId,
      {String? clientId, String? clientName, String? clientPhone}) {
    _skorUserId = skorUserId;
    _clientId = clientId;
    _clientName = clientName;
    _clientPhone = clientPhone;
    loadData();
    loadOperationalAreas();
  }

  void toggleOperationalAreas() {
    _showOperationalAreas = !_showOperationalAreas;
    notifyListeners();
  }

  Future<void> loadData() async {
    if (_skorUserId == null || _skorUserId!.isEmpty) {
      _setError('Skor User ID is required');
      return;
    }

    _setLoadingState(ClientLocationLoadingState.loading);
    _errorMessage = null;

    try {
      // First try to load from cache
      final cacheService = ClientLocationCacheService.instance;
      final cachedData =
          await cacheService.getCachedClientLocationData(_skorUserId!);

      if (cachedData != null && !cachedData.isExpired) {
        // Use cached data
        _locations = cachedData.locations;
        _addresses = cachedData.addresses;
        _isDataFromCache = true;

        debugPrint(
            '✅ Loaded from cache: ${_locations.length} locations, ${_addresses.length} addresses');
        debugPrint(
            '   └─ Cache age: ${cachedData.age.inHours}h ${cachedData.age.inMinutes % 60}m');

        _setLoadingState(ClientLocationLoadingState.loaded);
        notifyListeners();
        return;
      }

      // Cache miss or expired, load from API
      debugPrint('📡 Loading fresh data from API...');
      _isDataFromCache = false;
      await Future.wait([
        loadLocationHistory(),
        loadAddresses(),
      ]);

      // Cache the fresh data
      await cacheService.cacheClientLocationData(
        skorUserId: _skorUserId!,
        locations: _locations,
        addresses: _addresses,
        clientId: _clientId,
        clientName: _clientName,
        clientPhone: _clientPhone,
      );

      if (_locations.isEmpty && _addresses.isEmpty) {
        _setError('No location or address data found for this client');
      } else {
        _setLoadingState(ClientLocationLoadingState.loaded);
        debugPrint(
            '✅ Fresh data loaded and cached: ${_locations.length} locations, ${_addresses.length} addresses');
      }
    } catch (e) {
      _setError(e.toString());
      debugPrint('❌ Error loading location data: $e');
    }

    notifyListeners();
  }

  Future<void> loadLocationHistory() async {
    if (_skorUserId == null || _skorUserId!.isEmpty) {
      return;
    }

    try {
      final response =
          await ClientLocationService.getClientLocationHistory(_skorUserId!);
      _locations = response.locations;
      debugPrint('✅ Loaded ${_locations.length} location records');
    } catch (e) {
      debugPrint('❌ Error loading location history: $e');
      // Don't set error here as we'll handle it in loadData
    }
  }

  Future<void> loadAddresses() async {
    if (_skorUserId == null || _skorUserId!.isEmpty) {
      return;
    }

    try {
      final response =
          await ClientAddressService.getClientAddresses(_skorUserId!);
      _addresses = response.addresses;
      debugPrint('✅ Loaded ${_addresses.length} address records');
    } catch (e) {
      debugPrint('❌ Error loading addresses: $e');
      // Don't set error here as we'll handle it in loadData
    }
  }

  Future<void> loadOperationalAreas() async {
    try {
      debugPrint('🗺️ Loading operational areas...');
      _operationalAreas = await OperationalAreaService.fetchOperationalAreas();
      debugPrint('✅ Loaded ${_operationalAreas.length} operational areas');

      // Debug: Print details of each area
      for (final area in _operationalAreas) {
        debugPrint(
            '📍 Area: ${area.name} (${area.province}) - ${area.polygons.length} polygons');
        for (int i = 0; i < area.polygons.length; i++) {
          debugPrint('   └─ Polygon $i: ${area.polygons[i].length} points');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading operational areas: $e');
      // Don't fail the entire loading process if operational areas fail
    }
  }

  Future<void> refresh() async {
    // Force reload from API and update cache
    _isDataFromCache = false;
    await loadData();
    // Don't reload operational areas on refresh as they don't change often
  }

  // Clear cache for this client
  Future<void> clearCache() async {
    if (_skorUserId != null) {
      final cacheService = ClientLocationCacheService.instance;
      await cacheService.clearAllCache(); // For now, clear all cache
      debugPrint('🗑️ Cleared location cache');
    }
  }

  // Get cache info for debugging
  Future<Map<String, dynamic>> getCacheInfo() async {
    final cacheService = ClientLocationCacheService.instance;
    final cacheInfo = await cacheService.getCacheInfo();

    return {
      ...cacheInfo,
      'currentClientFromCache': _isDataFromCache,
      'currentSkorUserId': _skorUserId,
      'locationsCount': _locations.length,
      'addressesCount': _addresses.length,
    };
  }

  void _setLoadingState(ClientLocationLoadingState state) {
    _loadingState = state;
  }

  void _setError(String message) {
    _errorMessage = message;
    _loadingState = ClientLocationLoadingState.error;
  }

  void clearError() {
    _errorMessage = null;
    if (_loadingState == ClientLocationLoadingState.error) {
      _loadingState = ClientLocationLoadingState.initial;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
