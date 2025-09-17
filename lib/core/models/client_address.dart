class ClientAddress {
  final String id;
  final DateTime timestamp;
  final String skorUserId;
  final double latitude;
  final double longitude;
  final String city;
  final String district;
  final String province;
  final String addressLine1;
  final String addressLine2;
  final String addressLine3;
  final String postalCode;
  final bool isDeliveryAddress;
  final int addressType; // 158 = home, 157 = office
  final String addressName;

  ClientAddress({
    required this.id,
    required this.timestamp,
    required this.skorUserId,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.district,
    required this.province,
    required this.addressLine1,
    required this.addressLine2,
    required this.addressLine3,
    required this.postalCode,
    required this.isDeliveryAddress,
    required this.addressType,
    required this.addressName,
  });

  factory ClientAddress.fromApiResponse(List<dynamic> row) {
    return ClientAddress(
      id: row[0]?.toString() ?? '',
      timestamp: DateTime.tryParse(row[1]?.toString() ?? '') ?? DateTime.now(),
      skorUserId: row[11]?.toString() ?? '',
      latitude: double.tryParse(row[15]?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(row[21]?.toString() ?? '') ?? 0.0,
      city: row[7]?.toString() ?? '',
      district: row[14]?.toString() ?? '',
      province: row[16]?.toString() ?? '',
      addressLine1: row[17]?.toString() ?? '',
      addressLine2: row[18]?.toString() ?? '',
      addressLine3: row[19]?.toString() ?? '',
      postalCode: row[12]?.toString() ?? '',
      isDeliveryAddress: row[13] == true,
      addressType: int.tryParse(row[36]?.toString() ?? '') ?? 0,
      addressName: row[39]?.toString() ?? '',
    );
  }

  factory ClientAddress.fromJson(Map<String, dynamic> json) {
    return ClientAddress(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      skorUserId: json['skorUserId'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      province: json['province'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'] ?? '',
      addressLine3: json['addressLine3'] ?? '',
      postalCode: json['postalCode'] ?? '',
      isDeliveryAddress: json['isDeliveryAddress'] ?? false,
      addressType: json['addressType'] ?? 0,
      addressName: json['addressName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'skorUserId': skorUserId,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'district': district,
      'province': province,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'addressLine3': addressLine3,
      'postalCode': postalCode,
      'isDeliveryAddress': isDeliveryAddress,
      'addressType': addressType,
      'addressName': addressName,
    };
  }

  String get addressTypeLabel {
    switch (addressType) {
      case 158:
        return 'Home Address';
      case 157:
        return 'Office Address';
      default:
        return 'Other Address';
    }
  }

  String get fullAddress {
    List<String> addressParts = [];

    if (addressLine1.isNotEmpty) addressParts.add(addressLine1);
    if (addressLine2.isNotEmpty) addressParts.add(addressLine2);
    if (addressLine3.isNotEmpty) addressParts.add(addressLine3);
    if (district.isNotEmpty) addressParts.add(district);
    if (city.isNotEmpty) addressParts.add(city);
    if (province.isNotEmpty) addressParts.add(province);
    if (postalCode.isNotEmpty) addressParts.add(postalCode);

    return addressParts.join(', ');
  }

  bool get isHomeAddress => addressType == 158;
  bool get isOfficeAddress => addressType == 157;

  @override
  String toString() {
    return 'ClientAddress(id: $id, type: $addressTypeLabel, city: $city, isDelivery: $isDeliveryAddress)';
  }
}

class ClientAddressResponse {
  final List<ClientAddress> addresses;

  ClientAddressResponse({required this.addresses});

  factory ClientAddressResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rows = data['rows'] as List<dynamic>? ?? [];

    final addresses = rows
        .map((row) => ClientAddress.fromApiResponse(row as List<dynamic>))
        .where((address) => address.latitude != 0.0 && address.longitude != 0.0)
        .toList();

    return ClientAddressResponse(addresses: addresses);
  }

  List<ClientAddress> get homeAddresses =>
      addresses.where((addr) => addr.isHomeAddress).toList();

  List<ClientAddress> get officeAddresses =>
      addresses.where((addr) => addr.isOfficeAddress).toList();

  ClientAddress? get deliveryAddress =>
      addresses.where((addr) => addr.isDeliveryAddress).isNotEmpty
          ? addresses.firstWhere((addr) => addr.isDeliveryAddress)
          : null;
}
