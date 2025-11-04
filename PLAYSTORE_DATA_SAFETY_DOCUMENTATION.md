# Data Safety Documentation for Google Play Store
## Field Investigator App (Collection Agent)

**Last Updated:** November 3, 2025  
**App Version:** 1.0.0+1  
**Developer:** Skorcard

---

## 📋 Executive Summary

Field Investigator App (Collection Agent) adalah aplikasi mobile untuk field agents yang melakukan collection activities terhadap client dengan tunggakan pembayaran. Aplikasi ini mengumpulkan data lokasi, foto, dan informasi kontak untuk keperluan field visit documentation dan reporting.

---

## 🔒 Data Collection & Usage

### 1. **Location Data**

#### Data Collected:
- **GPS Coordinates** (Latitude & Longitude)
- **Precise Location** (ACCESS_FINE_LOCATION)
- **Approximate Location** (ACCESS_COARSE_LOCATION)
- **Background Location** (ACCESS_BACKGROUND_LOCATION)

#### Purpose:
- Track field agent's location during client visits
- Calculate distance to client locations
- Verify field visit authenticity
- Display client locations on maps
- Navigate to client addresses using Google Maps

#### Collection Method:
- Collected only when app is in use (foreground)
- Background location used for visit tracking
- Using Geolocator package (version 11.0.0)

#### Data Transmission:
- **Transmitted to:** Skorcard Backend API (n8n-sit.skorcard.app, n8n.skorcard.app)
- **Encryption:** HTTPS/TLS
- **Storage:** Temporarily stored locally, synced to cloud

#### User Control:
- Users must grant location permission
- Permission can be revoked in device settings
- App will not function properly without location access

---

### 2. **Photos & Images**

#### Data Collected:
- **Visit Photos** (up to 3 images per visit/message)
- **Client KTP Photos** (downloaded from server)
- **Client Selfie Photos** (downloaded from server)

#### Purpose:
- Document field visits
- Verify client identity
- Evidence of contact attempts
- Visual proof of visit location and conditions

#### Collection Method:
- Camera: Real-time capture during visits
- Gallery: Selection from device storage
- Download: Client photos from API server

#### Data Transmission:
- **Transmitted to:** Skorcard Backend API
- **Format:** JPEG/PNG via multipart/form-data
- **Encryption:** HTTPS/TLS
- **Max Size:** 1920x1080, 85% quality

#### Local Storage:
- Visit photos: Temporary storage during submission
- Client photos: Cached in app documents directory (`photos/[userId]/`)
- Automatically cleaned after successful upload

#### Permissions Required:
- `CAMERA` - Capture photos
- `READ_EXTERNAL_STORAGE` - Select from gallery
- `WRITE_EXTERNAL_STORAGE` - Save cached photos

---

### 3. **Personal Information**

#### Data Collected:
- **User Information:**
  - Name (Field Agent)
  - Email address
  - Team name
  - Login credentials
  
- **Client Information (Read-Only):**
  - Full name
  - Phone numbers (mobile, home, office, emergency contacts)
  - Address (current, KTP, office)
  - Client ID
  - Financial data (Outstanding amounts, payment history)
  - Employment information

#### Purpose:
- Authentication and authorization
- Activity tracking and reporting
- Client identification
- Contact management
- Performance metrics

#### Data Source:
- User data: Entered during login
- Client data: Retrieved from Skorcard Backend API (read-only)

#### Data Transmission:
- **Transmitted to:** Skorcard Backend API
- **Encryption:** HTTPS/TLS
- **Storage:** User credentials stored in SharedPreferences (encrypted)

---

### 4. **Activity & Contact History**

#### Data Collected:
- **Contactability Records:**
  - Contact channel (Call/Message/Visit)
  - Contact result
  - Contact date & time (Jakarta timezone)
  - Person contacted
  - Action location
  - Visit notes/Call notes/Message content
  - Promise to Pay (PTP) details (amount, date)
  - New phone numbers discovered
  - New addresses discovered
  
- **Performance Metrics:**
  - Visit count
  - Call count
  - Message count
  - RPC/TPC/OPC counts
  - PTP counts

#### Purpose:
- Track collection activities
- Monitor agent performance
- Generate reports
- Audit trail
- PTP management

#### Data Transmission:
- **Transmitted to:** Skorcard Backend API
- **Encryption:** HTTPS/TLS
- **Real-time sync:** Immediate upon submission

---

### 5. **Device & App Data**

#### Data Collected:
- Device timezone information
- App version
- Platform (Android/iOS)
- Network connectivity status

#### Purpose:
- Timestamp accuracy (Jakarta timezone)
- Bug tracking & debugging
- App functionality
- Offline detection

#### Data NOT Collected:
- Device identifiers (IMEI, Serial Number)
- Advertising ID
- Device contacts
- SMS/Call logs
- Installed apps list
- Clipboard data

---

## 🌐 Network & API Endpoints

### API Servers:
1. **n8n.skorcard.app** (Production)
2. **n8n-sit.skorcard.app** (SIT Environment)

### Endpoints Used:
| Endpoint | Purpose | Data Sent |
|----------|---------|-----------|
| `/webhook/a307571b-*` | Fetch clients list | FI Owner email |
| `/webhook/95709b0d-*` | Submit contactability | All form data + images |
| `/webhook/c8e14ad2-*` | Fetch user photos | User ID |
| `/webhook/f811b60c-*` | Fetch location history | Skor User ID |
| `/webhook/aade8018-*` | Fetch client addresses | Skor User ID |
| `/webhook/e3f3398d-*` | Fetch dashboard performance | FI Owner email |
| `/webhook/ba90b87e-*` | Fetch attendance history | User ID |
| `/webhook/d540950f-*` | Fetch contactability history | FI Owner email |
| `/webhook/[skip-tracing]` | Fetch alternative phone numbers | Client ID |

### Security:
- All API calls use **HTTPS/TLS encryption**
- Content-Type: application/json
- Request timeout: 30-60 seconds
- No sensitive data in URL parameters

---

## 📱 Permissions Required

### Android Permissions (AndroidManifest.xml):

```xml
<!-- Location Permissions -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Network Permission -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Camera & Storage (Implicit via image_picker) -->
<!-- CAMERA - Runtime permission -->
<!-- READ_EXTERNAL_STORAGE - Runtime permission -->
<!-- WRITE_EXTERNAL_STORAGE - Runtime permission -->
```

### iOS Permissions (Info.plist equivalent):
- **Location When In Use** (NSLocationWhenInUseUsageDescription)
- **Location Always** (NSLocationAlwaysAndWhenInUseUsageDescription)
- **Camera** (NSCameraUsageDescription)
- **Photo Library** (NSPhotoLibraryUsageDescription)

### Runtime Permissions:
Users are prompted to grant permissions when:
1. First launch (Location)
2. First camera use (Camera)
3. First gallery access (Photos)

---

## 🔐 Data Security Measures

### Encryption:
- **In Transit:** All API calls use HTTPS/TLS 1.2+
- **At Rest:** User credentials encrypted in SharedPreferences
- **Photos:** Stored in app-private directory, not accessible by other apps

### Data Retention:
- **Local Cache:** 3-24 hours (configurable)
- **User Session:** Until logout
- **Photos:** Cleared after successful upload or manual clear
- **Server-side:** Managed by Skorcard Backend (not controlled by app)

### Screenshot Protection:
- **Android:** FLAG_SECURE enabled (blocks screenshots & screen recording)
- **iOS:** Detection alerts + security overlay on background

### Access Control:
- Login required (email/password)
- Session-based authentication
- Auto-logout on app termination (optional)

---

## 👤 User Rights & Controls

### Data Access:
- Users can view their own data within the app
- Client data is read-only (no editing)
- Performance metrics are personal to each user

### Data Deletion:
- Users can logout to clear local cache
- Request data deletion from Skorcard Backend separately
- Clear cached photos via app settings (future feature)

### Opt-Out:
- Users can revoke permissions in device settings
- App functionality will be limited without permissions
- No data collection when permissions are denied

---

## 🎯 Data Usage Purposes

### Primary Purposes:
1. **Field Visit Documentation** - Photos, location, notes
2. **Client Management** - Contact information, visit history
3. **Performance Tracking** - Activity metrics, PTP tracking
4. **Navigation** - Google Maps integration for client locations
5. **Communication** - WhatsApp, Phone calls to clients

### Data NOT Used For:
- ❌ Advertising
- ❌ Analytics for marketing
- ❌ Selling to third parties
- ❌ User profiling beyond job requirements
- ❌ Location tracking outside of work context

---

## 🔄 Third-Party Services

### Services Integrated:
1. **Google Maps**
   - Purpose: Navigation to client locations
   - Data Shared: GPS coordinates
   - Privacy: [Google Maps Privacy Policy](https://policies.google.com/privacy)

2. **WhatsApp (Deep Link)**
   - Purpose: Contact clients via WhatsApp
   - Data Shared: Phone number (via URL)
   - No direct API integration

3. **Phone Dialer (Deep Link)**
   - Purpose: Make phone calls to clients
   - Data Shared: Phone number (via intent)
   - System default dialer

### No Third-Party SDKs:
- ✅ No Firebase Analytics
- ✅ No Facebook SDK
- ✅ No Ad Networks
- ✅ No Crash Reporting (external)

---

## 📊 Data Safety Form Answers (Google Play Console)

### Data Collection:
**Does your app collect or share any of the required user data types?**
- ✅ **Yes**

### Data Types Collected:

#### Location:
- ✅ **Approximate location** - Required for functionality
- ✅ **Precise location** - Required for functionality
- **Purpose:** App functionality, Fraud prevention
- **Collection:** Ephemeral (not stored permanently)

#### Photos and videos:
- ✅ **Photos** - Required for functionality
- **Purpose:** App functionality
- **Collection:** Optional

#### Personal info:
- ✅ **Name** - Required for functionality
- ✅ **Email address** - Required for functionality
- **Purpose:** App functionality, Account management
- **Collection:** Required

#### App activity:
- ✅ **App interactions** (Visit history, contact logs)
- **Purpose:** App functionality, Analytics
- **Collection:** Required

### Data Security:
- ✅ Data is encrypted in transit (HTTPS/TLS)
- ✅ Users can request data deletion
- ✅ Data is not shared with third parties (except Skorcard Backend)
- ⚠️ Data is not encrypted at rest (except user credentials)

### Data Sharing:
**Is data shared with third parties?**
- ❌ **No** - Data is only sent to Skorcard's own backend servers

---

## 📝 Privacy Policy Requirements

Your app must have a **Privacy Policy URL** that covers:
1. What data is collected
2. How data is used
3. How data is shared (if applicable)
4. How users can request data deletion
5. Contact information for privacy concerns

**Recommended Privacy Policy URL:**
`https://skorcard.app/privacy-policy` (to be created)

---

## ✅ Compliance Checklist

- [x] Data collection is minimal and justified
- [x] Users are informed about data collection (this document)
- [x] Users can control permissions
- [x] Data is encrypted in transit (HTTPS/TLS)
- [x] Sensitive data handling follows best practices
- [x] No unnecessary permissions requested
- [x] Screenshot protection for sensitive information
- [x] Clear purpose for each data type
- [x] No sharing with advertisers or analytics providers
- [x] Privacy policy prepared/referenced

---

## 📞 Contact Information

**Developer:** Skorcard  
**Support Email:** support@skorcard.app (example)  
**Privacy Inquiries:** privacy@skorcard.app (example)

---

## 📚 Additional Resources

- [Google Play Data Safety Guide](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Android Privacy Best Practices](https://developer.android.com/privacy)
- [Flutter Privacy Guide](https://docs.flutter.dev/security/privacy)

---

**Note to Developer:**
Before submitting to Play Store, ensure:
1. Privacy Policy URL is live and accessible
2. Support email is monitored
3. All API endpoints are production-ready
4. Screenshot protection is tested
5. Permission handling is user-friendly
6. Data deletion process is documented

---

*This document should be reviewed and updated whenever the app's data collection practices change.*
