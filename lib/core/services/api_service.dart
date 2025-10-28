import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../exceptions/app_exception.dart';
import 'cache_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late http.Client _client;
  String? _authToken;
  final CacheService _cache = CacheService();

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
      String fiOwnerEmail) async {
    try {
      // Use POST method with fi_owner in request body
      const String baseUrl =
          'https://n8n.skorcard.app/webhook/a307571b-e8c4-45d2-9244-b40305896648';

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'fi_owner': fiOwnerEmail,
      };

      print('🔄 Calling Skorcard API with fi_owner: $fiOwnerEmail');
      print('🔗 URL: $baseUrl');
      print('📄 Request Body: $requestBody');

      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(EnvConfig.receiveTimeout);

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
                    print(
                        '   - Total_OS_Yesterday1: ${clientData['Total_OS_Yesterday1']}');
                    print('   - Available keys: ${clientData.keys.toList()}');

                    // Debug financial fields specifically
                    final financialFields = [
                      'Total_OS_Yesterday1',
                      'Last_Statement_MAD',
                      'Last_Statement_TAD',
                      'Last_Payment_Amount',
                      'Days_Past_Due',
                      'DPD_Bucket'
                    ];
                    print('📊 Financial fields in API response:');
                    for (String field in financialFields) {
                      print('   - $field: ${clientData[field]}');
                    }
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
      String clientId) async {
    try {
      // Validate input
      if (clientId.isEmpty || clientId.toLowerCase() == 'null') {
        print('⚠️ Invalid clientId provided: $clientId');
        return [];
      }

      print('🔄 Fetching contactability history for client: $clientId');

      final String baseUrl =
          'https://n8n.skorcard.app/webhook/0843b27d-6ead-4232-9499-adb2e09cc02e';

      // Prepare request body with client ID
      final Map<String, dynamic> requestBody = {
        'id': clientId,
      };

      print('🌐 Request URL: $baseUrl');
      print('🔑 Client ID: $clientId');
      print('📄 Request Body: $requestBody');

      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Headers: ${response.headers}');
      print('📄 Response Body Length: ${response.body.length}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          // Check if response body is empty or null
          if (response.body.isEmpty || response.body.trim().isEmpty) {
            print('⚠️ Empty response body from API');
            return [];
          }

          // Check if response is JSON
          final contentType = response.headers['content-type'] ?? '';
          if (!contentType.contains('application/json') &&
              !contentType.contains('text/json')) {
            print('⚠️ Response is not JSON. Content-Type: $contentType');
            print('📄 Response Body: ${response.body}');
            return [];
          }

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
          print('📄 Raw response body length: ${response.body.length}');
          print(
              '📄 Raw response preview: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}');

          // Check for specific error types
          if (jsonError.toString().contains('Unexpected end of input')) {
            print('⚠️ API returned empty or incomplete response');
          } else if (jsonError.toString().contains('Unexpected character')) {
            print('⚠️ API returned non-JSON content');
          }

          // Return empty list instead of throwing error to prevent app crash
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
          'https://n8n-sit.skorcard.app/webhook/95709b0d-0d03-4710-85d5-d72f14359ee4';

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
        // Parse the response to check for success status
        try {
          final List<dynamic> responseList = jsonDecode(response.body);
          if (responseList.isNotEmpty) {
            final responseData = responseList[0];
            if (responseData['data'] != null &&
                responseData['data'].isNotEmpty) {
              final dataItem = responseData['data'][0];
              final status = dataItem['status']?.toString().toLowerCase();
              if (status == 'success') {
                print(
                    '✅ Contactability submitted successfully with SUCCESS status');
                return true;
              } else {
                print('❌ Contactability submission failed - status: $status');
                return false;
              }
            }
          }
          print('❌ Invalid response format from Skorcard API');
          return false;
        } catch (e) {
          print('❌ Error parsing response: $e');
          // If parsing fails but HTTP status is success, still return true
          print('✅ Contactability submitted successfully (fallback)');
          return true;
        }
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

  /// Submit contactability with images using multipart/form-data
  Future<bool> submitContactabilityWithImages({
    required Map<String, dynamic> data,
    List<File>? images,
  }) async {
    try {
      const String url =
          'https://n8n-sit.skorcard.app/webhook/95709b0d-0d03-4710-85d5-d72f14359ee4';

      print('🔄 Submitting contactability with images to Skorcard API');
      print('🔗 URL: $url');
      print('📄 Data: $data');
      print('🖼️ Images count: ${images?.length ?? 0}');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add form fields
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add images
      if (images != null && images.isNotEmpty) {
        // For message channel, use image1
        // For visit channel, use image1, image2, image3
        final bool isMessageChannel = data['Channel'] == 'Message';
        final int maxImages = isMessageChannel ? 1 : 3;

        for (int i = 0; i < images.length && i < maxImages; i++) {
          final image = images[i];
          final imageField = 'image${i + 1}';

          request.files.add(
            await http.MultipartFile.fromPath(
              imageField,
              image.path,
              filename:
                  'image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
          print(
              '📎 Added $imageField for ${data['Channel']} channel: ${image.path}');
        }
      }

      print('🚀 Sending multipart request...');
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse the response to check for success status
        try {
          final List<dynamic> responseList = jsonDecode(response.body);
          if (responseList.isNotEmpty) {
            final responseData = responseList[0];
            if (responseData['data'] != null &&
                responseData['data'].isNotEmpty) {
              final dataItem = responseData['data'][0];
              final status = dataItem['status']?.toString().toLowerCase();
              if (status == 'success') {
                print('✅ Contactability with images submitted successfully');
                return true;
              } else {
                print('❌ Contactability submission failed - status: $status');
                return false;
              }
            }
          }
          print('❌ Invalid response format from Skorcard API');
          return false;
        } catch (e) {
          print('❌ Error parsing response: $e');
          // If parsing fails but HTTP status is success, still return true
          print(
              '✅ Contactability with images submitted successfully (fallback)');
          return true;
        }
      } else {
        print(
            '❌ Failed to submit contactability with images: ${response.statusCode}');
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

  /// Get agent contactability history from Skorcard API
  Future<Map<String, dynamic>> getAgentContactabilityHistory({
    required String fiOwnerEmail,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      const String baseUrl =
          'https://n8n-sit.skorcard.app/webhook/d540950f-85d2-4e2b-a054-7e5dfcef0379';

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'fi_owner': fiOwnerEmail,
      };

      print('🔄 Fetching agent contactability history');
      print('🔗 URL: $baseUrl');
      print('📄 Request Body: $requestBody');

      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Check if response body is empty or null
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          print('⚠️ Empty response body from API - no history available');
          return {
            'data': [],
            'info': {'count': 0, 'more_records': false}
          };
        }

        // Check if response is valid JSON
        try {
          final List<dynamic> responseList = jsonDecode(response.body);
          if (responseList.isNotEmpty) {
            final responseData = responseList[0];
            print('✅ Agent history fetched successfully');
            return responseData;
          } else {
            print('⚠️ Empty response array from agent history API');
            return {
              'data': [],
              'info': {'count': 0, 'more_records': false}
            };
          }
        } catch (jsonError) {
          print('❌ JSON Parse Error: $jsonError');
          print('📄 Raw response: ${response.body}');

          // Return empty data instead of throwing error for bad JSON
          print('⚠️ Invalid JSON response - treating as no history available');
          return {
            'data': [],
            'info': {'count': 0, 'more_records': false}
          };
        }
      } else {
        print('❌ Failed to fetch agent history: ${response.statusCode}');
        throw NetworkException(
          message: 'Failed to fetch agent history: ${response.statusCode}',
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

  /// Get dashboard performance data from Skorcard API
  Future<Map<String, dynamic>> getDashboardPerformance({
    required String fiOwnerEmail,
    bool forceRefresh = false,
  }) async {
    // Check cache first (unless forced refresh)
    final cacheKey =
        CacheService.generateUserKey(fiOwnerEmail, 'dashboard_performance');

    if (!forceRefresh) {
      final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        print('✅ Using cached dashboard performance data');
        return cachedData;
      }
    }

    try {
      const String baseUrl =
          'https://n8n-sit.skorcard.app/webhook/e3f3398d-ff5a-4ce6-9cee-73ab201119fb';

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'fi_owner': fiOwnerEmail,
      };

      print('🔄 Fetching dashboard performance data');
      print('🔗 URL: $baseUrl');
      print('📄 Request Body: $requestBody');

      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Check if response body is empty or null
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          print(
              '⚠️ Empty response body from dashboard API - no data available');
          final defaultData = {
            'visit': 0,
            'call': 0,
            'message': 0,
            'rpc': 0,
            'tpc': 0,
            'opc': 0,
            'ptp_all_time': 0,
            'ptp_this_month': 0,
          };
          // Cache the default data with shorter duration (1 minute)
          _cache.set(cacheKey, defaultData,
              duration: const Duration(minutes: 1));
          return defaultData;
        }

        // Check if response is valid JSON
        try {
          final List<dynamic> responseList = jsonDecode(response.body);
          if (responseList.isNotEmpty) {
            final responseData = responseList[0];
            print('✅ Dashboard performance data fetched successfully');
            print('📊 Response data: $responseData');

            // Extract performance data from direct response format
            // Expected format: [{"Visit_Count": 22, "Call_Count": 2, "Message_Count": 44, "RPC_Count": 6, "TPC_Count": 3, "OPC_Count": 12, "PTP_Count": 3, "PTP_Count_This_Month": 3}]
            Map<String, dynamic> performanceData = {
              'visit': _parseIntValue(responseData['Visit_Count']) ?? 0,
              'call': _parseIntValue(responseData['Call_Count']) ?? 0,
              'message': _parseIntValue(responseData['Message_Count']) ?? 0,
              'rpc': _parseIntValue(responseData['RPC_Count']) ?? 0,
              'tpc': _parseIntValue(responseData['TPC_Count']) ?? 0,
              'opc': _parseIntValue(responseData['OPC_Count']) ?? 0,
              'ptp_all_time': _parseIntValue(responseData['PTP_Count']) ?? 0,
              'ptp_this_month':
                  _parseIntValue(responseData['PTP_Count_This_Month']) ?? 0,
            };

            print('📈 Parsed performance data: $performanceData');

            // Cache the successful response (3 minutes for fresh data)
            _cache.set(cacheKey, performanceData,
                duration: const Duration(minutes: 3));

            return performanceData;
          } else {
            print('⚠️ Empty response array from dashboard API');
            final defaultData = {
              'visit': 0,
              'call': 0,
              'message': 0,
              'rpc': 0,
              'tpc': 0,
              'opc': 0,
              'ptp_all_time': 0,
              'ptp_this_month': 0,
            };
            // Cache empty response with shorter duration
            _cache.set(cacheKey, defaultData,
                duration: const Duration(minutes: 1));
            return defaultData;
          }
        } catch (jsonError) {
          print('❌ JSON Parse Error: $jsonError');
          print('📄 Raw response: ${response.body}');

          // Return default values instead of throwing error for bad JSON
          print('⚠️ Invalid JSON response - using default values');
          final defaultData = {
            'visit': 0,
            'call': 0,
            'message': 0,
            'rpc': 0,
            'tpc': 0,
            'opc': 0,
            'ptp_all_time': 0,
            'ptp_this_month': 0,
          };
          // Cache error response with very short duration (30 seconds)
          _cache.set(cacheKey, defaultData,
              duration: const Duration(seconds: 30));
          return defaultData;
        }
      } else {
        print('❌ Failed to fetch dashboard data: ${response.statusCode}');
        throw NetworkException(
          message: 'Failed to fetch dashboard data: ${response.statusCode}',
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

  /// Helper method to parse integer values safely
  int? _parseIntValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('Failed to parse int value: $value');
        return null;
      }
    }
    return null;
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
    print('🗑️ All API cache cleared');
  }

  /// Clear cache for specific user
  void clearUserCache(String userEmail) {
    final keysToRemove = <String>[];
    // Since we can't iterate over cache keys directly, we'll use known patterns
    final patterns = [
      'dashboard_performance',
      'attendance_history',
      'contactability_history'
    ];

    for (final pattern in patterns) {
      final key = CacheService.generateUserKey(userEmail, pattern);
      if (_cache.has(key)) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    print('🗑️ Cache cleared for user: $userEmail');
  }

  /// Force refresh dashboard data
  Future<Map<String, dynamic>> refreshDashboardPerformance({
    required String fiOwnerEmail,
  }) async {
    return getDashboardPerformance(
      fiOwnerEmail: fiOwnerEmail,
      forceRefresh: true,
    );
  }

  /// Get attendance history with caching
  Future<List<dynamic>> getAttendanceHistory({
    required String userId,
    bool forceRefresh = false,
  }) async {
    // Check cache first (unless forced refresh)
    final cacheKey = CacheService.generateUserKey(userId, 'attendance_history');

    if (!forceRefresh) {
      final cachedData = _cache.get<List<dynamic>>(cacheKey);
      if (cachedData != null) {
        print('✅ Using cached attendance history data');
        return cachedData;
      }
    }

    try {
      const String baseUrl =
          'https://n8n.skorcard.app/webhook/ba90b87e-b65f-4574-bcf0-223d54b022cf';

      final Map<String, dynamic> requestBody = {
        'user_id': userId,
      };

      print('🔄 Fetching attendance history data');
      print('🔗 URL: $baseUrl');
      print('📄 Request Body: $requestBody');

      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Check if response body is empty or null
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          print(
              '⚠️ Empty response body from attendance API - no data available');
          final emptyData = <dynamic>[];
          // Cache empty response with shorter duration (1 minute)
          _cache.set(cacheKey, emptyData, duration: const Duration(minutes: 1));
          return emptyData;
        }

        // Parse JSON response
        try {
          final List<dynamic> responseList = jsonDecode(response.body);
          print('✅ Attendance history data fetched successfully');
          print('📊 Response data: $responseList');

          // Cache the successful response (5 minutes)
          _cache.set(cacheKey, responseList,
              duration: const Duration(minutes: 5));

          return responseList;
        } catch (jsonError) {
          print('❌ JSON Parse Error: $jsonError');
          print('📄 Raw response: ${response.body}');

          // Return empty list for bad JSON
          print('⚠️ Invalid JSON response - using empty list');
          final emptyData = <dynamic>[];
          // Cache error response with very short duration (30 seconds)
          _cache.set(cacheKey, emptyData,
              duration: const Duration(seconds: 30));
          return emptyData;
        }
      } else {
        print('❌ HTTP Error ${response.statusCode}: ${response.body}');
        throw ServerException(
          message: 'Attendance API returned error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      print('❌ Network Error: No internet connection');
      throw const NetworkException(
        message: 'No internet connection',
        statusCode: 0,
      );
    } on TimeoutException {
      print('❌ Timeout Error: Request timed out');
      throw const NetworkException(
        message: 'Request timeout',
        statusCode: 408,
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

  /// Fetch skip tracing data for a client
  Future<List<Map<String, dynamic>>> fetchSkipTracingData(
      String clientId) async {
    try {
      // Validate input
      if (clientId.isEmpty || clientId.toLowerCase() == 'null') {
        print('⚠️ Invalid clientId provided: $clientId');
        return [];
      }

      print('🔄 Fetching skip tracing data for client: $clientId');

      const String baseUrl =
          'https://n8n.skorcard.app/webhook/fb6e465f-0e75-4b8c-8c51-f0831c4041f7';

      // Prepare request body with client ID
      final Map<String, dynamic> requestBody = {
        'id': clientId,
      };

      print('🌐 Request URL: $baseUrl');
      print('🔑 Client ID: $clientId');
      print('📄 Request Body: $requestBody');

      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Body Length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          // Check if response body is empty or null
          if (response.body.isEmpty || response.body.trim().isEmpty) {
            print('⚠️ Empty response body from API');
            return [];
          }

          final List<dynamic> responseList = json.decode(response.body);
          print('✅ Successfully parsed JSON: ${responseList.runtimeType}');

          // Extract skip tracing data from complex response structure
          final List<Map<String, dynamic>> skipTracingList = [];

          for (final item in responseList) {
            if (item is Map<String, dynamic> && item['data'] != null) {
              final List<dynamic> dataList = item['data'];
              for (final skipTracingData in dataList) {
                if (skipTracingData is Map<String, dynamic>) {
                  skipTracingList.add(skipTracingData);
                }
              }
            }
          }

          print('✅ Found ${skipTracingList.length} skip tracing records');
          return skipTracingList;
        } catch (jsonError) {
          print('❌ JSON Parse Error: $jsonError');
          print('📄 Raw response body: ${response.body}');
          return [];
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('📄 Error Body: ${response.body}');
        throw NetworkException(
          message:
              'Failed to fetch skip tracing data from Skorcard API: ${response.statusCode}',
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
