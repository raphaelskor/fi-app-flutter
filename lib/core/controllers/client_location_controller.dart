import 'package:flutter/foundation.dart';
import '../models/client_location.dart';
import '../services/client_location_service.dart';

enum ClientLocationLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class ClientLocationController extends ChangeNotifier {
  ClientLocationLoadingState _loadingState = ClientLocationLoadingState.initial;
  List<ClientLocation> _locations = [];
  String? _errorMessage;
  String? _skorUserId;

  ClientLocationLoadingState get loadingState => _loadingState;
  List<ClientLocation> get locations => _locations;
  String? get errorMessage => _errorMessage;
  String? get skorUserId => _skorUserId;

  bool get isLoading => _loadingState == ClientLocationLoadingState.loading;
  bool get hasError => _loadingState == ClientLocationLoadingState.error;
  bool get hasData =>
      _loadingState == ClientLocationLoadingState.loaded &&
      _locations.isNotEmpty;

  void initialize(String skorUserId) {
    _skorUserId = skorUserId;
    loadLocationHistory();
  }

  Future<void> loadLocationHistory() async {
    if (_skorUserId == null || _skorUserId!.isEmpty) {
      _setError('Skor User ID is required');
      return;
    }

    _setLoadingState(ClientLocationLoadingState.loading);
    _errorMessage = null;

    try {
      final response =
          await ClientLocationService.getClientLocationHistory(_skorUserId!);
      _locations = response.locations;

      if (_locations.isEmpty) {
        _setError('No location history found for this client');
      } else {
        _setLoadingState(ClientLocationLoadingState.loaded);
        debugPrint('✅ Loaded ${_locations.length} location records');
      }
    } catch (e) {
      _setError(e.toString());
      debugPrint('❌ Error loading location history: $e');
    }

    notifyListeners();
  }

  Future<void> refresh() async {
    await loadLocationHistory();
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
