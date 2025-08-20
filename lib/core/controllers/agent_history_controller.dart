import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../exceptions/app_exception.dart';
import '../models/contactability_history.dart';

enum AgentHistoryLoadingState {
  initial,
  loading,
  loaded,
  error,
  loadingMore,
}

class AgentHistoryItem {
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
  final Map<String, dynamic> rawData; // Added rawData field

  AgentHistoryItem({
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
    required this.rawData, // Added rawData field
  });

  factory AgentHistoryItem.fromJson(Map<String, dynamic> json) {
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

    // Parse created time
    DateTime createdTime = DateTime.now();
    if (json['Created_Time'] != null) {
      try {
        createdTime = DateTime.parse(json['Created_Time']);
      } catch (e) {
        print('Error parsing Created_Time: $e');
      }
    }

    // Extract contact result from various fields
    String contactResult = json['Contact_Result']?.toString() ??
        json['If_not_Connected']?.toString() ??
        json['Reachability']?.toString() ??
        'Unknown';

    return AgentHistoryItem(
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
      rawData: json, // Added rawData field
    );
  }

  // Convert to ContactabilityHistory for use in details screen
  ContactabilityHistory toContactabilityHistory() {
    return ContactabilityHistory.fromSkorcardApi(rawData);
  }
}

class AgentHistoryController extends ChangeNotifier {
  final ApiService _apiService;

  AgentHistoryLoadingState _loadingState = AgentHistoryLoadingState.initial;
  List<AgentHistoryItem> _historyItems = [];
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMoreRecords = false;
  final String _agentEmail = 'rosita@skor.co'; // Default agent email

  AgentHistoryController(this._apiService);

  // Getters
  AgentHistoryLoadingState get loadingState => _loadingState;
  List<AgentHistoryItem> get historyItems => _historyItems;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == AgentHistoryLoadingState.loading;
  bool get isLoadingMore =>
      _loadingState == AgentHistoryLoadingState.loadingMore;
  bool get hasMoreRecords => _hasMoreRecords;

  // Load initial history
  Future<void> loadHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _historyItems.clear();
    }

    _setLoadingState(AgentHistoryLoadingState.loading);
    _clearError();

    try {
      final response = await _apiService.getAgentContactabilityHistory(
        agentEmail: _agentEmail,
        page: _currentPage,
        perPage: 20,
      );

      final List<dynamic> dataList = response['data'] ?? [];
      final Map<String, dynamic> info = response['info'] ?? {};

      final newItems =
          dataList.map((item) => AgentHistoryItem.fromJson(item)).toList();

      if (refresh) {
        _historyItems = newItems;
      } else {
        _historyItems.addAll(newItems);
      }

      _hasMoreRecords = info['more_records'] == true;
      _setLoadingState(AgentHistoryLoadingState.loaded);
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  // Load more history (pagination)
  Future<void> loadMore() async {
    if (!_hasMoreRecords || isLoadingMore) return;

    _setLoadingState(AgentHistoryLoadingState.loadingMore);
    _currentPage++;

    try {
      final response = await _apiService.getAgentContactabilityHistory(
        agentEmail: _agentEmail,
        page: _currentPage,
        perPage: 20,
      );

      final List<dynamic> dataList = response['data'] ?? [];
      final Map<String, dynamic> info = response['info'] ?? {};

      final newItems =
          dataList.map((item) => AgentHistoryItem.fromJson(item)).toList();
      _historyItems.addAll(newItems);

      _hasMoreRecords = info['more_records'] == true;
      _setLoadingState(AgentHistoryLoadingState.loaded);
    } catch (e) {
      _currentPage--; // Revert page increment on error
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
  void _setLoadingState(AgentHistoryLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void _setError(String message) {
    _loadingState = AgentHistoryLoadingState.error;
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
    return 'An unexpected error occurred';
  }

  // Format helpers
  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
