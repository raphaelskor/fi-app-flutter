class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final PaginationMeta? pagination;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.pagination,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'],
      pagination: json['pagination'] != null
          ? PaginationMeta.fromJson(json['pagination'])
          : null,
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginationMeta({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalItems: json['total_items'] ?? 0,
      itemsPerPage: json['items_per_page'] ?? 20,
      hasNextPage: json['has_next_page'] ?? false,
      hasPreviousPage: json['has_previous_page'] ?? false,
    );
  }
}

class CreateContactabilityRequest {
  final String clientId;
  final String userId;
  final String channel;
  final String result;
  final String notes;
  final DateTime contactedAt;
  final double? latitude;
  final double? longitude;

  CreateContactabilityRequest({
    required this.clientId,
    required this.userId,
    required this.channel,
    required this.result,
    required this.notes,
    required this.contactedAt,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'user_id': userId,
      'channel': channel,
      'result': result,
      'notes': notes,
      'contacted_at': contactedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class ClientListRequest {
  final int page;
  final int limit;
  final String? search;
  final String? status;
  final double? userLatitude;
  final double? userLongitude;
  final double? maxDistance;

  ClientListRequest({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.status,
    this.userLatitude,
    this.userLongitude,
    this.maxDistance,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status;
    }
    if (userLatitude != null) {
      params['user_latitude'] = userLatitude;
    }
    if (userLongitude != null) {
      params['user_longitude'] = userLongitude;
    }
    if (maxDistance != null) {
      params['max_distance'] = maxDistance;
    }

    return params;
  }
}
