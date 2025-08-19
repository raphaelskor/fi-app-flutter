class Client {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String? email;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final double? distance; // Calculated distance from user location
  final Map<String, dynamic>?
      rawApiData; // Store original API data for detailed view

  Client({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.email,
    this.latitude,
    this.longitude,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.distance,
    this.rawApiData,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      notes: json['notes']?.toString(),
      distance: json['distance']?.toDouble(),
      rawApiData: null,
    );
  }

  // Factory method untuk Skorcard API response
  factory Client.fromSkorcardApi(Map<String, dynamic> json) {
    // Extract address from CA_Line_1 and CA_Line_2
    String address = '';
    if (json['CA_Line_1'] != null) {
      address = json['CA_Line_1'].toString();
      if (json['CA_Line_2'] != null) {
        address += ', ' + json['CA_Line_2'].toString();
      }
    }

    // Extract created/modified time
    DateTime createdAt = DateTime.now();
    DateTime updatedAt = DateTime.now();

    try {
      if (json['Created_Time'] != null) {
        createdAt = DateTime.parse(json['Created_Time']);
      }
      if (json['Modified_Time'] != null) {
        updatedAt = DateTime.parse(json['Modified_Time']);
      }
    } catch (e) {
      // Use current time if parsing fails
    }

    return Client(
      id: json['id']?.toString() ?? '',
      name: json['Name1']?.toString() ?? '',
      address: address,
      phone: json['Mobile']?.toString() ?? '',
      email: json['Email']?.toString(),
      latitude: null, // API doesn't provide lat/lng
      longitude: null,
      status: json['Current_Status']?.toString() ?? 'pending',
      createdAt: createdAt,
      updatedAt: updatedAt,
      notes: json['Call_Notes']?.toString(),
      distance: null,
      rawApiData: json, // Store the complete API response
    );
  }

  // Helper method to get Skor User ID from raw API data
  String? get skorUserId {
    try {
      // First check for user_ID (the one we need for skor_user_id parameter)
      final dynamic userIdField = rawApiData?['user_ID'];
      final String? userIdString;

      if (userIdField is String) {
        userIdString = userIdField;
      } else if (userIdField != null) {
        userIdString = userIdField.toString();
      } else {
        userIdString = null;
      }

      // Also check other possible fields as fallback
      final String? skorUserIdField = rawApiData?['Skor_User_ID']?.toString();
      final String? UserIDField = rawApiData?['User_ID']?.toString();

      // Return the first valid non-empty, non-null value
      if (userIdString != null &&
          userIdString.isNotEmpty &&
          userIdString.toLowerCase() != 'null') {
        return userIdString;
      }
      if (UserIDField != null &&
          UserIDField.isNotEmpty &&
          UserIDField.toLowerCase() != 'null') {
        return UserIDField;
      }
      if (skorUserIdField != null &&
          skorUserIdField.isNotEmpty &&
          skorUserIdField.toLowerCase() != 'null') {
        return skorUserIdField;
      }

      return null;
    } catch (e) {
      print('Error getting skorUserId: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notes': notes,
      'distance': distance,
      'raw_api_data': rawApiData,
    };
  }

  Client copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    double? distance,
    Map<String, dynamic>? rawApiData,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      distance: distance ?? this.distance,
      rawApiData: rawApiData ?? this.rawApiData,
    );
  }

  @override
  String toString() {
    return 'Client(id: $id, name: $name, phone: $phone, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Client && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
