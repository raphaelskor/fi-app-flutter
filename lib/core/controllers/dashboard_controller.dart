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
    'rpc': 0,
    'tpc': 0,
    'ptp': 0,
    'kp': 0,
    'bp': 0,
  };
  String? _errorMessage;

  // Getters
  DashboardLoadingState get loadingState => _loadingState;
  Map<String, int> get performanceData => _performanceData;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == DashboardLoadingState.loading;

  // Load dashboard performance data
  Future<void> loadDashboardData() async {
    try {
      _setLoadingState(DashboardLoadingState.loading);

      // Get user email from auth service
      final userEmail = _authService.userData?['email'] as String?;
      if (userEmail == null || userEmail.isEmpty) {
        _setError('User email not available');
        return;
      }

      debugPrint('🔄 Loading dashboard data for user: $userEmail');

      // Fetch dashboard data from API
      final Map<String, dynamic> responseData =
          await _apiService.getDashboardPerformance(
        fiOwnerEmail: userEmail,
      );

      // Update performance data
      _performanceData = {
        'visit': responseData['visit'] ?? 0,
        'rpc': responseData['rpc'] ?? 0,
        'tpc': responseData['tpc'] ?? 0,
        'ptp': responseData['ptp'] ?? 0,
        'kp': responseData['kp'] ?? 0,
        'bp': responseData['bp'] ?? 0,
      };

      debugPrint('✅ Dashboard data loaded successfully: $_performanceData');
      debugPrint(
          '📊 Individual counts: Visit=${_performanceData['visit']}, RPC=${_performanceData['rpc']}, TPC=${_performanceData['tpc']}, PTP=${_performanceData['ptp']}, KP=${_performanceData['kp']}, BP=${_performanceData['bp']}');
      _setLoadingState(DashboardLoadingState.loaded);
    } catch (e) {
      debugPrint('❌ Error loading dashboard data: $e');
      _setError(_getErrorMessage(e));
    }
  }

  // Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData();
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
