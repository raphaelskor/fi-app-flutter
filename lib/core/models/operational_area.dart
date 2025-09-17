import 'package:latlong2/latlong.dart';

class OperationalArea {
  final String name;
  final String province;
  final List<List<LatLng>> polygons; // Support multiple polygons
  final LatLng center;
  final double north;
  final double south;
  final double east;
  final double west;

  OperationalArea({
    required this.name,
    required this.province,
    required this.polygons,
    required this.center,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  factory OperationalArea.fromNominatimResponse(Map<String, dynamic> json) {
    final name = json['display_name']?.toString().split(',')[0] ?? '';
    final fullName = json['display_name']?.toString() ?? '';

    // Extract province from display name
    String province = '';
    if (fullName.contains('DKI Jakarta')) {
      province = 'DKI JAKARTA';
    } else if (fullName.contains('Banten')) {
      province = 'BANTEN';
    } else if (fullName.contains('Jawa Barat')) {
      province = 'JAWA BARAT';
    } else if (fullName.contains('Jawa Timur')) {
      province = 'JAWA TIMUR';
    } else if (fullName.contains('Bali')) {
      province = 'BALI';
    } else if (fullName.contains('Sulawesi Selatan')) {
      province = 'SULAWESI SELATAN';
    }

    final boundingBox = json['boundingbox'];
    final north = double.tryParse(boundingBox[1]?.toString() ?? '0') ?? 0.0;
    final south = double.tryParse(boundingBox[0]?.toString() ?? '0') ?? 0.0;
    final west = double.tryParse(boundingBox[2]?.toString() ?? '0') ?? 0.0;
    final east = double.tryParse(boundingBox[3]?.toString() ?? '0') ?? 0.0;

    final center = LatLng(
      double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
    );

    // Parse GeoJSON geometry
    List<List<LatLng>> polygons = [];
    final geojson = json['geojson'];
    if (geojson != null && geojson['coordinates'] != null) {
      polygons = _parseGeoJsonCoordinates(geojson);
    }

    return OperationalArea(
      name: name.toUpperCase(),
      province: province,
      polygons: polygons,
      center: center,
      north: north,
      south: south,
      east: east,
      west: west,
    );
  }

  static List<List<LatLng>> _parseGeoJsonCoordinates(
      Map<String, dynamic> geojson) {
    List<List<LatLng>> polygons = [];

    try {
      final type = geojson['type']?.toString();
      final coordinates = geojson['coordinates'];

      if (coordinates == null) return polygons;

      switch (type) {
        case 'Polygon':
          // Single polygon
          final polygon = _parsePolygonCoordinates(coordinates);
          if (polygon.isNotEmpty) {
            polygons.add(polygon);
          }
          break;

        case 'MultiPolygon':
          // Multiple polygons
          for (final polygonCoords in coordinates) {
            final polygon = _parsePolygonCoordinates(polygonCoords);
            if (polygon.isNotEmpty) {
              polygons.add(polygon);
            }
          }
          break;
      }
    } catch (e) {
      print('Error parsing GeoJSON coordinates: $e');
    }

    return polygons;
  }

  static List<LatLng> _parsePolygonCoordinates(dynamic coordinates) {
    List<LatLng> points = [];

    try {
      // Get the outer ring (first array in polygon coordinates)
      final outerRing = coordinates[0];

      for (final coord in outerRing) {
        if (coord is List && coord.length >= 2) {
          final lng = double.tryParse(coord[0].toString());
          final lat = double.tryParse(coord[1].toString());

          if (lat != null && lng != null) {
            points.add(LatLng(lat, lng));
          }
        }
      }
    } catch (e) {
      print('Error parsing polygon coordinates: $e');
    }

    return points;
  }

  String get fullName => '$name, $province';

  @override
  String toString() {
    return 'OperationalArea(name: $name, province: $province, polygons: ${polygons.length})';
  }
}
