import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../exceptions/app_exception.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late http.Client _client;
  String? _authToken;

  void initialize() {
    _client = http.Client();
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(EnvConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException(
        message: 'No internet connection',
        statusCode: 0,
      );
    } on HttpException {
      throw const NetworkException(
        message: 'Network error occurred',
        statusCode: 0,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
        message: 'Unexpected error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(EnvConfig.sendTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException(
        message: 'No internet connection',
        statusCode: 0,
      );
    } on HttpException {
      throw const NetworkException(
        message: 'Network error occurred',
        statusCode: 0,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
        message: 'Unexpected error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);

      final response = await _client
          .put(
            uri,
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(EnvConfig.sendTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException(
        message: 'No internet connection',
        statusCode: 0,
      );
    } on HttpException {
      throw const NetworkException(
        message: 'Network error occurred',
        statusCode: 0,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
        message: 'Unexpected error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);

      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(EnvConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException(
        message: 'No internet connection',
        statusCode: 0,
      );
    } on HttpException {
      throw const NetworkException(
        message: 'Network error occurred',
        statusCode: 0,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
        message: 'Unexpected error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParams) {
    final uri = Uri.parse('${EnvConfig.baseUrl}$endpoint');

    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(
          queryParameters: queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      ));
    }

    return uri;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw const ServerException(
          message: 'Invalid response format',
          statusCode: 500,
        );
      }
    }

    final responseBody = _tryParseErrorResponse(response.body);
    final errorMessage = responseBody['message'] ?? 'Unknown error occurred';

    switch (statusCode) {
      case 400:
        throw ValidationException(
          message: errorMessage,
          statusCode: statusCode,
          details: responseBody['errors']?.toString(),
        );
      case 401:
        throw UnauthorizedException(
          message: errorMessage,
          statusCode: statusCode,
        );
      case 403:
        throw ForbiddenException(
          message: errorMessage,
          statusCode: statusCode,
        );
      case 404:
        throw NotFoundException(
          message: errorMessage,
          statusCode: statusCode,
        );
      case 408:
        throw const TimeoutException(
          message: 'Request timeout',
          statusCode: 408,
        );
      case 500:
      case 501:
      case 502:
      case 503:
        throw ServerException(
          message: errorMessage,
          statusCode: statusCode,
        );
      default:
        throw NetworkException(
          message: errorMessage,
          statusCode: statusCode,
        );
    }
  }

  Map<String, dynamic> _tryParseErrorResponse(String responseBody) {
    try {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      return {'message': responseBody};
    }
  }

  // Skorcard API specific methods
  Future<List<Map<String, dynamic>>> fetchSkorcardClients(
      String userName) async {
    try {
      // Build URL with full_name parameter directly in the path
      const String baseUrl =
          'https://n8n.skorcard.app/webhook/a307571b-e8c4-45d2-9244-b40305896648';
      final String url = '$baseUrl?full_name=$userName';

      print('🔄 Calling Skorcard API with userName: $userName');
      print('🔗 URL: $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(EnvConfig.receiveTimeout);

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body Length: ${response.body.length}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response body is empty
        if (response.body.isEmpty) {
          print('⚠️ Empty response body');
          return [];
        }

        // Check if response body starts with valid JSON
        final trimmedBody = response.body.trim();
        if (!trimmedBody.startsWith('[') && !trimmedBody.startsWith('{')) {
          print('⚠️ Response is not valid JSON: $trimmedBody');
          return [];
        }

        try {
          final dynamic parsedResponse = jsonDecode(response.body);
          print('✅ Successfully parsed JSON: ${parsedResponse.runtimeType}');

          // Handle different response types
          List<dynamic> responseData;
          if (parsedResponse is List) {
            responseData = parsedResponse;
          } else if (parsedResponse is Map<String, dynamic> &&
              parsedResponse['data'] != null) {
            responseData = [parsedResponse];
          } else {
            print('⚠️ Unexpected response format: $parsedResponse');
            return [];
          }

          // Extract client data from complex response structure
          final List<Map<String, dynamic>> clients = [];

          for (final item in responseData) {
            if (item is Map<String, dynamic> && item['data'] != null) {
              final List<dynamic> dataList = item['data'];
              for (final clientData in dataList) {
                if (clientData is Map<String, dynamic>) {
                  clients.add(clientData);

                  // Debug: Print user_ID field to understand the structure
                  if (clients.length == 1) {
                    print('📊 Sample client data structure:');
                    print('   - user_ID: ${clientData['user_ID']}');
                    print('   - User_ID: ${clientData['User_ID']}');
                    print('   - Skor_User_ID: ${clientData['Skor_User_ID']}');
                    print('   - id: ${clientData['id']}');
                    print('   - Available keys: ${clientData.keys.toList()}');
                  }
                }
              }
            }
          }

          print('✅ Found ${clients.length} clients');
          return clients;
        } catch (jsonError) {
          print('❌ JSON Parse Error: $jsonError');
          print('📄 Raw response: ${response.body}');
          return [];
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('📄 Error Body: ${response.body}');
        throw NetworkException(
          message:
              'Failed to fetch clients from Skorcard API: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      print('❌ Socket Exception: $e');
      throw const NetworkException(
        message: 'No internet connection',
        statusCode: 0,
      );
    } on HttpException catch (e) {
      print('❌ HTTP Exception: $e');
      throw const NetworkException(
        message: 'Network error occurred',
        statusCode: 0,
      );
    } catch (e) {
      print('❌ Unexpected Error: $e');
      if (e is AppException) rethrow;
      throw NetworkException(
        message: 'Unexpected error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // Fetch contactability history from Skorcard API
  Future<List<Map<String, dynamic>>> fetchContactabilityHistory(
      String skorUserId) async {
    try {
      // Validate input
      if (skorUserId.isEmpty || skorUserId.toLowerCase() == 'null') {
        print('⚠️ Invalid skorUserId provided: $skorUserId');
        return [];
      }

      print('🔄 Fetching contactability history for user: $skorUserId');

      final String baseUrl =
          'https://n8n.skorcard.app/webhook/0843b27d-6ead-4232-9499-adb2e09cc02e';
      final String fullUrl = '$baseUrl?skor_user_id=$skorUserId';

      print('🌐 Request URL: $fullUrl');

      final response = await _client.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        try {
          final dynamic parsedResponse = json.decode(response.body);
          print('✅ Successfully parsed JSON: ${parsedResponse.runtimeType}');

          List<dynamic> responseData = [];

          // Handle different response formats
          if (parsedResponse is List) {
            responseData = parsedResponse;
          } else if (parsedResponse is Map<String, dynamic> &&
              parsedResponse['data'] != null) {
            responseData = [parsedResponse];
          } else {
            print('⚠️ Unexpected response format: $parsedResponse');
            return [];
          }

          // Extract contactability history data from complex response structure
          final List<Map<String, dynamic>> historyList = [];

          for (final item in responseData) {
            if (item is Map<String, dynamic> && item['data'] != null) {
              final List<dynamic> dataList = item['data'];
              for (final historyData in dataList) {
                if (historyData is Map<String, dynamic>) {
                  historyList.add(historyData);
                }
              }
            }
          }

          print('✅ Found ${historyList.length} contactability records');
          return historyList;
        } catch (jsonError) {
          print('❌ JSON Parse Error: $jsonError');
          print('📄 Raw response: ${response.body}');
          return [];
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('📄 Error Body: ${response.body}');
        throw NetworkException(
          message:
              'Failed to fetch contactability history from Skorcard API: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      print('❌ Socket Exception: $e');
      throw const NetworkException(
        message: 'No internet connection',
        statusCode: 0,
      );
    } on HttpException catch (e) {
      print('❌ HTTP Exception: $e');
      throw const NetworkException(
        message: 'Network error occurred',
        statusCode: 0,
      );
    } catch (e) {
      print('❌ Unexpected Error: $e');
      if (e is AppException) rethrow;
      throw NetworkException(
        message: 'Unexpected error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // Submit contactability to Skorcard API
  Future<bool> submitContactability(Map<String, dynamic> data) async {
    try {
      const String url =
          'https://n8n.skorcard.app/webhook/ff5e7b11-a3df-4367-ba1e-01db140c1ecd';

      print('🔄 Submitting contactability to Skorcard API');
      print('🔗 URL: $url');
      print('📄 Data: $data');

      final response = await _client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Contactability submitted successfully');
        return true;
      } else {
        print('❌ Failed to submit contactability: ${response.statusCode}');
        throw NetworkException(
          message: 'Failed to submit contactability: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      print('❌ Socket Exception: $e');
      throw const NetworkException(
        message: 'No internet connection',
        statusCode: 0,
      );
    } on HttpException catch (e) {
      print('❌ HTTP Exception: $e');
      throw const NetworkException(
        message: 'Network error occurred',
        statusCode: 0,
      );
    } catch (e) {
      print('❌ Unexpected Error: $e');
      if (e is AppException) rethrow;
      throw NetworkException(
        message: 'Unexpected error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
