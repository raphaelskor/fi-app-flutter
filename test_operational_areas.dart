import 'dart:convert';
import 'dart:io';
import 'lib/core/models/operational_area.dart';

void main() async {
  // Test parsing of Jakarta Pusat
  try {
    final file = File('assets/geo/jakarta pusat.json');
    final jsonString = await file.readAsString();
    final List<dynamic> data = json.decode(jsonString);

    print('📄 JSON file loaded: ${data.length} items');

    if (data.isNotEmpty) {
      final Map<String, dynamic> geoData = data[0];
      print('🗺️ GeoJSON type: ${geoData['geojson']?['type']}');
      print(
          '📍 Coordinates available: ${geoData['geojson']?['coordinates'] != null}');

      final area = OperationalArea.fromNominatimResponse(geoData);
      print('✅ Area parsed: ${area.name}');
      print('🔢 Polygons: ${area.polygons.length}');

      for (int i = 0; i < area.polygons.length; i++) {
        print('   └─ Polygon $i: ${area.polygons[i].length} points');
        if (area.polygons[i].isNotEmpty) {
          final firstPoint = area.polygons[i].first;
          final lastPoint = area.polygons[i].last;
          print('      First: ${firstPoint.latitude}, ${firstPoint.longitude}');
          print('      Last:  ${lastPoint.latitude}, ${lastPoint.longitude}');
        }
      }
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
