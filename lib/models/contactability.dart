enum ContactabilityType { visit, call, message }
enum ContactabilityStatus { pending, completed, failed, noAnswer }

class Contactability {
  final int id;
  final int contactId;
  final ContactabilityType type;
  final ContactabilityStatus status;
  final String notes;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  Contactability({
    required this.id,
    required this.contactId,
    required this.type,
    required this.status,
    required this.notes,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  factory Contactability.fromJson(Map<String, dynamic> json) {
    return Contactability(
      id: json['id'],
      contactId: json['contact_id'],
      type: ContactabilityType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type']
      ),
      status: ContactabilityStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status']
      ),
      notes: json['notes'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}