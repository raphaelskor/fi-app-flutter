import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/client_id_mapping_service.dart';
import '../services/client_location_cache_service.dart';
import '../exceptions/app_exception.dart';
import '../models/contactability_history.dart';
import '../utils/timezone_utils.dart';

enum ClientContactabilityHistoryLoadingState {
  initial,
  loading,
  loaded,
  error,
  refreshing,
}

class ClientContactabilityHistoryItem {
  final String id;
  final String clientName;
  final String channel;
  final String contactResult;
  final String notes;
  final DateTime createdTime;
  final DateTime? contactDate; // New field for contact date
  final String? visitLocation;
  final String? visitAction;
  final String? visitStatus;
  final String? ptpAmount;
  final String? ptpDate;
  final String? reachability;
  final Map<String, dynamic> rawData;

  ClientContactabilityHistoryItem({
    required this.id,
    required this.clientName,
    required this.channel,
    required this.contactResult,
    required this.notes,
    required this.createdTime,
    this.contactDate,
    this.visitLocation,
    this.visitAction,
    this.visitStatus,
    this.ptpAmount,
    this.ptpDate,
    this.reachability,
    required this.rawData,
  });

  factory ClientContactabilityHistoryItem.fromJson(Map<String, dynamic> json) {
    // Extract client name from User_ID field
    String clientName = 'Unknown Client';
    if (json['User_ID'] != null && json['User_ID']['name'] != null) {
      clientName = json['User_ID']['name'];
    }

    // Extract notes - semua channel menggunakan Visit_Notes
    String notes = json['Visit_Notes']?.toString() ?? '';

    // Parse created time with Jakarta timezone
    DateTime createdTime = TimezoneUtils.nowInJakarta();
    if (json['Created_Time'] != null) {
      try {
        createdTime = TimezoneUtils.parseApiDateTime(json['Created_Time']);
      } catch (e) {
        print('Error parsing Created_Time: $e');
      }
    }

    // Parse contact date - prioritize Contact_Date over Created_Time
    DateTime? contactDate;
    if (json['Contact_Date'] != null) {
      try {
        contactDate = TimezoneUtils.parseApiDateTime(json['Contact_Date']);
      } catch (e) {
        print('Error parsing Contact_Date: $e');
        // Fallback to created time if Contact_Date fails
        contactDate = createdTime;
      }
    } else {
      // If no Contact_Date, use Created_Time as contact date
      contactDate = createdTime;
    }

    // Extract contact result from various fields
    String contactResult = json['Contact_Result']?.toString() ??
        json['If_not_Connected']?.toString() ??
        json['Reachability']?.toString() ??
        'Unknown';

    return ClientContactabilityHistoryItem(
      id: json['id']?.toString() ?? '',
      clientName: clientName,
      channel: json['Channel']?.toString() ?? 'Unknown',
      contactResult: contactResult,
      notes: notes,
      createdTime: createdTime,
      contactDate: contactDate,
      visitLocation: json['Visit_Location']?.toString(),
      visitAction:
          json['Vist_Action']?.toString() ?? json['Visit_Action']?.toString(),
      visitStatus: json['Visit_Status']?.toString(),
      ptpAmount: json['P2P_Amount']?.toString(),
      ptpDate: json['P2P_Date']?.toString(),
      reachability: json['Reachability']?.toString(),
      rawData: json,
    );
  }

  // Convert to ContactabilityHistory for compatibility
  ContactabilityHistory toContactabilityHistory() {
    // Create ContactabilityHistory directly using parsed data to ensure consistency
    DateTime? modifiedTime;
    DateTime? visitDate;

    try {
      if (rawData['Modified_Time'] != null) {
        modifiedTime = TimezoneUtils.parseApiDateTime(rawData['Modified_Time']);
      }
      if (rawData['Visit_Date'] != null) {
        visitDate = TimezoneUtils.parseApiDateTime(rawData['Visit_Date']);
      }
    } catch (e) {
      print('Error parsing dates in toContactabilityHistory: $e');
    }

    return ContactabilityHistory(
      id: id,
      skorUserId: rawData['Skor_User_ID']?.toString() ?? '',
      name: clientName,
      channel: channel,
      status: visitStatus,
      result: contactResult,
      notes: notes,
      visitLocation: visitLocation,
      visitAgent: rawData['Visit_Agent']?.toString(),
      visitLatLong: rawData['Visit_Lat_Long']?.toString(),
      createdTime: createdTime,
      modifiedTime: modifiedTime,
      visitDate: visitDate,
      contactDate: contactDate, // Use the already parsed contactDate
      dpdbucket: rawData['DPD_Bucket']?.toString(),
      contactResult: contactResult,
      messageSentFor: rawData['Message_Sent_For']?.toString(),
      deliveredTimeIfAny: rawData['Delivered_Time_If_Any']?.toString(),
      readTimeIfAny: rawData['Read_Time_If_Any']?.toString(),
      rawData: rawData,
    );
  }
}

class ClientContactabilityHistoryController extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;

  ClientContactabilityHistoryLoadingState _loadingState =
      ClientContactabilityHistoryLoadingState.initial;
  List<ClientContactabilityHistoryItem> _historyItems = [];
  String? _errorMessage;

  ClientContactabilityHistoryController(this._apiService, this._authService);

  // Getters
  ClientContactabilityHistoryLoadingState get loadingState => _loadingState;
  List<ClientContactabilityHistoryItem> get historyItems => _historyItems;
  String? get errorMessage => _errorMessage;
  bool get isLoading =>
      _loadingState == ClientContactabilityHistoryLoadingState.loading;
  bool get isRefreshing =>
      _loadingState == ClientContactabilityHistoryLoadingState.refreshing;

  // Load contactability history
  Future<void> loadHistory({bool refresh = false}) async {
    if (refresh) {
      _setLoadingState(ClientContactabilityHistoryLoadingState.refreshing);
    } else {
      _setLoadingState(ClientContactabilityHistoryLoadingState.loading);
    }

    _clearError();

    try {
      // Get user email from AuthService
      final userEmail = _authService.userData?['email'] as String?;
      if (userEmail == null || userEmail.isEmpty) {
        throw Exception('User email not found. Please login again.');
      }

      final response = await _apiService.getAgentContactabilityHistory(
        fiOwnerEmail: userEmail,
      );

      final List<dynamic> dataList = response['data'] ?? [];

      // Extract Client ID -> Skor User ID mappings from the response
      await _extractAndStoreClientIdMappings(dataList);

      // Update cache with correct Client IDs
      await _updateLocationCacheWithClientIds();

      final newItems = dataList
          .map((item) => ClientContactabilityHistoryItem.fromJson(item))
          .toList();

      _historyItems = newItems;
      _setLoadingState(ClientContactabilityHistoryLoadingState.loaded);
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await loadHistory(refresh: true);
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Extract and store Client ID -> Skor User ID mappings from contactability data
  Future<void> _extractAndStoreClientIdMappings(List<dynamic> dataList) async {
    try {
      final Map<String, String> mappings = {}; // skorUserId -> clientId

      debugPrint(
          '🔍 Extracting Client ID mappings from contactability data...');
      debugPrint('📦 Data structure: ${dataList.length} items');

      for (int i = 0; i < dataList.length; i++) {
        final item = dataList[i];
        debugPrint('📦 Item $i: ${item.runtimeType}');

        if (item is Map<String, dynamic>) {
          // Debug the structure
          debugPrint('📦 Item $i keys: ${item.keys.toList()}');

          // Look for 'data' array in each item (based on user's example structure)
          final List<dynamic>? clientDataArray = item['data'];

          if (clientDataArray != null) {
            debugPrint(
                '📦 Found data array with ${clientDataArray.length} items');

            for (int j = 0; j < clientDataArray.length; j++) {
              final clientData = clientDataArray[j];
              debugPrint('📦 Data[$j]: ${clientData.runtimeType}');

              if (clientData is Map<String, dynamic>) {
                debugPrint('📦 Data[$j] keys: ${clientData.keys.toList()}');

                final String? clientId = clientData['id']?.toString();
                final String? skorUserId = clientData['User_ID']?.toString();

                debugPrint('📦 Data[$j] - id: $clientId, User_ID: $skorUserId');

                if (clientId != null &&
                    clientId.isNotEmpty &&
                    skorUserId != null &&
                    skorUserId.isNotEmpty &&
                    clientId.toLowerCase() != 'null' &&
                    skorUserId.toLowerCase() != 'null') {
                  // FIXED: Store as skorUserId -> clientId mapping
                  mappings[skorUserId] = clientId;
                  debugPrint(
                      '🔗 Found mapping: Skor User ID $skorUserId → Client ID $clientId');
                }
              }
            }
          } else {
            debugPrint('📦 No data array found in item $i');
          }
        }
      }

      if (mappings.isNotEmpty) {
        final mappingService = ClientIdMappingService.instance;
        await mappingService.storeClientIdMapping(mappings);
        debugPrint(
            '✅ Stored ${mappings.length} Client ID mappings from contactability data');

        // Debug stored mappings
        for (final entry in mappings.entries) {
          debugPrint('💾 Stored: ${entry.key} → ${entry.value}');
        }
      } else {
        debugPrint(
            '⚠️ No valid Client ID mappings found in contactability data');
      }
    } catch (e) {
      debugPrint('❌ Error extracting Client ID mappings: $e');
    }
  }

  // Update location cache with correct Client IDs using mapping service
  Future<void> _updateLocationCacheWithClientIds() async {
    try {
      final cacheService = ClientLocationCacheService.instance;
      await cacheService.updateClientIdInCache();
      debugPrint('✅ Location cache updated with correct Client IDs');
    } catch (e) {
      debugPrint('❌ Error updating location cache with Client IDs: $e');
    }
  }

  // Private methods
  void _setLoadingState(ClientContactabilityHistoryLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void _setError(String message) {
    _loadingState = ClientContactabilityHistoryLoadingState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    // Handle FormatException from empty response body
    if (error is FormatException) {
      if (error.message.contains('Unexpected end of input')) {
        return 'No contactability history available yet';
      }
      return 'Invalid data format received from server';
    }

    // Handle network-related errors
    if (error.toString().contains('No internet connection')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error.toString().contains('User email not found')) {
      return 'Please login again to view your history';
    }

    return 'Unable to load history. Please try again later.';
  }

  // Format helpers - ensure dates are in Jakarta timezone
  String formatDate(DateTime date) {
    return TimezoneUtils.formatDate(date);
  }

  String formatTime(DateTime date) {
    return TimezoneUtils.formatTime(date);
  }

  String formatDateTime(DateTime date) {
    return TimezoneUtils.formatDateTime(date);
  }
}
