import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../exceptions/app_exception.dart';

class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  static const String _photoApiUrl =
      'https://n8n.skorcard.app/webhook/c8e14ad2-d9fa-4a0d-be07-3787ff81a463';

  /// Fetches user photos (KTP and Selfie) from the API
  /// Returns a map with 'ktp' and 'selfie' file paths or null if not found
  Future<Map<String, String?>> fetchUserPhotos(String userId) async {
    try {
      print('🔍 PhotoService: Fetching photos for userId: $userId');

      // Create request body
      final body = jsonEncode({'user_id': userId});
      print('🔍 PhotoService: Request body: $body');

      // Make API request
      print('🔍 PhotoService: Making API request to: $_photoApiUrl');
      final response = await http.post(
        Uri.parse(_photoApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('🔍 PhotoService: Response status: ${response.statusCode}');
      print('🔍 PhotoService: Response headers: ${response.headers}');
      print(
          '🔍 PhotoService: Response body length: ${response.bodyBytes.length} bytes');

      if (response.statusCode != 200) {
        print(
            '❌ PhotoService: API request failed with status ${response.statusCode}');
        print('❌ PhotoService: Response body: ${response.body}');
        throw NetworkException(
          message: 'Failed to fetch photos: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      // Get response as bytes
      final Uint8List zipBytes = response.bodyBytes;
      print('🔍 PhotoService: Received ${zipBytes.length} bytes from API');

      if (zipBytes.isEmpty) {
        print('❌ PhotoService: Empty response from API');
        throw ServerException(
          message: 'Empty response from photo API',
        );
      }

      // Extract files from ZIP
      print('🔍 PhotoService: Extracting photos from ZIP...');
      final result = await _extractPhotosFromZip(zipBytes, userId);
      print('🔍 PhotoService: Extraction complete. Result: $result');

      return result;
    } catch (e) {
      print('❌ PhotoService: Error in fetchUserPhotos: $e');
      if (e is AppException) {
        rethrow;
      }
      throw ServerException(
        message: 'Error fetching photos: ${e.toString()}',
      );
    }
  }

  /// Extracts KTP and Selfie photos from ZIP archive
  Future<Map<String, String?>> _extractPhotosFromZip(
    Uint8List zipBytes,
    String userId,
  ) async {
    try {
      print('🔍 PhotoService: Starting ZIP extraction for userId: $userId');

      // Decode ZIP archive
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);
      print(
          '🔍 PhotoService: ZIP decoded successfully. Files count: ${archive.length}');

      // List all files in the archive for debugging
      for (final ArchiveFile file in archive) {
        print(
            '🔍 PhotoService: Archive file: ${file.name} (${file.size} bytes)');
      }

      // Get application documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String photosDir = path.join(appDocDir.path, 'photos', userId);
      print('🔍 PhotoService: Photos directory: $photosDir');

      // Create photos directory if it doesn't exist
      final Directory photosDirObj = Directory(photosDir);
      if (!await photosDirObj.exists()) {
        await photosDirObj.create(recursive: true);
        print('🔍 PhotoService: Created photos directory');
      }

      Map<String, String?> results = {'ktp': null, 'selfie': null};

      // Extract files from archive
      for (final ArchiveFile file in archive) {
        if (file.isFile) {
          final String fileName = file.name.toLowerCase();
          final List<int> data = file.content as List<int>;
          print(
              '🔍 PhotoService: Processing file: ${file.name} (lowercase: $fileName)');

          String? photoType;
          String fileExtension = 'jpg'; // Default extension

          // Determine photo type based on filename
          if (fileName.contains('ktp')) {
            photoType = 'ktp';
            print('🔍 PhotoService: Identified as KTP photo');
          } else if (fileName.contains('selfie')) {
            photoType = 'selfie';
            print('🔍 PhotoService: Identified as Selfie photo');
          } else {
            print(
                '🔍 PhotoService: Could not identify photo type for: $fileName');
          }

          // Determine file extension
          if (fileName.contains('.png')) {
            fileExtension = 'png';
          } else if (fileName.contains('.jpeg') || fileName.contains('.jpg')) {
            fileExtension = 'jpg';
          }
          print(
              '🔍 PhotoService: File extension determined as: $fileExtension');

          if (photoType != null) {
            // Create file path
            final String filePath =
                path.join(photosDir, '${photoType}.$fileExtension');
            print('🔍 PhotoService: Saving to: $filePath');

            // Write file to disk
            final File outputFile = File(filePath);
            await outputFile.writeAsBytes(data);
            print('✅ PhotoService: Successfully saved $photoType photo');

            results[photoType] = filePath;
          }
        }
      }

      print('🔍 PhotoService: Final results: $results');
      return results;
    } catch (e) {
      print('❌ PhotoService: Error in _extractPhotosFromZip: $e');
      throw ServerException(
        message: 'Error extracting photos from ZIP: ${e.toString()}',
      );
    }
  }

  /// Clears cached photos for a user
  Future<void> clearUserPhotos(String userId) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String photosDir = path.join(appDocDir.path, 'photos', userId);
      final Directory photosDirObj = Directory(photosDir);

      if (await photosDirObj.exists()) {
        await photosDirObj.delete(recursive: true);
      }
    } catch (e) {
      // Ignore errors when clearing cache
      print('Warning: Could not clear photos for user $userId: $e');
    }
  }

  /// Checks if photos exist locally for a user
  Future<Map<String, bool>> checkPhotosExist(String userId) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String photosDir = path.join(appDocDir.path, 'photos', userId);

      final Map<String, bool> exists = {'ktp': false, 'selfie': false};

      // Check for KTP files
      for (String ext in ['jpg', 'jpeg', 'png']) {
        final File ktpFile = File(path.join(photosDir, 'ktp.$ext'));
        if (await ktpFile.exists()) {
          exists['ktp'] = true;
          break;
        }
      }

      // Check for Selfie files
      for (String ext in ['jpg', 'jpeg', 'png']) {
        final File selfieFile = File(path.join(photosDir, 'selfie.$ext'));
        if (await selfieFile.exists()) {
          exists['selfie'] = true;
          break;
        }
      }

      return exists;
    } catch (e) {
      return {'ktp': false, 'selfie': false};
    }
  }

  /// Gets local file paths for photos if they exist
  Future<Map<String, String?>> getLocalPhotoPaths(String userId) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String photosDir = path.join(appDocDir.path, 'photos', userId);

      final Map<String, String?> paths = {'ktp': null, 'selfie': null};

      // Find KTP file
      for (String ext in ['jpg', 'jpeg', 'png']) {
        final File ktpFile = File(path.join(photosDir, 'ktp.$ext'));
        if (await ktpFile.exists()) {
          paths['ktp'] = ktpFile.path;
          break;
        }
      }

      // Find Selfie file
      for (String ext in ['jpg', 'jpeg', 'png']) {
        final File selfieFile = File(path.join(photosDir, 'selfie.$ext'));
        if (await selfieFile.exists()) {
          paths['selfie'] = selfieFile.path;
          break;
        }
      }

      return paths;
    } catch (e) {
      return {'ktp': null, 'selfie': null};
    }
  }
}
