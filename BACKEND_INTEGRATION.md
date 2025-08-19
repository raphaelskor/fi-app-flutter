# Field Investigator App - Backend Integration

Struktur project ini sudah disiapkan untuk integrasi jangka panjang dengan backend dengan arsitektur yang clean dan scalable.

## Struktur Project

### Core Layer (`lib/core/`)

#### Config (`lib/core/config/`)
- `env_config.dart` - Konfigurasi environment dan endpoint API

#### Exceptions (`lib/core/exceptions/`)
- `app_exception.dart` - Custom exception classes untuk error handling

#### Validators (`lib/core/validators/`)
- `app_validators.dart` - Validasi form dan input data

#### Utils (`lib/core/utils/`)
- `app_utils.dart` - Utility functions (DateUtils, StringUtils, DistanceUtils, ColorUtils)

#### Models (`lib/core/models/`)
- `client.dart` - Model untuk data client
- `contactability.dart` - Model untuk data contactability dengan enum
- `api_models.dart` - Model untuk request/response API dan pagination

#### Services (`lib/core/services/`)
- `api_service.dart` - HTTP client service dengan error handling

#### Repositories (`lib/core/repositories/`)
- `client_repository.dart` - Repository untuk client dan contactability API calls

#### Controllers (`lib/core/controllers/`)
- `client_controller.dart` - State management untuk client data
- `contactability_controller.dart` - State management untuk contactability data

### Screens Layer (`lib/screens/`)

#### Updated Screens
- `create_contactability_tab.dart` - List client dengan data dari API
- `client_details_screen.dart` - Detail client dengan 2 tab (details + history)
- `contactability_form_screen.dart` - Form untuk submit contactability

### Widgets Layer (`lib/widgets/`)
- `common_widgets.dart` - Loading dan error widgets yang reusable

## Fitur Yang Sudah Diimplementasi

### 1. **API Integration**
- HTTP client dengan error handling
- Automatic retry mechanism
- Request/response models
- Pagination support

### 2. **State Management**
- Provider pattern untuk state management
- Loading states untuk UI feedback
- Error handling dengan user-friendly messages

### 3. **Client Management**
- List client dengan optimasi berdasarkan jarak
- Filter dan search functionality
- Pagination untuk performa optimal
- Client details dengan informasi lengkap

### 4. **Contactability Management**
- Form contactability yang unified untuk semua channel (Call, Message, Visit)
- History contactability dengan pagination
- Real-time location tracking
- Validation untuk semua input

### 5. **UI/UX Improvements**
- Loading indicators
- Error messages dengan retry functionality
- Refresh-to-reload
- Status indicators dengan color coding
- Responsive design

## API Endpoints yang Digunakan

### Client Endpoints
```
GET /api/v1/clients - List clients dengan filter dan pagination
GET /api/v1/clients/:id - Get client by ID
PUT /api/v1/clients/:id/status - Update client status
```

### Contactability Endpoints
```
POST /api/v1/contactability - Create new contactability record
GET /api/v1/clients/:id/contactability - Get contactability history by client
GET /api/v1/contactability/:id - Get contactability by ID
PUT /api/v1/contactability/:id - Update contactability
DELETE /api/v1/contactability/:id - Delete contactability
```

## Environment Configuration

Ubah base URL di `lib/core/config/env_config.dart`:

```dart
static const String _baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://localhost:3000', // Ganti sesuai server
);
```

Atau set environment variable saat build:
```bash
flutter run --dart-define=BASE_URL=https://your-api-server.com
```

## Error Handling

Sistem error handling yang comprehensive:
- Network errors
- Timeout errors
- Authentication errors
- Validation errors
- Server errors

## Cara Penggunaan

1. **Install dependencies:**
```bash
flutter pub get
```

2. **Update base URL di env_config.dart**

3. **Gunakan screen yang sudah terupdate:**
   - File `CreateContactabilityTab`, `ClientDetailsScreen`, dan `ContactabilityFormScreen` sudah terintegrasi dengan backend
   - Tidak perlu mengganti import atau class name lagi

4. **Provider sudah ter-register di main.dart**

## Pengembangan Selanjutnya

1. **Authentication Integration**
   - JWT token management
   - Refresh token mechanism
   - User profile management

2. **Offline Support**
   - Local database (SQLite/Hive)
   - Sync mechanism
   - Conflict resolution

3. **Real-time Features**
   - WebSocket connection
   - Push notifications
   - Live location tracking

4. **Analytics & Reporting**
   - Performance metrics
   - User behavior tracking
   - Custom reports

## Testing

Struktur ini mendukung unit testing untuk:
- Repository layer
- Controller layer
- Utility functions
- Validation logic

## Performance Optimization

- Lazy loading dengan pagination
- Image caching
- Network request caching
- Memory management

Struktur ini sudah siap untuk pengembangan jangka panjang dengan maintainability dan scalability yang baik.
