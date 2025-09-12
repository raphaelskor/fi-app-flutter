class ClientLocation {
  final String id;
  final DateTime timestamp;
  final String skorUserId;
  final double latitude;
  final double longitude;
  final String eventType;
  final String ipAddress;
  final String deviceId;

  ClientLocation({
    required this.id,
    required this.timestamp,
    required this.skorUserId,
    required this.latitude,
    required this.longitude,
    required this.eventType,
    required this.ipAddress,
    required this.deviceId,
  });

  factory ClientLocation.fromApiResponse(List<dynamic> row) {
    return ClientLocation(
      id: row[0]?.toString() ?? '',
      timestamp: DateTime.tryParse(row[1]?.toString() ?? '') ?? DateTime.now(),
      skorUserId: row[9]?.toString() ?? '',
      latitude: double.tryParse(row[10]?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(row[12]?.toString() ?? '') ?? 0.0,
      eventType: row[7]?.toString() ?? '',
      ipAddress: row[5]?.toString() ?? '',
      deviceId: row[14]?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'ClientLocation(id: $id, timestamp: $timestamp, lat: $latitude, lng: $longitude, eventType: $eventType)';
  }
}

class ClientLocationResponse {
  final List<ClientLocation> locations;

  ClientLocationResponse({required this.locations});

  factory ClientLocationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rows = data['rows'] as List<dynamic>? ?? [];

    final locations = rows
        .map((row) => ClientLocation.fromApiResponse(row as List<dynamic>))
        .where(
            (location) => location.latitude != 0.0 && location.longitude != 0.0)
        .toList();

    return ClientLocationResponse(locations: locations);
  }
}
