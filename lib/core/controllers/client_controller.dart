import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../models/api_models.dart';
import '../repositories/client_repository.dart';
import '../exceptions/app_exception.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import 'package:geolocator/geolocator.dart';

enum ClientLoadingState {
  initial,
  loading,
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
    await _getUserLocation();
    await loadTodaysClients();
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

  // Load today's clients (same as regular clients for now)
  Future<void> loadTodaysClients() async {
    try {
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
        _todaysClients = response.data!;
        _clients = List.from(_todaysClients); // Keep both in sync
        _paginationMeta = response.pagination;
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
    await loadTodaysClients();
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

  String _getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    return 'An unexpected error occurred: ${error.toString()}';
  }
}
