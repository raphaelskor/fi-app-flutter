import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/operational_area.dart';

class OperationalAreaService {
  // List of operational areas with their corresponding file names
  static const List<Map<String, String>> _operationalAreas = [
    {
      'name': 'JAKARTA PUSAT',
      'province': 'DKI JAKARTA',
      'file': 'jakarta pusat.json'
    },
    {
      'name': 'JAKARTA BARAT',
      'province': 'DKI JAKARTA',
      'file': 'jakarta barat.json'
    },
    {
      'name': 'JAKARTA SELATAN',
      'province': 'DKI JAKARTA',
      'file': 'jakarta selatan.json'
    },
    {
      'name': 'JAKARTA TIMUR',
      'province': 'DKI JAKARTA',
      'file': 'jakarta timur.json'
    },
    {
      'name': 'JAKARTA UTARA',
      'province': 'DKI JAKARTA',
      'file': 'jakarta utara.json'
    },
    {'name': 'TANGERANG', 'province': 'BANTEN', 'file': 'tangerang.json'},
    {
      'name': 'TANGERANG SELATAN',
      'province': 'BANTEN',
      'file': 'tangerang selatan.json'
    },
    {'name': 'BOGOR', 'province': 'JAWA BARAT', 'file': 'bogor.json'},
    {'name': 'DEPOK', 'province': 'JAWA BARAT', 'file': 'depok.json'},
    {'name': 'BEKASI', 'province': 'JAWA BARAT', 'file': 'bekasi.json'},
    {
      'name': 'KABUPATEN BEKASI',
      'province': 'JAWA BARAT',
      'file': 'kab-bekasi.json'
    },
    {
      'name': 'KABUPATEN BOGOR',
      'province': 'JAWA BARAT',
      'file': 'kab-bogor.json'
    },
    {'name': 'KARAWANG', 'province': 'JAWA BARAT', 'file': 'karawang.json'},
    {'name': 'SURABAYA', 'province': 'JAWA TIMUR', 'file': 'surabaya.json'},
    {'name': 'GRESIK', 'province': 'JAWA TIMUR', 'file': 'gresik.json'},
    {'name': 'SIDOARJO', 'province': 'JAWA TIMUR', 'file': 'sidoarjo.json'},
    {'name': 'BANDUNG', 'province': 'JAWA BARAT', 'file': 'bandung.json'},
    {'name': 'CIMAHI', 'province': 'JAWA BARAT', 'file': 'cimahi.json'},
    {'name': 'MALANG', 'province': 'JAWA TIMUR', 'file': 'malang.json'},
    {'name': 'BATU', 'province': 'JAWA TIMUR', 'file': 'batu.json'},
    {'name': 'DENPASAR', 'province': 'BALI', 'file': 'denpasar.json'},
    {
      'name': 'MAKASSAR',
      'province': 'SULAWESI SELATAN',
      'file': 'makassar.json'
    },
  ];

  static Future<List<OperationalArea>> fetchOperationalAreas() async {
    List<OperationalArea> areas = [];

    for (final areaData in _operationalAreas) {
      try {
        final area = await _loadAreaFromFile(
            areaData['name']!, areaData['province']!, areaData['file']!);
        if (area != null) {
          areas.add(area);
          print('✅ Loaded boundary for ${area.fullName}');
        }
      } catch (e) {
        print('❌ Failed to load boundary for ${areaData['name']}: $e');
      }
    }

    print('📍 Total operational areas loaded: ${areas.length}');
    return areas;
  }

  static Future<OperationalArea?> _loadAreaFromFile(
      String name, String province, String fileName) async {
    try {
      // Load JSON file from assets
      final String jsonString =
          await rootBundle.loadString('assets/geo/$fileName');
      final List<dynamic> data = json.decode(jsonString);

      if (data.isNotEmpty) {
        // Use the first (and usually only) item from the JSON file
        final Map<String, dynamic> geoData = data[0];
        return OperationalArea.fromNominatimResponse(geoData);
      }
    } catch (e) {
      print('Error loading boundary from file $fileName: $e');
    }

    return null;
  }

  // Get areas by province for grouping
  static Map<String, List<OperationalArea>> groupAreasByProvince(
      List<OperationalArea> areas) {
    Map<String, List<OperationalArea>> grouped = {};

    for (final area in areas) {
      grouped.putIfAbsent(area.province, () => []).add(area);
    }

    return grouped;
  }

  // Check if a coordinate is within any operational area
  static bool isWithinOperationalArea(
      double lat, double lng, List<OperationalArea> areas) {
    for (final area in areas) {
      if (lat >= area.south &&
          lat <= area.north &&
          lng >= area.west &&
          lng <= area.east) {
        return true;
      }
    }
    return false;
  }
}
