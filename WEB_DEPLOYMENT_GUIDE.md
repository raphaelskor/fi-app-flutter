# Flutter Web Deployment - Refactoring Guide

## Status
❌ **Aplikasi belum bisa di-deploy ke web** karena menggunakan fitur-fitur yang hanya tersedia di platform mobile.

## Masalah Utama

### 1. Penggunaan `dart:io`
Banyak file menggunakan `dart:io` yang tidak tersedia di web platform:
- `lib/main.dart` - ✅ Sudah diperbaiki dengan `kIsWeb` check
- `lib/core/services/api_service.dart` - ⚠️ Menggunakan `SocketException`, `HttpException`
- `lib/core/services/photo_service.dart` - ❌ Menggunakan `File`, `Directory`
- `lib/core/controllers/contactability_controller.dart` - ❌ Menggunakan `File`
- `lib/screens/clients/client_details_screen.dart` - ❌ Menggunakan `Image.file()`, `File()`
- `lib/screens/contactability_form_screen.dart` - ❌ Menggunakan `File`

### 2. Package Tidak Support Web
- `path_provider` - Digunakan untuk akses file system, tidak tersedia di web
- Perlu diganti dengan:
  - `shared_preferences_web` untuk simple storage
  - `indexed_db` untuk database di browser
  - API untuk storage file

### 3. File I/O Operations
Aplikasi ini extensively menggunakan:
- `File()` untuk membaca/menulis file lokal
- `Directory()` untuk navigasi folder
- `Image.file()` untuk display gambar dari file system

Di web, harus menggunakan:
- `Uint8List` / `Blob` untuk handle binary data
- `Image.memory()` untuk display dari memory
- `Image.network()` untuk display dari URL
- Browser storage APIs (localStorage, IndexedDB, atau backend API)

## Rekomendasi

### Opsi 1: Conditional Features (Recommended untuk hybrid app)
```dart
import 'package:flutter/foundation.dart' show kIsWeb;

Widget buildImage(String? path) {
  if (kIsWeb) {
    // Web: Load from network or show placeholder
    return Image.network(path ?? 'placeholder.png');
  } else {
    // Mobile: Load from file
    return Image.file(File(path!));
  }
}
```

### Opsi 2: Platform-Specific Implementation
Buat abstraction layer dengan implementation berbeda untuk mobile dan web:

```
lib/
  core/
    platform/
      file_handler.dart          # Abstract interface
      file_handler_mobile.dart   # Mobile implementation (dart:io)
      file_handler_web.dart      # Web implementation (HTML5 APIs)
```

### Opsi 3: Web-Only Version (Fastest)
Buat simplified version khusus web yang:
- Tidak support photo upload/display dari local files
- Gunakan API untuk semua data (tidak ada local caching dengan files)
- Simplified UI tanpa fitur yang membutuhkan file I/O

## Langkah Refactoring

### 1. Photo Service
```dart
// Before (mobile-only)
Future<String> savePhoto(Uint8List bytes) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/photo.jpg');
  await file.writeAsBytes(bytes);
  return file.path;
}

// After (cross-platform)
Future<String> savePhoto(Uint8List bytes) async {
  if (kIsWeb) {
    // Upload to server, return URL
    return await uploadPhotoToServer(bytes);
  } else {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/photo.jpg');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
```

### 2. Image Display
```dart
// Before
Image.file(File(photoPath))

// After
kIsWeb
  ? Image.network(photoPath)  // photoPath is URL on web
  : Image.file(File(photoPath))  // photoPath is local path on mobile
```

### 3. API Service
Exception handling sudah ada stub di `lib/core/utils/io_stub.dart`, tapi perlu ensure semua file yang menggunakan `File` juga handle web case.

## Next Steps

1. **Audit semua penggunaan File/Directory:**
   ```bash
   grep -r "File(" lib/
   grep -r "Directory(" lib/
   grep -r "Image.file" lib/
   ```

2. **Buat abstraction layer untuk file operations**

3. **Update photo service untuk support web:**
   - Upload ke server instead of save locally
   - Gunakan blob URLs atau base64 untuk preview

4. **Test incremental:**
   - Build web: `flutter build web`
   - Test locally: `flutter run -d chrome`

5. **Enable CI/CD setelah semua fix:**
   - Uncomment `.github/workflows/firebase-hosting-deploy.yml`
   - Setup `FIREBASE_SERVICE_ACCOUNT` secret di GitHub

## Firebase Hosting Setup (Sudah Selesai)

✅ Firebase project: `skorcard-collection`
✅ Firebase konfigurasi: `.firebaserc`, `firebase.json`
✅ Hosting URL: https://skorcard-collection.web.app
✅ GitHub Actions workflow template: `.github/workflows/firebase-hosting-deploy.yml` (disabled)

## Deployment Manual (Sementara)

Jika ingin deploy versi simplified untuk testing:

```powershell
# 1. Comment out features yang tidak support web
# 2. Build web
flutter build web --release --pwa-strategy=none --base-href /

# 3. Deploy ke Firebase
firebase deploy --only hosting
```

## Resources

- [Flutter Web Support](https://docs.flutter.dev/platform-integration/web)
- [Conditional Imports](https://dart.dev/guides/libraries/create-library-packages#conditionally-importing-and-exporting-library-files)
- [Platform Detection](https://api.flutter.dev/flutter/foundation/kIsWeb-constant.html)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)

---
**Dibuat:** November 4, 2025
**Status:** Perlu refactoring sebelum web deployment bisa berfungsi
