class EnvConfig {
  static const String _baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String _apiVersion = String.fromEnvironment(
    'API_VERSION',
    defaultValue: 'v1',
  );

  static String get baseUrl => _baseUrl;
  static String get apiUrl => '$_baseUrl/api/$_apiVersion';

  // API Endpoints
  static String get clientsEndpoint => '$apiUrl/clients';
  static String get contactabilityEndpoint => '$apiUrl/contactability';
  static String get locationsEndpoint => '$apiUrl/locations';
  static String get authEndpoint => '$apiUrl/auth';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
