import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../models/api_models.dart';
import '../repositories/client_repository.dart';
import '../exceptions/app_exception.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../services/daily_cache_service.dart';
import '../services/client_location_cache_service.dart';
import '../services/client_location_service.dart';
import '../services/client_address_service.dart';
import '../services/client_id_mapping_service.dart';
import 'package:geolocator/geolocator.dart';

enum ClientLoadingState {
  initial,
  loading,
  caching, // New state for cache loading
  loaded,
  error,
}

class ClientController extends ChangeNotifier {
  final ClientRepository _clientRepository = ClientRepository();
  final AuthService _authService;

  // State
  ClientLoadingState _loadingState = ClientLoadingState.initial;
  List<Client> _clients = [];
  List<Client> _todaysClients = [];
  Client? _selectedClient;
  String? _errorMessage;
  PaginationMeta? _paginationMeta;
  Position? _userLocation;

  // Filters
  String? _searchQuery;
  String? _statusFilter;
  int _currentPage = 1;

  // Constructor
  ClientController(this._authService);

  // Getters
  ClientLoadingState get loadingState => _loadingState;
  List<Client> get clients => _clients;
  List<Client> get todaysClients => _todaysClients;
  Client? get selectedClient => _selectedClient;
  String? get errorMessage => _errorMessage;
  PaginationMeta? get paginationMeta => _paginationMeta;
  Position? get userLocation => _userLocation;
  String? get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  int get currentPage => _currentPage;
  bool get hasMore => _paginationMeta?.hasNextPage ?? false;

  // Initialize
  Future<void> initialize() async {
    // Clear outdated cache on app startup
    await DailyCacheService.clearOutdatedCache();

    await _getUserLocation();
    await loadTodaysClients(); // This will use cache if available
  }

  // Get user location
  Future<void> _getUserLocation() async {
    try {
      _userLocation = await LocationService.getCurrentLocation();
    } catch (e) {
      debugPrint('Failed to get user location: $e');
    }
  }

  // Load clients from Skorcard API
  Future<void> loadClients({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _clients.clear();
      }

      _setLoadingState(ClientLoadingState.loading);

      // Get user email from AuthService
      final userEmail = _authService.userData?['email'] as String?;
      if (userEmail == null || userEmail.isEmpty) {
        throw ValidationException(
          message: 'User email not found. Please login again.',
          statusCode: 400,
        );
      }

      // Use Skorcard API to fetch clients
      final response = await _clientRepository.getSkorcardClients(
        fiOwnerEmail: userEmail,
        userLatitude: _userLocation?.latitude,
        userLongitude: _userLocation?.longitude,
      );

      if (response.success && response.data != null) {
        if (refresh) {
          _clients = response.data!;
        } else {
          _clients.addAll(response.data!);
        }

        _paginationMeta = response.pagination;
        _setLoadingState(ClientLoadingState.loaded);
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  // Load today's clients with daily caching
  Future<void> loadTodaysClients({bool forceRefresh = false}) async {
    try {
      _setLoadingState(ClientLoadingState.loading);

      // Try to load from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedClients = await DailyCacheService.loadCachedClients();
        if (cachedClients != null) {
          _todaysClients = cachedClients;
          _clients = List.from(_todaysClients); // Keep both in sync

          // Set caching state for extracting mappings from cached data
          _setLoadingState(ClientLoadingState.caching);

          // Extract and store Client ID mappings from cached data as well
          await _extractAndStoreClientIdMappings(_todaysClients);

          _setLoadingState(ClientLoadingState.loaded);
          debugPrint('📦 Loaded ${cachedClients.length} clients from cache');
          return;
        }
      }

      // Cache miss or force refresh - load from API
      debugPrint('🌐 Loading clients from API...');

      // Get user email from AuthService
      final userEmail = _authService.userData?['email'] as String?;
      if (userEmail == null || userEmail.isEmpty) {
        throw ValidationException(
          message: 'User email not found. Please login again.',
          statusCode: 400,
        );
      }

      // Use Skorcard API to fetch clients
      final response = await _clientRepository.getSkorcardClients(
        fiOwnerEmail: userEmail,
        userLatitude: _userLocation?.latitude,
        userLongitude: _userLocation?.longitude,
      );

      if (response.success && response.data != null) {
        _todaysClients = response.data!;
        _clients = List.from(_todaysClients); // Keep both in sync
        _paginationMeta = response.pagination;

        // Set caching state for processing mappings and cache
        _setLoadingState(ClientLoadingState.caching);

        // Extract and store Client ID mappings from the loaded data
        await _extractAndStoreClientIdMappings(_todaysClients);

        // Save to cache for next time
        await DailyCacheService.saveTodaysClients(_todaysClients);
        debugPrint('💾 Saved ${_todaysClients.length} clients to cache');

        // Auto-cache location data for all clients in background
        _autoCacheLocationData(_todaysClients);

        _setLoadingState(ClientLoadingState.loaded);
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  // Load more clients (pagination)
  Future<void> loadMoreClients() async {
    if (!hasMore || _loadingState == ClientLoadingState.loading) return;

    _currentPage++;
    await loadClients();
  }

  // Get client by ID
  Future<void> getClientById(String clientId) async {
    try {
      _setLoadingState(ClientLoadingState.loading);

      // Find client in existing list first
      final existingClient = _clients.firstWhere(
        (client) => client.id == clientId,
        orElse: () => throw NotFoundException(message: 'Client not found'),
      );

      _selectedClient = existingClient;
      _setLoadingState(ClientLoadingState.loaded);
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  // Update client status
  Future<bool> updateClientStatus(String clientId, String status) async {
    try {
      // For now, just update locally since Skorcard API may not support status updates
      _updateLocalClientStatus(clientId, status);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  // Search clients
  Future<void> searchClients(String query) async {
    _searchQuery = query.isEmpty ? null : query;

    // For now, filter locally since Skorcard API doesn't support search
    if (_searchQuery == null) {
      await loadClients(refresh: true);
    } else {
      _setLoadingState(ClientLoadingState.loading);
      await loadClients(refresh: true); // Get fresh data

      final filteredClients = _clients.where((client) {
        return client.name
                .toLowerCase()
                .contains(_searchQuery!.toLowerCase()) ||
            client.phone.contains(_searchQuery!) ||
            client.address.toLowerCase().contains(_searchQuery!.toLowerCase());
      }).toList();

      _clients = filteredClients;
      _setLoadingState(ClientLoadingState.loaded);
    }
  }

  // Filter by status
  Future<void> filterByStatus(String? status) async {
    _statusFilter = status;

    // For now, filter locally since Skorcard API doesn't support status filter
    if (_statusFilter == null) {
      await loadClients(refresh: true);
    } else {
      _setLoadingState(ClientLoadingState.loading);
      await loadClients(refresh: true); // Get fresh data

      final filteredClients = _clients.where((client) {
        return client.status.toLowerCase() == _statusFilter!.toLowerCase();
      }).toList();

      _clients = filteredClients;
      _setLoadingState(ClientLoadingState.loaded);
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await _getUserLocation();
    await loadClients(refresh: true);
    await loadTodaysClients(forceRefresh: true); // Force refresh from API
  }

  // Clear selection
  void clearSelection() {
    _selectedClient = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Cache management methods
  Future<Map<String, dynamic>> getCacheInfo() async {
    return await DailyCacheService.getCacheInfo();
  }

  Future<void> clearCache() async {
    await DailyCacheService.clearAllCache();
    debugPrint('🗑️ Cache cleared manually');
  }

  // Check if data is from cache
  Future<bool> isDataFromCache() async {
    return await DailyCacheService.isCacheValidForToday();
  }

  // Private helper methods
  void _setLoadingState(ClientLoadingState state) {
    _loadingState = state;
    if (state != ClientLoadingState.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _loadingState = ClientLoadingState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void _updateLocalClientStatus(String clientId, String status) {
    for (int i = 0; i < _clients.length; i++) {
      if (_clients[i].id == clientId) {
        _clients[i] = _clients[i].copyWith(status: status);
        break;
      }
    }

    for (int i = 0; i < _todaysClients.length; i++) {
      if (_todaysClients[i].id == clientId) {
        _todaysClients[i] = _todaysClients[i].copyWith(status: status);
        break;
      }
    }

    if (_selectedClient?.id == clientId) {
      _selectedClient = _selectedClient!.copyWith(status: status);
    }

    notifyListeners();
  }

  // Auto-cache location data for all clients in background
  void _autoCacheLocationData(List<Client> clients) async {
    try {
      debugPrint(
          '🚀 Starting auto-cache location data for ${clients.length} clients...');

      final cacheService = ClientLocationCacheService.instance;

      // Process clients in background without blocking UI
      for (final client in clients) {
        if (client.skorUserId == null || client.skorUserId!.isEmpty) continue;

        try {
          // Check if data is already cached and still valid
          final cachedData = await cacheService
              .getCachedClientLocationData(client.skorUserId!);
          if (cachedData != null && !cachedData.isExpired) {
            continue; // Skip if already cached and valid
          }

          debugPrint(
              '📍 Auto-caching location data for client: ${client.skorUserId}');

          // Fetch location history using ClientLocationService
          final locationResponse =
              await ClientLocationService.getClientLocationHistory(
                  client.skorUserId!);

          // Fetch addresses using ClientAddressService
          final addressResponse =
              await ClientAddressService.getClientAddresses(client.skorUserId!);

          // Debug Client ID before caching
          debugPrint('🔍 About to cache for client:');
          debugPrint('   - Client ID: "${client.id}"');
          debugPrint('   - Skor User ID: "${client.skorUserId}"');
          debugPrint('   - Client Name: "${client.name}"');
          debugPrint('   - Client Phone: "${client.phone}"');

          // Cache the data
          await cacheService.cacheClientLocationData(
            skorUserId: client.skorUserId!,
            locations: locationResponse.locations,
            addresses: addressResponse.addresses,
            clientId: client.id,
            clientName: client.name,
            clientPhone: client.phone,
          );
          debugPrint(
              '✅ Auto-cached location data for client: ${client.skorUserId}');

          // Small delay to avoid overwhelming the API
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint(
              '❌ Error auto-caching location data for client ${client.skorUserId}: $e');
          // Continue with next client instead of stopping
          continue;
        }
      }

      debugPrint('🎉 Auto-cache location data completed!');
    } catch (e) {
      debugPrint('❌ Error in auto-cache location data: $e');
    }
  }

  // Extract and store Client ID mappings from loaded client data
  Future<void> _extractAndStoreClientIdMappings(List<Client> clients) async {
    try {
      debugPrint(
          '🔗 Extracting Client ID mappings from ${clients.length} clients...');

      final mappingService = ClientIdMappingService.instance;
      final mappings = <String, String>{};
      int successCount = 0;
      int errorCount = 0;

      for (final client in clients) {
        try {
          final skorUserId = client.skorUserId;
          final clientId = client.id;

          debugPrint('   🔍 Processing client:');
          debugPrint('      - Client ID: "$clientId"');
          debugPrint('      - Skor User ID: "$skorUserId"');
          debugPrint('      - Client Name: "${client.name}"');

          if (skorUserId != null &&
              skorUserId.isNotEmpty &&
              clientId.isNotEmpty &&
              clientId != 'null') {
            // Store mapping: skorUserId -> clientId
            mappings[skorUserId] = clientId;
            successCount++;

            debugPrint('      ✅ Will store mapping: $skorUserId → $clientId');
          } else {
            errorCount++;
            debugPrint('      ❌ Invalid data - skipping');
            debugPrint(
                '         - skorUserId isEmpty: ${skorUserId == null || skorUserId.isEmpty}');
            debugPrint(
                '         - clientId isEmpty/null: ${clientId.isEmpty || clientId == "null"}');
          }
        } catch (e) {
          errorCount++;
          debugPrint('      ❌ Error processing client ${client.name}: $e');
        }
      }

      // Store all mappings at once
      if (mappings.isNotEmpty) {
        await mappingService.storeClientIdMapping(mappings);
      }

      debugPrint('🔗 Client ID mapping extraction completed:');
      debugPrint('   ✅ Success: $successCount mappings stored');
      debugPrint('   ❌ Errors: $errorCount clients skipped');

      // Update cache with new Client IDs
      if (successCount > 0) {
        try {
          final cacheService = ClientLocationCacheService.instance;
          await cacheService.updateClientIdInCache();
          debugPrint('✅ Updated location cache with Client IDs');
        } catch (e) {
          debugPrint('❌ Error updating location cache: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _extractAndStoreClientIdMappings: $e');
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    return 'An unexpected error occurred: ${error.toString()}';
  }
}
