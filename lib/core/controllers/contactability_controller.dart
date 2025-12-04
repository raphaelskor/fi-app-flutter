import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/contactability.dart';
import '../models/contactability_history.dart';
import '../models/api_models.dart';
import '../repositories/client_repository.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/client_location_cache_service.dart';
import '../exceptions/app_exception.dart';
import '../services/location_service.dart';
import '../utils/timezone_utils.dart';
import 'package:geolocator/geolocator.dart';

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
  final AuthService _authService;

  // State
  ContactabilityLoadingState _loadingState = ContactabilityLoadingState.initial;
  List<ContactabilityHistory> _contactabilityHistory = [];
  Contactability? _selectedContactability;
  String? _errorMessage;
  PaginationMeta? _paginationMeta;

  // Constructor
  ContactabilityController(this._authService);

  // Form state
  String? _clientId;
  String? _skorUserId; // Add Skor User ID for API calls
  ContactabilityChannel _selectedChannel = ContactabilityChannel.call;
  ContactabilityResult? _selectedResult;
  String _notes = '';
  Position? _currentLocation;

  // New form fields for enhanced contactability
  ContactResult? _selectedContactResult;
  VisitBySkorTeam _selectedVisitBySkorTeam = VisitBySkorTeam.yes;
  PersonContacted? _selectedPersonContacted;
  ActionLocation? _selectedActionLocation;
  String _visitNotes = '';
  String _visitAgent = '';
  String _visitAgentTeamLead = '';
  String _newPhoneNumber = '';
  String _newAddress = '';
  DateTime? _contactabilityDateTime;

  // Image handling for visits
  List<File> _selectedImages = [];

  // Pagination
  int _currentPage = 1;

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
  ContactResult? get selectedContactResult => _selectedContactResult;
  VisitBySkorTeam get selectedVisitBySkorTeam => _selectedVisitBySkorTeam;
  PersonContacted? get selectedPersonContacted => _selectedPersonContacted;
  ActionLocation? get selectedActionLocation => _selectedActionLocation;
  String get visitNotes => _visitNotes;
  String get visitAgent => _visitAgent;
  String get visitAgentTeamLead => _visitAgentTeamLead;
  String get newPhoneNumber => _newPhoneNumber;
  String get newAddress => _newAddress;
  DateTime? get contactabilityDateTime => _contactabilityDateTime;
  List<File> get selectedImages => _selectedImages;

  // Initialize
  Future<void> initialize(String clientId, {String? skorUserId}) async {
    // Clear previous data immediately to prevent data mixing
    _contactabilityHistory.clear();
    _currentPage = 1;
    _errorMessage = null;
    _setLoadingState(ContactabilityLoadingState.initial);

    _clientId = clientId;
    _skorUserId = skorUserId;
    // Set current date/time in Jakarta timezone (GMT+7)
    _contactabilityDateTime = TimezoneUtils.nowInJakarta();

    debugPrint(
        '🔄 Initializing ContactabilityController for client: $clientId with skorUserId: $skorUserId');
    debugPrint(
        '📅 Contactability DateTime set to: $_contactabilityDateTime (${TimezoneUtils.getTimezoneDisplay()})');

    await _getCurrentLocation();
    await loadContactabilityHistory(
        refresh: true); // Force refresh to ensure clean data
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
    // Determine which ID to use for the API call
    String? apiCallId = _clientId;

    // If clientId is empty/null/invalid, try to use skorUserId
    if (apiCallId == null ||
        apiCallId.isEmpty ||
        apiCallId.toLowerCase() == 'null') {
      apiCallId = _skorUserId;
      debugPrint(
          '⚠️ Client ID is invalid, trying skorUserId instead: $apiCallId');
    }

    if (apiCallId == null || apiCallId.isEmpty) {
      debugPrint(
          '❌ No valid ID available for contactability history: clientId=$_clientId, skorUserId=$_skorUserId');
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

      debugPrint(
          '📡 Fetching contactability history for ID: $apiCallId (clientId=$_clientId, skorUserId=$_skorUserId)');

      // Fetch data from Skorcard API with error handling
      final List<Map<String, dynamic>> rawHistory;
      try {
        // Get team and email from user data
        final userTeam = _authService.userData?['team']?.toString();
        final userEmail = _authService.userData?['email']?.toString();
        rawHistory = await _apiService.fetchContactabilityHistory(
          apiCallId,
          team: userTeam,
          email: userEmail,
        );
        debugPrint(
            '✅ Fetched ${rawHistory.length} contactability records for $apiCallId');
      } catch (apiError) {
        debugPrint('❌ API Error fetching contactability history: $apiError');
        _contactabilityHistory.clear();
        _setLoadingState(ContactabilityLoadingState.loaded);
        return;
      }

      // Convert to ContactabilityHistory objects with error handling
      final List<ContactabilityHistory> historyList = [];
      String? realClientId; // Store the real Client ID from contactability data

      for (final item in rawHistory) {
        try {
          final history = ContactabilityHistory.fromSkorcardApi(item);
          historyList.add(history);

          // Extract the real Client ID from the first contactability record
          if (realClientId == null && item['id'] != null) {
            realClientId = item['id']?.toString();
            debugPrint(
                '🔍 Found real Client ID from contactability data: $realClientId');
          }
        } catch (e) {
          debugPrint('Error parsing contactability history item: $e');
          // Skip this item and continue with others
        }
      }

      // If we found a real Client ID and have SkorUserId, update the location cache
      if (realClientId != null &&
          realClientId.isNotEmpty &&
          _skorUserId != null &&
          _skorUserId!.isNotEmpty) {
        debugPrint(
            '🔄 Updating location cache with real Client ID: $realClientId');

        try {
          final cacheService = ClientLocationCacheService.instance;
          final cachedData =
              await cacheService.getCachedClientLocationData(_skorUserId!);

          if (cachedData != null) {
            // Re-cache the data with the correct Client ID
            await cacheService.cacheClientLocationData(
              skorUserId: _skorUserId!,
              locations: cachedData.locations,
              addresses: cachedData.addresses,
              clientId: realClientId,
              clientName: cachedData.clientName,
              clientPhone: cachedData.clientPhone,
            );
            debugPrint(
                '✅ Updated location cache with real Client ID: $realClientId');
          }
        } catch (e) {
          debugPrint('❌ Error updating location cache with real Client ID: $e');
        }
      }

      // Sort by created time (newest first)
      historyList.sort((a, b) => b.createdTime.compareTo(a.createdTime));

      if (refresh) {
        _contactabilityHistory = historyList;
      } else {
        _contactabilityHistory.addAll(historyList);
      }

      debugPrint(
          '📊 Final contactability history count: ${_contactabilityHistory.length}');
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
    if (_clientId == null || _clientId!.isEmpty) {
      _setError('Client ID not available');
      return false;
    }

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
        'id': _clientId!, // Add client ID as required by API
        'User_ID': _skorUserId!,
        'Channel': _getChannelApiValue(_selectedChannel),
      };

      // Add FI_Owner from user login
      final userEmail = _authService.userData?['email'] as String?;
      if (userEmail != null && userEmail.isNotEmpty) {
        submitData['FI_Owner'] = userEmail;
      }

      // Add location if available
      if (_currentLocation != null) {
        submitData['Visit_Lat_Long'] =
            '${_currentLocation!.latitude},${_currentLocation!.longitude}';
      }

      if (_selectedContactResult != null) {
        submitData['Contact_Result'] = _selectedContactResult!.apiValue;

        // Add PTP fields if contact result is PTP
        if (_selectedContactResult == ContactResult.ptp) {
          if (ptpAmount != null && ptpAmount.isNotEmpty) {
            submitData['P2p_Amount'] = ptpAmount;
          }
          if (ptpDate != null) {
            // Format date as YYYY-MM-DD for API using Jakarta timezone
            submitData['P2p_Date'] = TimezoneUtils.formatDateForApi(ptpDate);
            debugPrint(
                '📅 PTP Date formatted for API: ${TimezoneUtils.formatDateForApi(ptpDate)} (${TimezoneUtils.getTimezoneDisplay()})');
          }
        }
      }

      // Add required Person Contacted field
      if (_selectedPersonContacted != null) {
        submitData['Person_Contacted'] = _selectedPersonContacted!.apiValue;
      }

      // Add required Action Location field
      if (_selectedActionLocation != null) {
        submitData['Action_Location'] = _selectedActionLocation!.apiValue;
      }

      // Add optional new phone number field
      if (_newPhoneNumber.trim().isNotEmpty) {
        submitData['New_Phone_Number'] = _newPhoneNumber.trim();
      }

      // Add optional new address field
      if (_newAddress.trim().isNotEmpty) {
        submitData['New_Address'] = _newAddress.trim();
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
      final bool success;
      if (_selectedImages.isNotEmpty &&
          (_selectedChannel == ContactabilityChannel.visit ||
              _selectedChannel == ContactabilityChannel.message)) {
        // Use multipart API for visits and messages with images
        success = await _apiService.submitContactabilityWithImages(
          data: submitData,
          images: _selectedImages,
        );
      } else {
        // Use regular JSON API for other cases
        success = await _apiService.submitContactability(submitData);
      }

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
  void setSelectedContactResult(ContactResult? result) {
    _selectedContactResult = result;
    notifyListeners();
  }

  void setSelectedVisitBySkorTeam(VisitBySkorTeam value) {
    _selectedVisitBySkorTeam = value;
    notifyListeners();
  }

  void setSelectedPersonContacted(PersonContacted? person) {
    _selectedPersonContacted = person;
    notifyListeners();
  }

  void setSelectedActionLocation(ActionLocation? location) {
    _selectedActionLocation = location;
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

  void setNewPhoneNumber(String phoneNumber) {
    _newPhoneNumber = phoneNumber;
    notifyListeners();
  }

  void setNewAddress(String address) {
    _newAddress = address;
    notifyListeners();
  }

  // Image management methods
  void addImage(File image, {int maxImages = 3}) {
    if (_selectedImages.length < maxImages) {
      _selectedImages.add(image);
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  void clearImages() {
    _selectedImages.clear();
    notifyListeners();
  }

  void _resetForm() {
    _selectedChannel = ContactabilityChannel.call;
    _selectedResult = null;
    _notes = '';
    _selectedContactResult = null;
    _selectedVisitBySkorTeam = VisitBySkorTeam.yes;
    _visitNotes = '';
    _visitAgent = '';
    _visitAgentTeamLead = '';
    _newPhoneNumber = '';
    _newAddress = '';
    _selectedImages.clear();
    _contactabilityDateTime = TimezoneUtils.nowInJakarta();
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await _getCurrentLocation();
    await loadContactabilityHistory(refresh: true);
  }

  // Refresh location only
  Future<void> refreshLocation() async {
    await _getCurrentLocation();
    notifyListeners();
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

  // Clear all data (useful when switching clients)
  void clearData() {
    _contactabilityHistory.clear();
    _selectedContactability = null;
    _errorMessage = null;
    _currentPage = 1;
    _clientId = null;
    _skorUserId = null;
    _setLoadingState(ContactabilityLoadingState.initial);
    debugPrint('🧹 Cleared all contactability data');
  }

  @override
  void dispose() {
    clearData();
    super.dispose();
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
