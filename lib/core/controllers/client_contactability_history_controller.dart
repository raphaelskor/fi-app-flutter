import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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

    // Extract notes based on channel type
    String notes = '';
    final channel = json['Channel']?.toString() ?? '';
    switch (channel.toLowerCase()) {
      case 'call':
        notes = json['Call_Notes']?.toString() ?? '';
        break;
      case 'field visit':
      case 'visit':
        notes = json['Visit_Notes']?.toString() ?? '';
        break;
      case 'message':
        notes = json['Agent_WA_Notes']?.toString() ?? '';
        break;
      default:
        notes = json['Call_Notes']?.toString() ??
            json['Visit_Notes']?.toString() ??
            json['Agent_WA_Notes']?.toString() ??
            '';
    }

    // Parse created time with Jakarta timezone
    DateTime createdTime = TimezoneUtils.nowInJakarta();
    if (json['Created_Time'] != null) {
      try {
        createdTime = TimezoneUtils.parseApiDateTime(json['Created_Time']);
      } catch (e) {
        print('Error parsing Created_Time: $e');
      }
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
    return ContactabilityHistory.fromSkorcardApi(rawData);
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
