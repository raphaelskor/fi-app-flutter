# Photo Display Feature

## Overview

This feature adds the ability to display KTP and Selfie photos for clients in the Client Details screen. The photos are fetched from the Skorcard API and displayed in the client information section.

## Technical Implementation

### API Endpoint
- **URL**: `https://n8n.skorcard.app/webhook/c8e14ad2-d9fa-4a0d-be07-3787ff81a463`
- **Method**: POST
- **Request Body**:
  ```json
  {
    "user_id": "SC012025005827"
  }
  ```
- **Response**: Binary ZIP file containing KTP and Selfie images

### Files Added/Modified

1. **PhotoService** (`lib/core/services/photo_service.dart`)
   - Handles API communication with the photo endpoint
   - Downloads and extracts ZIP files containing photos
   - Manages local caching of photos
   - Provides methods to check photo availability and clear cache

2. **Client Details Screen** (`lib/screens/clients/client_details_screen.dart`)
   - Updated to display KTP and Selfie photos
   - Added photo section with loading states and error handling
   - Photos are displayed as thumbnails that can be tapped for full-screen view

3. **Dependencies** (`pubspec.yaml`)
   - Added `archive: ^3.4.10` for ZIP file extraction
   - Added `path_provider: ^2.1.2` for file system access
   - Added `path: ^1.8.3` for path utilities

## Features

### Photo Display
- KTP and Selfie photos are shown in a dedicated "Photos" section
- Thumbnails can be tapped to view full-screen versions
- InteractiveViewer allows zooming and panning in full-screen mode
- Error handling for missing or corrupted images

### Local Caching
- Photos are cached locally to improve performance
- Cache is organized by user ID
- Supports multiple file formats (JPG, PNG)
- Automatic cache management

### Loading States
- Loading indicator while fetching photos from API
- Retry button available if photo loading fails
- Graceful handling of API errors

### Error Handling
- Network connectivity issues
- Invalid ZIP file format
- Missing photos in response
- File system access errors

## Usage

The photo functionality is automatically triggered when:
1. A client details screen is opened
2. The client has a valid `skorUserId`
3. Photos haven't been cached locally yet

### Code Example

```dart
// PhotoService usage
final photoService = PhotoService();

// Fetch photos for a user
final photos = await photoService.fetchUserPhotos('SC012025005827');
// Returns: {'ktp': '/path/to/ktp.jpg', 'selfie': '/path/to/selfie.jpg'}

// Check if photos exist locally
final exists = await photoService.checkPhotosExist('SC012025005827');
// Returns: {'ktp': true, 'selfie': false}

// Clear cached photos
await photoService.clearUserPhotos('SC012025005827');
```

## File Structure

```
photos/
├── [userId]/
    ├── ktp.jpg
    ├── selfie.jpg
    └── ...
```

Photos are stored in the application documents directory under a `photos` folder, organized by user ID.

## Error Handling

The system handles various error scenarios:

1. **Network Errors**: Timeout, no connection, server errors
2. **API Errors**: Invalid response, empty response, HTTP errors
3. **File Errors**: Corrupted ZIP, invalid file format, disk space issues
4. **Parsing Errors**: Invalid ZIP structure, missing files

## Security Considerations

- Photos are stored locally on the device
- No sensitive data is transmitted beyond the user ID
- Local photos are isolated per user
- Error messages don't expose sensitive information

## Future Enhancements

Potential improvements:
- Photo compression to reduce storage space
- Automatic cache cleanup based on age
- Progress indicators for large downloads
- Support for additional photo types
- Batch photo downloads for multiple users