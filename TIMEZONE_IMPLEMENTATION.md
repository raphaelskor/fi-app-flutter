# Timezone Implementation (GMT+7 Jakarta Time)

## Ringkasan Perubahan

Aplikasi telah dipastikan menggunakan timezone Jakarta (GMT+7) untuk semua timestamp yang berkaitan dengan:

### 1. Form Contactability
- **Waktu form dibuka**: `contactabilityDateTime` menggunakan Jakarta time
- **Tanggal PTP**: Date picker menggunakan Jakarta time untuk validasi
- **Submit timestamp**: Data yang dikirim ke API menggunakan format Jakarta time

### 2. API Response Parsing
- **Created_Time**: Parsing dari API response dikonversi ke Jakarta time
- **Modified_Time**: Parsing dari API response dikonversi ke Jakarta time  
- **Visit_Date**: Parsing dari API response dikonversi ke Jakarta time

### 3. Cache System
- **Daily cache validation**: Menggunakan Jakarta date untuk validasi cache harian
- **Cache expiry**: Berdasarkan tanggal Jakarta, bukan UTC

### 4. Display Format
- **Indonesian date format**: "25 Juli 2025" menggunakan Jakarta time
- **History timestamps**: Semua tampilan waktu dalam format Jakarta time

## Implementasi Teknis

### TimezoneUtils Class
File: `lib/core/utils/timezone_utils.dart`

Utility class yang menyediakan:
- `nowInJakarta()` - Current time dalam Jakarta timezone
- `toJakarta(DateTime)` - Convert ke Jakarta timezone
- `formatIndonesianDate()` - Format tanggal Indonesia
- `formatDateForApi()` - Format YYYY-MM-DD untuk API
- `parseApiDateTime()` - Parse response API ke Jakarta time

### Field-field yang Menggunakan Jakarta Time

1. **ContactabilityController**:
   - `_contactabilityDateTime` - Set saat form dibuka
   - PTP date submission ke API

2. **ContactabilityHistory**:
   - `createdTime`, `modifiedTime`, `visitDate` - Parsing dari API

3. **DailyCacheService**:
   - Cache validation berdasarkan tanggal Jakarta

4. **Form Screen**:
   - Display current date/time
   - PTP date picker range validation

## Validasi Timezone

Semua timestamp kini konsisten menggunakan GMT+7:
- ✅ Form submission timestamp
- ✅ PTP date validation (hari ini sampai 5 hari ke depan)
- ✅ API response parsing
- ✅ Cache system daily validation
- ✅ Display format (Indonesian date)
- ✅ Historical data timestamps

## Debugging

Untuk memverifikasi timezone:
1. Check console logs yang menampilkan "(Jakarta Time)" atau "(GMT+7)"
2. Pastikan waktu yang ditampilkan sesuai dengan waktu lokal Indonesia
3. Validate PTP date picker hanya allow hari kerja (tidak Minggu)
4. Cache system refresh setiap hari berdasarkan tanggal Jakarta

## Catatan Penting

- Semua DateTime object internal aplikasi menggunakan Jakarta timezone
- API endpoint tetap menerima format yang sudah ditentukan (YYYY-MM-DD untuk tanggal)
- Display ke user menggunakan format Indonesia "25 Juli 2025"
- Cache validation menggunakan tanggal Jakarta untuk memastikan refresh harian yang tepat
