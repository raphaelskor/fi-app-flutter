import 'package:flutter/foundation.dart';
import '../models/contactability.dart';
import '../models/contactability_history.dart';
import '../models/api_models.dart';
import '../repositories/client_repository.dart';
import '../services/api_service.dart';
import '../exceptions/app_exception.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

enum ContactabilityLoadingState {
  initial,
  loading,
  loaded,
  submitting,
  submitted,
  error,
}

class ContactabilityController extends ChangeNotifier {
  final ContactabilityRepository _contactabilityRepository =
      ContactabilityRepository();
  final ApiService _apiService = ApiService();

  // State
  ContactabilityLoadingState _loadingState = ContactabilityLoadingState.initial;
  List<ContactabilityHistory> _contactabilityHistory = [];
  Contactability? _selectedContactability;
  String? _errorMessage;
  PaginationMeta? _paginationMeta;

  // Form state
  String? _clientId;
  String? _skorUserId; // Add Skor User ID for API calls
  ContactabilityChannel _selectedChannel = ContactabilityChannel.call;
  ContactabilityResult? _selectedResult;
  String _notes = '';
  Position? _currentLocation;

  // New form fields for enhanced contactability
  VisitAction? _selectedVisitAction;
  VisitStatus? _selectedVisitStatus;
  ContactResult? _selectedContactResult;
  VisitLocation? _selectedVisitLocation;
  VisitBySkorTeam _selectedVisitBySkorTeam = VisitBySkorTeam.yes;
  String _visitNotes = '';
  String _visitAgent = '';
  String _visitAgentTeamLead = '';
  DateTime? _contactabilityDateTime;

  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 20;

  // Getters
  ContactabilityLoadingState get loadingState => _loadingState;
  List<ContactabilityHistory> get contactabilityHistory =>
      _contactabilityHistory;
  Contactability? get selectedContactability => _selectedContactability;
  String? get errorMessage => _errorMessage;
  PaginationMeta? get paginationMeta => _paginationMeta;
  String? get clientId => _clientId;
  ContactabilityChannel get selectedChannel => _selectedChannel;
  ContactabilityResult? get selectedResult => _selectedResult;
  String get notes => _notes;
  Position? get currentLocation => _currentLocation;
  int get currentPage => _currentPage;
  bool get hasMore => _paginationMeta?.hasNextPage ?? false;
  bool get isSubmitting =>
      _loadingState == ContactabilityLoadingState.submitting;

  // New getters for enhanced form
  VisitAction? get selectedVisitAction => _selectedVisitAction;
  VisitStatus? get selectedVisitStatus => _selectedVisitStatus;
  ContactResult? get selectedContactResult => _selectedContactResult;
  VisitLocation? get selectedVisitLocation => _selectedVisitLocation;
  VisitBySkorTeam get selectedVisitBySkorTeam => _selectedVisitBySkorTeam;
  String get visitNotes => _visitNotes;
  String get visitAgent => _visitAgent;
  String get visitAgentTeamLead => _visitAgentTeamLead;
  DateTime? get contactabilityDateTime => _contactabilityDateTime;

  // Initialize
  Future<void> initialize(String clientId, {String? skorUserId}) async {
    _clientId = clientId;
    _skorUserId = skorUserId;
    _contactabilityDateTime = DateTime.now(); // Set current date/time
    await _getCurrentLocation();
    await loadContactabilityHistory();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      _currentLocation = await LocationService.getCurrentLocation();
    } catch (e) {
      debugPrint('Failed to get current location: $e');
    }
  }

  // Load contactability history from Skorcard API
  Future<void> loadContactabilityHistory({bool refresh = false}) async {
    if (_skorUserId == null || _skorUserId!.isEmpty || _skorUserId == 'null') {
      debugPrint(
          'No valid Skor User ID available for contactability history: $_skorUserId');
      _contactabilityHistory.clear();
      _setLoadingState(ContactabilityLoadingState.loaded);
      return;
    }

    try {
      if (refresh) {
        _currentPage = 1;
        _contactabilityHistory.clear();
      }

      _setLoadingState(ContactabilityLoadingState.loading);

      // Fetch data from Skorcard API with error handling
      final List<Map<String, dynamic>> rawHistory;
      try {
        rawHistory = await _apiService.fetchContactabilityHistory(_skorUserId!);
      } catch (apiError) {
        debugPrint('API Error fetching contactability history: $apiError');
        _contactabilityHistory.clear();
        _setLoadingState(ContactabilityLoadingState.loaded);
        return;
      }

      // Convert to ContactabilityHistory objects with error handling
      final List<ContactabilityHistory> historyList = [];
      for (final item in rawHistory) {
        try {
          historyList.add(ContactabilityHistory.fromSkorcardApi(item));
        } catch (e) {
          debugPrint('Error parsing contactability history item: $e');
          // Skip this item and continue with others
        }
      }

      // Sort by created time (newest first)
      historyList.sort((a, b) => b.createdTime.compareTo(a.createdTime));

      if (refresh) {
        _contactabilityHistory = historyList;
      } else {
        _contactabilityHistory.addAll(historyList);
      }

      _setLoadingState(ContactabilityLoadingState.loaded);
    } catch (e) {
      debugPrint('Unexpected error in loadContactabilityHistory: $e');
      // Don't show error to user, just log and set to loaded state
      _contactabilityHistory.clear();
      _setLoadingState(ContactabilityLoadingState.loaded);
    }
  } // Load more history (pagination) - Not applicable for Skorcard API for now

  Future<void> loadMoreHistory() async {
    // Skorcard API returns all data at once, so this method is not needed
    // but keeping it for interface compatibility
    return;
  }

  // Submit contactability to Skorcard API
  Future<bool> submitContactability({
    String? ptpAmount,
    DateTime? ptpDate,
  }) async {
    if (_skorUserId == null || _skorUserId!.isEmpty) {
      _setError('User ID not available');
      return false;
    }

    if (_visitNotes.trim().isEmpty) {
      _setError('Please enter visit notes');
      return false;
    }

    try {
      _setLoadingState(ContactabilityLoadingState.submitting);

      // Build the data according to the API specification
      final Map<String, dynamic> submitData = {
        'User_ID': _skorUserId!,
        'Channel': _getChannelApiValue(_selectedChannel),
      };

      // Add location if available
      if (_currentLocation != null) {
        submitData['Visit_Lat_Long'] =
            '${_currentLocation!.latitude},${_currentLocation!.longitude}';
      }

      // Add visit-specific fields
      if (_selectedVisitLocation != null) {
        submitData['Visit_Location'] = _selectedVisitLocation!.apiValue;
      }

      if (_selectedVisitAction != null) {
        submitData['Visit_Action'] = _selectedVisitAction!.apiValue;
      }

      if (_selectedVisitStatus != null) {
        submitData['Visit_Status'] = _selectedVisitStatus!.apiValue;
      }

      if (_selectedContactResult != null) {
        submitData['Contact_Result'] = _selectedContactResult!.apiValue;

        // Add PTP fields if contact result is PTP
        if (_selectedContactResult == ContactResult.ptp) {
          if (ptpAmount != null && ptpAmount.isNotEmpty) {
            submitData['P2p_Amount'] = ptpAmount;
          }
          if (ptpDate != null) {
            // Format date as DD/MM/YYYY
            final day = ptpDate.day.toString().padLeft(2, '0');
            final month = ptpDate.month.toString().padLeft(2, '0');
            final year = ptpDate.year.toString();
            submitData['P2p_Date'] = '$day/$month/$year';
          }
        }
      }

      submitData['Visit_Notes'] = _visitNotes.trim();
      submitData['Visit_by_Skor_Team'] = _selectedVisitBySkorTeam.apiValue;

      if (_visitAgent.isNotEmpty) {
        submitData['Visit_Agent'] = _visitAgent;
      }

      if (_visitAgentTeamLead.isNotEmpty) {
        submitData['Visit_Agent_Team_Lead'] = _visitAgentTeamLead;
      }

      // Submit to Skorcard API
      final success = await _apiService.submitContactability(submitData);

      if (success) {
        _setLoadingState(ContactabilityLoadingState.submitted);
        _resetForm();
        return true;
      } else {
        _setError('Failed to submit contactability');
        return false;
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  // Get contactability by ID
  Future<void> getContactabilityById(String id) async {
    try {
      _setLoadingState(ContactabilityLoadingState.loading);

      final response =
          await _contactabilityRepository.getContactabilityById(id);

      if (response.success && response.data != null) {
        _selectedContactability = response.data!;
        _setLoadingState(ContactabilityLoadingState.loaded);
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  // Form methods
  void setSelectedChannel(ContactabilityChannel channel) {
    _selectedChannel = channel;
    notifyListeners();
  }

  void setSelectedResult(ContactabilityResult result) {
    _selectedResult = result;
    notifyListeners();
  }

  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  // New form methods for enhanced contactability
  void setSelectedVisitAction(VisitAction? action) {
    _selectedVisitAction = action;
    notifyListeners();
  }

  void setSelectedVisitStatus(VisitStatus? status) {
    _selectedVisitStatus = status;
    notifyListeners();
  }

  void setSelectedContactResult(ContactResult? result) {
    _selectedContactResult = result;
    notifyListeners();
  }

  void setSelectedVisitLocation(VisitLocation? location) {
    _selectedVisitLocation = location;
    notifyListeners();
  }

  void setSelectedVisitBySkorTeam(VisitBySkorTeam value) {
    _selectedVisitBySkorTeam = value;
    notifyListeners();
  }

  void setVisitNotes(String notes) {
    _visitNotes = notes;
    notifyListeners();
  }

  void setVisitAgent(String agent) {
    _visitAgent = agent;
    notifyListeners();
  }

  void setVisitAgentTeamLead(String teamLead) {
    _visitAgentTeamLead = teamLead;
    notifyListeners();
  }

  void _resetForm() {
    _selectedChannel = ContactabilityChannel.call;
    _selectedResult = null;
    _notes = '';
    _selectedVisitAction = null;
    _selectedVisitStatus = null;
    _selectedContactResult = null;
    _selectedVisitLocation = null;
    _selectedVisitBySkorTeam = VisitBySkorTeam.yes;
    _visitNotes = '';
    _visitAgent = '';
    _visitAgentTeamLead = '';
    _contactabilityDateTime = DateTime.now();
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await _getCurrentLocation();
    await loadContactabilityHistory(refresh: true);
  }

  // Clear selection
  void clearSelection() {
    _selectedContactability = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset state
  void reset() {
    _loadingState = ContactabilityLoadingState.initial;
    _contactabilityHistory.clear();
    _selectedContactability = null;
    _errorMessage = null;
    _paginationMeta = null;
    _clientId = null;
    _currentPage = 1;
    _resetForm();
    notifyListeners();
  }

  // Private methods
  void _setLoadingState(ContactabilityLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void _setError(String message) {
    _loadingState = ContactabilityLoadingState.error;
    _errorMessage = message;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    return 'An unexpected error occurred';
  }

  // Helper method for getting channel API value
  String _getChannelApiValue(ContactabilityChannel channel) {
    switch (channel) {
      case ContactabilityChannel.call:
        return 'Call';
      case ContactabilityChannel.message:
        return 'Message';
      case ContactabilityChannel.visit:
        return 'Field Visit';
    }
  }
}
