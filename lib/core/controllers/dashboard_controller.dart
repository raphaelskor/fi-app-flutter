import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../exceptions/app_exception.dart';

enum DashboardLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class DashboardController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService;

  // Constructor
  DashboardController(this._authService);

  // State
  DashboardLoadingState _loadingState = DashboardLoadingState.initial;
  Map<String, int> _performanceData = {
    'visit': 0,
    'call': 0,
    'message': 0,
    'rpc': 0,
    'tpc': 0,
    'opc': 0,
    'ptp_all_time': 0,
    'ptp_this_month': 0,
  };
  String? _errorMessage;
  DateTime? _lastRefresh;

  // Getters
  DashboardLoadingState get loadingState => _loadingState;
  Map<String, int> get performanceData => _performanceData;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == DashboardLoadingState.loading;
  DateTime? get lastRefresh => _lastRefresh;

  // Load dashboard performance data
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    try {
      _setLoadingState(DashboardLoadingState.loading);

      // Get user email from auth service
      final userEmail = _authService.userData?['email'] as String?;
      if (userEmail == null || userEmail.isEmpty) {
        _setError('User email not available');
        return;
      }

      debugPrint(
          '🔄 Loading dashboard data for user: $userEmail ${forceRefresh ? '(force refresh)' : '(cached if available)'}');

      // Fetch dashboard data from API
      final Map<String, dynamic> responseData =
          await _apiService.getDashboardPerformance(
        fiOwnerEmail: userEmail,
        forceRefresh: forceRefresh,
      );

      // The API service already processes and maps the data to correct field names
      // responseData contains mapped fields: 'visit', 'call', 'message', etc.
      _performanceData = {
        'visit': responseData['visit'] ?? 0,
        'call': responseData['call'] ?? 0,
        'message': responseData['message'] ?? 0,
        'rpc': responseData['rpc'] ?? 0,
        'tpc': responseData['tpc'] ?? 0,
        'opc': responseData['opc'] ?? 0,
        'ptp_all_time': responseData['ptp_all_time'] ?? 0,
        'ptp_this_month': responseData['ptp_this_month'] ?? 0,
      };

      _lastRefresh = DateTime.now();

      debugPrint('✅ Dashboard data loaded successfully: $_performanceData');
      debugPrint(
          '📊 Individual counts: Visit=${_performanceData['visit']}, Call=${_performanceData['call']}, Message=${_performanceData['message']}, RPC=${_performanceData['rpc']}, TPC=${_performanceData['tpc']}, OPC=${_performanceData['opc']}, PTP All=${_performanceData['ptp_all_time']}, PTP Month=${_performanceData['ptp_this_month']}');
      _setLoadingState(DashboardLoadingState.loaded);
    } catch (e) {
      debugPrint('❌ Error loading dashboard data: $e');
      _setError(_getErrorMessage(e));
    }
  }

  // Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData(forceRefresh: true);
  }

  // Manual refresh method for pull-to-refresh
  Future<void> manualRefresh() async {
    debugPrint('🔄 Manual refresh triggered');
    await refresh();
  }

  // Calculate ratio
  double calculateRatio(int numerator, int denominator) {
    if (denominator == 0) return 0.0;
    return (numerator / denominator) * 100;
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private methods
  void _setLoadingState(DashboardLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void _setError(String message) {
    _loadingState = DashboardLoadingState.error;
    _errorMessage = message;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    return 'An unexpected error occurred';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
