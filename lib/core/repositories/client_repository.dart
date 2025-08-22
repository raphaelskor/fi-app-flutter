import '../models/client.dart';
import '../models/contactability.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../exceptions/app_exception.dart';

class ClientRepository {
  final ApiService _apiService = ApiService();

  // Fetch clients from Skorcard API
  Future<ApiResponse<List<Client>>> getSkorcardClients({
    String? fiOwnerEmail,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      if (fiOwnerEmail == null || fiOwnerEmail.isEmpty) {
        throw ValidationException(
          message: 'fi_owner email is required to fetch clients',
          statusCode: 400,
        );
      }

      final clientsData = await _apiService.fetchSkorcardClients(fiOwnerEmail);

      final List<Client> clients = clientsData
          .map((clientData) => Client.fromSkorcardApi(clientData))
          .toList();

      // Calculate distance if user location is provided
      if (userLatitude != null && userLongitude != null) {
        for (int i = 0; i < clients.length; i++) {
          // For now, set distance to null since API doesn't provide lat/lng
          // In the future, we could geocode the address to get coordinates
        }
      }

      return ApiResponse<List<Client>>(
        success: true,
        data: clients,
        message: 'Clients fetched successfully',
        pagination: PaginationMeta(
          currentPage: 1,
          totalPages: 1,
          totalItems: clients.length,
          itemsPerPage: clients.length,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
          message: 'Failed to fetch clients from Skorcard: ${e.toString()}');
    }
  }

  // Original method for fallback (if needed)
  Future<ApiResponse<List<Client>>> getClients({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    double? userLatitude,
    double? userLongitude,
    double? maxDistance,
  }) async {
    try {
      final request = ClientListRequest(
        page: page,
        limit: limit,
        search: search,
        status: status,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        maxDistance: maxDistance,
      );

      final response = await _apiService.get(
        '/api/clients',
        queryParams: request.toQueryParams(),
      );

      return ApiResponse.fromJson(
        response,
        (data) => (data as List)
            .map((json) => Client.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
          message: 'Failed to fetch clients: ${e.toString()}');
    }
  }

  Future<ApiResponse<Client>> getClientById(String clientId) async {
    try {
      final response = await _apiService.get('/api/clients/$clientId');

      return ApiResponse.fromJson(
        response,
        (data) => Client.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
          message: 'Failed to fetch client: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<Client>>> getTodaysClients({
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'today': true,
        'sort_by': 'distance',
      };

      if (userLatitude != null) {
        queryParams['user_latitude'] = userLatitude;
      }
      if (userLongitude != null) {
        queryParams['user_longitude'] = userLongitude;
      }

      final response = await _apiService.get(
        '/api/clients',
        queryParams: queryParams,
      );

      return ApiResponse.fromJson(
        response,
        (data) => (data as List)
            .map((json) => Client.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
          message: 'Failed to fetch today\'s clients: ${e.toString()}');
    }
  }

  Future<ApiResponse<Client>> updateClientStatus(
      String clientId, String status) async {
    try {
      final response = await _apiService.put(
        '/api/clients/$clientId/status',
        {'status': status},
      );

      return ApiResponse.fromJson(
        response,
        (data) => Client.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
          message: 'Failed to update client status: ${e.toString()}');
    }
  }
}

class ContactabilityRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<Contactability>> createContactability(
    CreateContactabilityRequest request,
  ) async {
    try {
      final response = await _apiService.post(
        '/api/contactability',
        request.toJson(),
      );

      return ApiResponse.fromJson(
        response,
        (data) => Contactability.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
          message: 'Failed to create contactability: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<Contactability>>> getContactabilityByClient(
    String clientId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/clients/$clientId/contactability',
        queryParams: {
          'page': page,
          'limit': limit,
        },
      );

      return ApiResponse.fromJson(
        response,
        (data) => (data as List)
            .map(
                (json) => Contactability.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
          message: 'Failed to fetch contactability history: ${e.toString()}');
    }
  }

  Future<ApiResponse<Contactability>> getContactabilityById(String id) async {
    try {
      final response = await _apiService.get('/api/contactability/$id');

      return ApiResponse.fromJson(
        response,
        (data) => Contactability.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
          message: 'Failed to fetch contactability: ${e.toString()}');
    }
  }

  Future<ApiResponse<Contactability>> updateContactability(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiService.put(
        '/api/contactability/$id',
        updates,
      );

      return ApiResponse.fromJson(
        response,
        (data) => Contactability.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
          message: 'Failed to update contactability: ${e.toString()}');
    }
  }

  Future<ApiResponse<void>> deleteContactability(String id) async {
    try {
      await _apiService.delete('/api/contactability/$id');
      return ApiResponse<void>(
          success: true, message: 'Contactability deleted successfully');
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
          message: 'Failed to delete contactability: ${e.toString()}');
    }
  }
}
