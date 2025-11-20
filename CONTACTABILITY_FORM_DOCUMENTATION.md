# 📋 Contactability Form - Complete Technical Documentation

## Overview

Form untuk mencatat kontak dengan client (debitur). Form ini memiliki **3 channel berbeda** (Visit, Call, Message) dengan field dan opsi yang berbeda untuk setiap channel.

**API Endpoint untuk Submit:**
```
POST https://n8n-sit.skorcard.app/webhook/95709b0d-0d03-4710-85d5-d72f14359ee4
```

---

## 🎯 Form Structure Overview

### Common Information (Semua Channel)
1. **Client Information** (Read-only display)
   - Client Name
   - Phone Number
   - Address

2. **Contactability Information** (Auto-filled)
   - Date (auto: current date in Jakarta timezone)
   - Time (auto: current time in Jakarta timezone)
   - Location (auto-filled untuk Visit channel, dengan refresh & map buttons)

3. **Channel Selection** (3 options)
   - Visit
   - Call
   - Message

4. **Person Contacted** (Dropdown - REQUIRED untuk semua channel)

5. **Action Location** (Dropdown - REQUIRED untuk semua channel, opsi berbeda per channel)

6. **Contact Result** (Dropdown - REQUIRED untuk semua channel, opsi berbeda per channel)

7. **PTP Fields** (Conditional - muncul jika Contact Result = "Promise to Pay (PTP)")
   - PTP Amount (Required if shown)
   - PTP Date (Required if shown)

8. **Notes** (Text area - REQUIRED untuk semua channel, label berbeda per channel)
   - Visit → "Visit Notes"
   - Call → "Call Notes"
   - Message → "Message Content"

9. **New Phone Number** (Optional untuk semua channel)

10. **New Address** (Optional untuk semua channel)

11. **Image Upload** (Conditional berdasarkan channel)
    - Visit: 0-3 images (REQUIRED minimal 1)
    - Message: 0-3 images (REQUIRED minimal 1)
    - Call: No images allowed

---

## 📝 Field Details by Channel

### 🔷 CHANNEL 1: VISIT

#### Fields yang Ditampilkan:
1. ✅ **Client Information** (read-only)
2. ✅ **Date & Time** (auto-filled)
3. ✅ **Location** (auto-filled GPS coordinates) + Refresh button + Map button
4. ✅ **Channel Selection** → "Visit" selected
5. ✅ **Person Contacted** (dropdown - REQUIRED)
6. ✅ **Action Location** (dropdown - REQUIRED)
7. ✅ **Image Upload** (0-3 images, REQUIRED minimal 1)
8. ✅ **Contact Result** (dropdown - REQUIRED)
9. ✅ **PTP Fields** (conditional, muncul jika Contact Result = PTP)
10. ✅ **Visit Notes** (text area - REQUIRED)
11. ✅ **New Phone Number** (optional)
12. ✅ **New Address** (optional)

---

#### Field: Person Contacted (16 options)

**Type:** Dropdown (single select)  
**Required:** Yes  
**Options:**

| # | Value | Display Name |
|---|-------|--------------|
| 1 | `Debtor` | Debtor |
| 2 | `Spouse` | Spouse |
| 3 | `Son` | Son |
| 4 | `Daughter` | Daughter |
| 5 | `Father` | Father |
| 6 | `Mother` | Mother |
| 7 | `Brother` | Brother |
| 8 | `Sister` | Sister |
| 9 | `House Assistant` | House Assistant |
| 10 | `House Security` | House Security |
| 11 | `Area Security` | Area Security |
| 12 | `Office Security` | Office Security |
| 13 | `Receptionist` | Receptionist |
| 14 | `Guest` | Guest |
| 15 | `Neighbor` | Neighbor |
| 16 | `Emergency Contact` | Emergency Contact |

---

#### Field: Action Location (5 options untuk Visit)

**Type:** Dropdown (single select)  
**Required:** Yes  
**Options:**

| # | Value | Display Name |
|---|-------|--------------|
| 1 | `Alamat Korespondensi` | Alamat Korespondensi |
| 2 | `Alamat Kantor` | Alamat Kantor |
| 3 | `Alamat Rumah` | Alamat Rumah |
| 4 | `Alamat KTP` | Alamat KTP |
| 5 | `Alamat Lain` | Alamat Lain |

---

#### Field: Contact Result (27 options untuk Visit)

**Type:** Dropdown (single select)  
**Required:** Yes  
**Options:**

**Visit-Specific Results (18 options):**

| # | Value | Display Name |
|---|-------|--------------|
| 1 | `Alamat Ditemukan, Rumah Kosong` | Alamat Ditemukan, Rumah Kosong |
| 2 | `Dilarang Masuk Perumahan` | Dilarang Masuk Perumahan |
| 3 | `Dilarang Masuk Kantor` | Dilarang Masuk Kantor |
| 4 | `Menghindar` | Menghindar |
| 5 | `Titip Surat` | Titip Surat |
| 6 | `Alamat Tidak Ditemukan` | Alamat Tidak Ditemukan |
| 7 | `Alamat Salah` | Alamat Salah |
| 8 | `Konsumen Tidak Dikenal` | Konsumen Tidak Dikenal |
| 9 | `Pindah, Tidak Ditemukan` | Pindah, Tidak Ditemukan |
| 10 | `Pindah, Alamat Baru` | Pindah, Alamat Baru |
| 11 | `Meninggal Dunia` | Meninggal Dunia |
| 12 | `Mengundurkan Diri` | Mengundurkan Diri |
| 13 | `Berhenti Bekerja` | Berhenti Bekerja |
| 14 | `Sedang Renovasi` | Sedang Renovasi |
| 15 | `Bencana Alam` | Bencana Alam |
| 16 | `Kondisi Medis` | Kondisi Medis |
| 17 | `Sengketa Hukum` | Sengketa Hukum |
| 18 | `Kunjungan Ulang` | Kunjungan Ulang |

**Common Results (9 options - tersedia untuk semua channel):**

| # | Value | Display Name |
|---|-------|--------------|
| 19 | `Promise to Pay (PTP)` | Promise to Pay (PTP) ⭐ |
| 20 | `Negotiation` | Negotiation |
| 21 | `Hot Prospect` | Hot Prospect |
| 22 | `Already Paid` | Already Paid |
| 23 | `Refuse to Pay` | Refuse to Pay |
| 24 | `Dispute` | Dispute |
| 25 | `Not Recognized` | Not Recognized |
| 26 | `Partial Payment` | Partial Payment |
| 27 | `Failed to Pay` | Failed to Pay |

**⭐ Special:** Jika user pilih "Promise to Pay (PTP)", maka **PTP Fields Section** akan muncul.

---

#### Section: PTP Fields (Conditional)

**Display Condition:** Contact Result = "Promise to Pay (PTP)"

**Field 1: PTP Amount**
- **Type:** Text input with currency formatting (Rupiah)
- **Format:** Auto-format as "Rp 1.000.000" saat user mengetik
- **Validation:** Required jika section muncul
- **Example:** User ketik "1000000" → auto-format menjadi "Rp 1.000.000"

**Field 2: PTP Date**
- **Type:** Date picker
- **Validation:** Required jika section muncul
- **Rules:**
  - Minimum date: Today (tidak bisa pilih tanggal kemarin)
  - Maximum date: Today + 5 days
  - Blocked days: Sunday (tidak bisa pilih hari Minggu)
- **Format Display:** DD MMM YYYY (contoh: "07 Nov 2024")
- **Format Submit ke API:** YYYY-MM-DD (contoh: "2024-11-07")

---

#### Field: Image Upload (0-3 images)

**Type:** Image upload (Camera atau Gallery)  
**Required:** Yes (minimal 1 image)  
**Maximum:** 3 images  
**Features:**
- Button "Camera" untuk ambil foto dari kamera
- Button "Gallery" untuk pilih dari galeri
- Preview thumbnail untuk setiap image yang dipilih
- Button X (delete) di setiap thumbnail untuk hapus image
- Disable upload buttons jika sudah 3 images

---

#### Field: Visit Notes

**Type:** Multi-line text area  
**Required:** Yes  
**Label:** "Visit Notes"  
**Placeholder:** "Describe what happened during the visit..."  
**Max Lines:** 4 lines  
**Validation:** Cannot be empty

---

#### Field: New Phone Number

**Type:** Text input dengan formatting  
**Required:** No (optional)  
**Format:** Prefix "+62 " + digits only  
**Example:** User ketik "812321561" → display sebagai "+62 812321561"  
**Validation:** Digits only, max 13 digits setelah 62

---

#### Field: New Address

**Type:** Multi-line text area  
**Required:** No (optional)  
**Label:** "New Address"  
**Placeholder:** "New address found during contact..."  
**Max Lines:** 3 lines

---

### 🔷 CHANNEL 2: CALL

#### Fields yang Ditampilkan:
1. ✅ **Client Information** (read-only)
2. ✅ **Date & Time** (auto-filled)
3. ✅ **Channel Selection** → "Call" selected
4. ✅ **Person Contacted** (dropdown - REQUIRED)
5. ✅ **Action Location** (dropdown - REQUIRED)
6. ✅ **Contact Result** (dropdown - REQUIRED)
7. ✅ **PTP Fields** (conditional, muncul jika Contact Result = PTP)
8. ✅ **Call Notes** (text area - REQUIRED)
9. ✅ **New Phone Number** (optional)
10. ✅ **New Address** (optional)

**❌ TIDAK ADA:**
- Location (GPS coordinates)
- Image Upload

---

#### Field: Person Contacted (16 options)

**SAMA seperti Visit channel** (lihat section Visit di atas)

---

#### Field: Action Location (6 options untuk Call)

**Type:** Dropdown (single select)  
**Required:** Yes  
**Options:**

| # | Value | Display Name |
|---|-------|--------------|
| 1 | `Customer Mobile` | Customer Mobile |
| 2 | `Econ 1` | Econ 1 |
| 3 | `Econ 2` | Econ 2 |
| 4 | `Office` | Office |
| 5 | `Skip Tracing Number` | Skip Tracing Number |
| 6 | `Phone Contact` | Phone Contact |

---

#### Field: Contact Result (9 options untuk Call)

**Type:** Dropdown (single select)  
**Required:** Yes  
**Options:**

**HANYA Common Results (tidak ada opsi khusus Call):**

| # | Value | Display Name |
|---|-------|--------------|
| 1 | `Promise to Pay (PTP)` | Promise to Pay (PTP) ⭐ |
| 2 | `Negotiation` | Negotiation |
| 3 | `Hot Prospect` | Hot Prospect |
| 4 | `Already Paid` | Already Paid |
| 5 | `Refuse to Pay` | Refuse to Pay |
| 6 | `Dispute` | Dispute |
| 7 | `Not Recognized` | Not Recognized |
| 8 | `Partial Payment` | Partial Payment |
| 9 | `Failed to Pay` | Failed to Pay |

**⭐ Special:** Jika user pilih "Promise to Pay (PTP)", maka **PTP Fields Section** akan muncul (sama seperti Visit).

---

#### Section: PTP Fields (Conditional)

**SAMA seperti Visit channel** (lihat section Visit di atas)

---

#### Field: Call Notes

**Type:** Multi-line text area  
**Required:** Yes  
**Label:** "Call Notes"  
**Placeholder:** "Describe what happened during the call..."  
**Max Lines:** 4 lines  
**Validation:** Cannot be empty

---

#### Field: New Phone Number & New Address

**SAMA seperti Visit channel** (lihat section Visit di atas)

---

### 🔷 CHANNEL 3: MESSAGE (WhatsApp/SMS)

#### Fields yang Ditampilkan:
1. ✅ **Client Information** (read-only)
2. ✅ **Date & Time** (auto-filled)
3. ✅ **Channel Selection** → "Message" selected
4. ✅ **Person Contacted** (dropdown - REQUIRED)
5. ✅ **Action Location** (dropdown - REQUIRED)
6. ✅ **Image Upload** (0-3 images, REQUIRED minimal 1)
7. ✅ **Contact Result** (dropdown - REQUIRED)
8. ✅ **PTP Fields** (conditional, muncul jika Contact Result = PTP)
9. ✅ **Message Content** (text area - REQUIRED)
10. ✅ **New Phone Number** (optional)
11. ✅ **New Address** (optional)

**❌ TIDAK ADA:**
- Location (GPS coordinates)

---

#### Field: Person Contacted (16 options)

**SAMA seperti Visit channel** (lihat section Visit di atas)

---

#### Field: Action Location (6 options untuk Message)

**Type:** Dropdown (single select)  
**Required:** Yes  
**Options:**

**SAMA seperti Call channel:**

| # | Value | Display Name |
|---|-------|--------------|
| 1 | `Customer Mobile` | Customer Mobile |
| 2 | `Econ 1` | Econ 1 |
| 3 | `Econ 2` | Econ 2 |
| 4 | `Office` | Office |
| 5 | `Skip Tracing Number` | Skip Tracing Number |
| 6 | `Phone Contact` | Phone Contact |

---

#### Field: Image Upload (0-3 images)

**SAMA seperti Visit channel** (lihat section Visit di atas)

---

#### Field: Contact Result (16 options untuk Message)

**Type:** Dropdown (single select)  
**Required:** Yes  
**Options:**

**Message-Specific Results (7 options):**

| # | Value | Display Name |
|---|-------|--------------|
| 1 | `WA One Tick` | WA One Tick |
| 2 | `WA Two Tick` | WA Two Tick |
| 3 | `WA Blue Tick` | WA Blue Tick |
| 4 | `WA Not Registered` | WA Not Registered |
| 5 | `SP 1` | SP 1 |
| 6 | `SP 2` | SP 2 |
| 7 | `SP 3` | SP 3 |

**Common Results (9 options):**

| # | Value | Display Name |
|---|-------|--------------|
| 8 | `Promise to Pay (PTP)` | Promise to Pay (PTP) ⭐ |
| 9 | `Negotiation` | Negotiation |
| 10 | `Hot Prospect` | Hot Prospect |
| 11 | `Already Paid` | Already Paid |
| 12 | `Refuse to Pay` | Refuse to Pay |
| 13 | `Dispute` | Dispute |
| 14 | `Not Recognized` | Not Recognized |
| 15 | `Partial Payment` | Partial Payment |
| 16 | `Failed to Pay` | Failed to Pay |

**⭐ Special:** Jika user pilih "Promise to Pay (PTP)", maka **PTP Fields Section** akan muncul (sama seperti Visit).

---

#### Section: PTP Fields (Conditional)

**SAMA seperti Visit channel** (lihat section Visit di atas)

---

#### Field: Message Content

**Type:** Multi-line text area  
**Required:** Yes  
**Label:** "Message Content"  
**Placeholder:** "Enter the message sent to the client..."  
**Max Lines:** 4 lines  
**Validation:** Cannot be empty

---

#### Field: New Phone Number & New Address

**SAMA seperti Visit channel** (lihat section Visit di atas)

---

## 🚀 API Submission

### Endpoint
```
POST https://n8n-sit.skorcard.app/webhook/95709b0d-0d03-4710-85d5-d72f14359ee4
```

### Content-Type
- **WITH Images** (Visit/Message dengan images): `multipart/form-data`
- **WITHOUT Images** (Call atau Visit/Message tanpa images): `application/json`

---

### Request Body Structure

#### Payload Fields (JSON)

```javascript
{
  // ===== REQUIRED FIELDS (semua channel) =====
  "id": "3770745000008039001",              // Client ID (Zoho CRM ID)
  "User_ID": "USER123",                     // Client's Skor User ID
  "Channel": "Visit",                        // "Visit" | "Call" | "Message"
  "FI_Owner": "agent@skorcard.com",         // Email agent yang login
  "Person_Contacted": "Debtor",             // Dari dropdown
  "Action_Location": "Alamat Korespondensi", // Dari dropdown
  "Contact_Result": "Promise to Pay (PTP)", // Dari dropdown
  "Visit_Notes": "Client berjanji bayar...", // Notes (label berbeda per channel)
  "Visit_by_Skor_Team": "Yes",              // Auto-set berdasarkan team user
  
  // ===== CONDITIONAL FIELDS =====
  // Location (HANYA untuk Visit channel)
  "Visit_Lat_Long": "-6.2088,106.8456",     // Format: "latitude,longitude"
  
  // PTP Fields (HANYA jika Contact_Result = "Promise to Pay (PTP)")
  "P2p_Amount": "1000000",                   // String angka saja (tanpa "Rp" atau separator)
  "P2p_Date": "2024-11-07",                  // Format: YYYY-MM-DD
  
  // ===== OPTIONAL FIELDS =====
  "Visit_Agent": "Agent Name",               // Auto-filled dari user data
  "Visit_Agent_Team_Lead": "Team Name",      // Auto-filled dari user data
  "New_Phone_Number": "+628123456789",       // Jika user isi
  "New_Address": "Jl. Baru No. 123"          // Jika user isi
}
```

---

### Complete Request Examples

#### Example 1: Visit Channel WITH Images

**Content-Type:** `multipart/form-data`

**Form Data:**
```
body = {
  "id": "3770745000008039001",
  "User_ID": "USER123",
  "Channel": "Visit",
  "FI_Owner": "agent@skorcard.com",
  "Visit_Lat_Long": "-6.2088,106.8456",
  "Person_Contacted": "Debtor",
  "Action_Location": "Alamat Korespondensi",
  "Contact_Result": "Promise to Pay (PTP)",
  "P2p_Amount": "1000000",
  "P2p_Date": "2024-11-10",
  "Visit_Notes": "Client berjanji bayar tanggal 10 November",
  "Visit_by_Skor_Team": "Yes",
  "Visit_Agent": "John Doe",
  "Visit_Agent_Team_Lead": "Jakarta Team",
  "New_Phone_Number": "+628123456789"
}

image1 = <File>
image2 = <File>
image3 = <File>
```

**JavaScript Example:**
```javascript
const formData = new FormData();

// Add JSON data as 'body' field (stringify)
const bodyData = {
  id: "3770745000008039001",
  User_ID: "USER123",
  Channel: "Visit",
  FI_Owner: "agent@skorcard.com",
  Visit_Lat_Long: "-6.2088,106.8456",
  Person_Contacted: "Debtor",
  Action_Location: "Alamat Korespondensi",
  Contact_Result: "Promise to Pay (PTP)",
  P2p_Amount: "1000000",
  P2p_Date: "2024-11-10",
  Visit_Notes: "Client berjanji bayar tanggal 10 November",
  Visit_by_Skor_Team: "Yes",
  Visit_Agent: "John Doe",
  Visit_Agent_Team_Lead: "Jakarta Team",
  New_Phone_Number: "+628123456789"
};

formData.append('body', JSON.stringify(bodyData));

// Add image files
if (image1File) formData.append('image1', image1File, image1File.name);
if (image2File) formData.append('image2', image2File, image2File.name);
if (image3File) formData.append('image3', image3File, image3File.name);

// Submit
fetch('https://n8n-sit.skorcard.app/webhook/95709b0d-0d03-4710-85d5-d72f14359ee4', {
  method: 'POST',
  body: formData
  // DON'T set Content-Type header! Browser will set it automatically with boundary
})
.then(response => response.json())
.then(data => console.log('Success:', data))
.catch(error => console.error('Error:', error));
```

---

#### Example 2: Call Channel (No Images)

**Content-Type:** `application/json`

**Request Body:**
```json
{
  "id": "3770745000008039001",
  "User_ID": "USER123",
  "Channel": "Call",
  "FI_Owner": "agent@skorcard.com",
  "Person_Contacted": "Spouse",
  "Action_Location": "Customer Mobile",
  "Contact_Result": "Negotiation",
  "Visit_Notes": "Istri debitur minta waktu untuk diskusi dengan suami",
  "Visit_by_Skor_Team": "No",
  "Visit_Agent": "Jane Smith",
  "Visit_Agent_Team_Lead": "Surabaya Team"
}
```

**JavaScript Example:**
```javascript
const bodyData = {
  id: "3770745000008039001",
  User_ID: "USER123",
  Channel: "Call",
  FI_Owner: "agent@skorcard.com",
  Person_Contacted: "Spouse",
  Action_Location: "Customer Mobile",
  Contact_Result: "Negotiation",
  Visit_Notes: "Istri debitur minta waktu untuk diskusi dengan suami",
  Visit_by_Skor_Team: "No",
  Visit_Agent: "Jane Smith",
  Visit_Agent_Team_Lead: "Surabaya Team"
};

fetch('https://n8n-sit.skorcard.app/webhook/95709b0d-0d03-4710-85d5-d72f14359ee4', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  },
  body: JSON.stringify(bodyData)
})
.then(response => response.json())
.then(data => console.log('Success:', data))
.catch(error => console.error('Error:', error));
```

---

#### Example 3: Message Channel WITH Images

**Content-Type:** `multipart/form-data`

**Form Data:**
```
body = {
  "id": "3770745000008039001",
  "User_ID": "USER123",
  "Channel": "Message",
  "FI_Owner": "agent@skorcard.com",
  "Person_Contacted": "Debtor",
  "Action_Location": "Customer Mobile",
  "Contact_Result": "WA Blue Tick",
  "Visit_Notes": "Pesan WA sudah dibaca tapi belum ada respon",
  "Visit_by_Skor_Team": "Yes",
  "Visit_Agent": "Agent Name",
  "Visit_Agent_Team_Lead": "Team Name"
}

image1 = <File> (screenshot WA)
```

---

### Success Response

```json
{
  "success": true,
  "message": "Contactability submitted successfully",
  "id": "contact_new_123"
}
```

### Error Response

```json
{
  "success": false,
  "error": "ERROR_CODE",
  "message": "Human readable error message"
}
```

---

## 📤 Data Format Reference

Bagian ini menjelaskan **format data yang harus digunakan saat submit ke API** vs **format yang ditampilkan ke user di UI**.

---

### 1️⃣ **Date Format**

| Aspect | Format | Example |
|--------|--------|---------|
| **Display di UI** | DD MMM YYYY | `07 Nov 2024` |
| **Submit ke API** | YYYY-MM-DD | `2024-11-07` |

**JavaScript Code:**
```javascript
// Display → API
function formatDateForAPI(displayDate) {
  const date = new Date(displayDate);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// Example
formatDateForAPI("07 Nov 2024") // Returns: "2024-11-07"
```

---

### 2️⃣ **Time Format**

| Aspect | Format | Example |
|--------|--------|---------|
| **Display di UI** | HH:MM WIB | `14:30 WIB` |
| **Submit ke API** | HH:MM:SS | `14:30:00` |

**JavaScript Code:**
```javascript
function formatTimeForAPI(displayTime) {
  // Remove timezone text
  const cleanTime = displayTime.replace(/\s*(WIB|WITA|WIT)\s*/gi, '').trim();
  
  // Ensure HH:MM:SS format
  const parts = cleanTime.split(':');
  if (parts.length === 2) {
    return `${parts[0].padStart(2, '0')}:${parts[1].padStart(2, '0')}:00`;
  }
  return cleanTime;
}

// Example
formatTimeForAPI("14:30 WIB") // Returns: "14:30:00"
```

**⚠️ Note:** Date & Time hanya untuk display, **TIDAK dikirim ke API** (API auto-generate server-side timestamp).

---

### 3️⃣ **Currency Format (PTP Amount)**

| Aspect | Format | Example |
|--------|--------|---------|
| **User Input** | Bebas | `1000000` atau `1.000.000` atau `Rp 1.000.000` |
| **Display di UI** | Rp X.XXX.XXX | `Rp 1.000.000` |
| **Submit ke API** | Digits only (String) | `"1000000"` |

**JavaScript Code:**
```javascript
// Format untuk Display (saat user mengetik)
function formatCurrencyDisplay(value) {
  const digits = value.replace(/\D/g, ''); // Remove all non-digits
  if (!digits) return '';
  const formatted = parseInt(digits).toLocaleString('id-ID');
  return `Rp ${formatted}`;
}

// Clean untuk API
function formatCurrencyForAPI(displayValue) {
  return displayValue.replace(/\D/g, ''); // Extract digits only
}

// Examples
formatCurrencyDisplay("1000000")        // Returns: "Rp 1.000.000"
formatCurrencyForAPI("Rp 1.000.000")    // Returns: "1000000"
```

---

### 4️⃣ **Phone Number Format**

| Aspect | Format | Example |
|--------|--------|---------|
| **User Input** | Bebas | `812321561` atau `0812321561` |
| **Display di UI** | +62 XXX-XXX-XXX | `+62 812-321-561` |
| **Submit ke API** | +62XXXXXXXXX (no separator) | `"+62812321561"` |

**JavaScript Code:**
```javascript
// Format untuk Display
function formatPhoneDisplay(value) {
  let digits = value.replace(/\D/g, '');
  
  // Remove leading 0
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  
  // Remove leading 62 if exists
  if (digits.startsWith('62')) {
    digits = digits.substring(2);
  }
  
  // Format with separator (optional for UI readability)
  if (digits.length >= 9) {
    return `+62 ${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}`;
  } else if (digits.length >= 3) {
    return `+62 ${digits.substring(0, 3)}-${digits.substring(3)}`;
  } else {
    return `+62 ${digits}`;
  }
}

// Clean untuk API (no separator)
function formatPhoneForAPI(displayValue) {
  let digits = displayValue.replace(/\D/g, '');
  
  // Remove leading 0
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  
  // Add 62 prefix if not exists
  if (!digits.startsWith('62')) {
    digits = '62' + digits;
  }
  
  return '+' + digits;
}

// Examples
formatPhoneDisplay("812321561")           // Returns: "+62 812-321-561"
formatPhoneDisplay("0812321561")          // Returns: "+62 812-321-561"
formatPhoneForAPI("+62 812-321-561")      // Returns: "+62812321561"
```

---

### 5️⃣ **Location Format (GPS Coordinates)**

| Aspect | Format | Example |
|--------|--------|---------|
| **Display di UI** | Lat: X, Lng: Y | `Lat: -6.2088, Lng: 106.8456` |
| **Submit ke API** | latitude,longitude (**NO SPACE**) | `"-6.2088,106.8456"` |

**JavaScript Code:**
```javascript
// Format untuk API
function formatLocationForAPI(lat, lng) {
  const latFixed = parseFloat(lat).toFixed(6);
  const lngFixed = parseFloat(lng).toFixed(6);
  
  // IMPORTANT: NO SPACE after comma!
  return `${latFixed},${lngFixed}`;
}

// Example
formatLocationForAPI(-6.2088, 106.8456)   // Returns: "-6.208800,106.845600"
```

**⚠️ CRITICAL:**
- ✅ Correct: `"-6.2088,106.8456"` (no space)
- ❌ Wrong: `"-6.2088, 106.8456"` (has space)
- ❌ Wrong: `"Lat: -6.2088, Lng: 106.8456"` (has label)

---

### 6️⃣ **Text Fields (Notes, Address)**

| Aspect | Format | Example |
|--------|--------|---------|
| **User Input** | Multi-line text | `"Line 1\nLine 2"` |
| **Submit ke API** | String with `\n` | `"Line 1\nLine 2"` |

**JavaScript Code:**
```javascript
// No special formatting needed, just trim whitespace
function formatNotesForAPI(notes) {
  return notes.trim();
}
```

---

### 7️⃣ **Dropdown Values**

| Aspect | Format | Example |
|--------|--------|---------|
| **Display di UI** | Exact string from dropdown | `"Debtor"`, `"Promise to Pay (PTP)"` |
| **Submit ke API** | **EXACT SAME STRING** | `"Debtor"`, `"Promise to Pay (PTP)"` |

**⚠️ CRITICAL - CASE SENSITIVE:**
- ✅ Correct: `"Debtor"`
- ❌ Wrong: `"debtor"` (lowercase)
- ❌ Wrong: `"DEBTOR"` (uppercase)

**⚠️ CRITICAL - EXACT MATCH:**
- ✅ Correct: `"Promise to Pay (PTP)"`
- ❌ Wrong: `"Promise to Pay"`
- ❌ Wrong: `"PTP"`

---

### 8️⃣ **Boolean Values (Visit by Skor Team)**

| Aspect | Format | Example |
|--------|--------|---------|
| **Logic** | Based on user team | Team = "Skorcard" → `"Yes"`, else → `"No"` |
| **Submit ke API** | **String** (NOT boolean) | `"Yes"` or `"No"` |

**JavaScript Code:**
```javascript
const userTeam = "Skorcard";
const visitBySkorTeam = userTeam === "Skorcard" ? "Yes" : "No";
```

**⚠️ CRITICAL:**
- ✅ Correct: `"Yes"` (string)
- ❌ Wrong: `true` (boolean)
- ✅ Correct: `"No"` (string)
- ❌ Wrong: `false` (boolean)

---

### 9️⃣ **Image Files**

#### **Upload ke API (Field Names)**
- Field names untuk submit: `image1`, `image2`, `image3` (lowercase, no underscore)
- Content-Type: `multipart/form-data`
- File format: JPEG, PNG recommended
- Max size: < 5MB per image (recommended)

#### **Response dari API (Field Names)**
- Field names dalam response: `Visit_Image_1`, `Visit_Image_2`, `Visit_Image_3` (uppercase with underscore)
- Value: Full URL path to uploaded image

**⚠️ IMPORTANT:**
- **Saat SUBMIT**: gunakan `image1`, `image2`, `image3`
- **Saat READ response**: API return dengan `Visit_Image_1`, `Visit_Image_2`, `Visit_Image_3`

**JavaScript Code - Upload:**
```javascript
const formData = new FormData();

// Add JSON body
formData.append('body', JSON.stringify({
  id: "3770745000008039001",
  // ... other fields
}));

// Add images - USE lowercase "image1", "image2", "image3"
if (image1File) {
  formData.append('image1', image1File, image1File.name);
}
if (image2File) {
  formData.append('image2', image2File, image2File.name);
}
if (image3File) {
  formData.append('image3', image3File, image3File.name);
}

// Submit
fetch('https://n8n-sit.skorcard.app/webhook/95709b0d-0d03-4710-85d5-d72f14359ee4', {
  method: 'POST',
  body: formData
  // DON'T set Content-Type! Browser will auto-set with boundary
});
```

**Example Response:**
```json
{
  "success": true,
  "id": "contact_123",
  "Visit_Image_1": "https://storage.skorcard.app/images/img1.jpg",
  "Visit_Image_2": "https://storage.skorcard.app/images/img2.jpg",
  "Visit_Image_3": "https://storage.skorcard.app/images/img3.jpg"
}
```

---

### 🎯 **Complete Example: User Input → API Payload**

```javascript
// ===== USER INPUT (what user sees/enters) =====
const userInput = {
  date: "07 Nov 2024",              // Display only, not sent to API
  time: "14:30 WIB",                // Display only, not sent to API
  location: { 
    lat: -6.2088, 
    lng: 106.8456 
  },
  personContacted: "Debtor",
  actionLocation: "Alamat Korespondensi",
  contactResult: "Promise to Pay (PTP)",
  ptpAmount: "Rp 1.000.000",        // Displayed with formatting
  ptpDate: "10 Nov 2024",           // Displayed in readable format
  notes: "Client berjanji bayar\ntanggal 10 November",
  newPhone: "812321561",            // User input without prefix
  images: [File1, File2, File3]     // 3 image files
};

// ===== API PAYLOAD (what to send) =====
const apiPayload = {
  // Required fields
  id: "3770745000008039001",
  User_ID: "USER123",
  Channel: "Visit",
  FI_Owner: "agent@skorcard.com",
  
  // Location (NO SPACE after comma!)
  Visit_Lat_Long: "-6.208800,106.845600",
  
  // Dropdowns (EXACT strings, case-sensitive)
  Person_Contacted: "Debtor",
  Action_Location: "Alamat Korespondensi",
  Contact_Result: "Promise to Pay (PTP)",
  
  // PTP fields (if Contact Result = PTP)
  P2p_Amount: "1000000",            // Digits only, no formatting!
  P2p_Date: "2024-11-10",           // ISO format YYYY-MM-DD!
  
  // Notes (preserve newlines with \n)
  Visit_Notes: "Client berjanji bayar\ntanggal 10 November",
  
  // Optional fields
  New_Phone_Number: "+62812321561", // With +62 prefix, no separator!
  
  // Auto-filled
  Visit_by_Skor_Team: "Yes",        // String, not boolean!
  Visit_Agent: "John Doe",
  Visit_Agent_Team_Lead: "Jakarta Team"
};

// Images sent as multipart with field names: image1, image2, image3
const formData = new FormData();
formData.append('body', JSON.stringify(apiPayload));
formData.append('image1', File1, File1.name);
formData.append('image2', File2, File2.name);
formData.append('image3', File3, File3.name);
```

---

### ✅ **Validation Checklist Before Submit**

```javascript
function validateBeforeSubmit(data) {
  const errors = [];
  
  // 1. Location format (Visit only)
  if (data.Channel === "Visit") {
    if (!data.Visit_Lat_Long.match(/^-?\d+\.\d+,-?\d+\.\d+$/)) {
      errors.push("❌ Location format invalid. Must be: latitude,longitude (NO SPACE)");
    }
  }
  
  // 2. PTP Amount (if PTP selected)
  if (data.Contact_Result === "Promise to Pay (PTP)") {
    if (!data.P2p_Amount || data.P2p_Amount.match(/\D/)) {
      errors.push("❌ PTP Amount must be digits only (no Rp, no separator)");
    }
  }
  
  // 3. PTP Date format (if PTP selected)
  if (data.Contact_Result === "Promise to Pay (PTP)") {
    if (!data.P2p_Date.match(/^\d{4}-\d{2}-\d{2}$/)) {
      errors.push("❌ PTP Date must be YYYY-MM-DD format");
    }
  }
  
  // 4. Phone number format (if provided)
  if (data.New_Phone_Number && !data.New_Phone_Number.match(/^\+62\d{9,13}$/)) {
    errors.push("❌ Phone number must be +62XXXXXXXXX (no separator)");
  }
  
  // 5. Visit by Skor Team (must be string)
  if (typeof data.Visit_by_Skor_Team !== 'string') {
    errors.push("❌ Visit_by_Skor_Team must be string 'Yes' or 'No', not boolean");
  }
  
  // 6. Dropdown values (case-sensitive check)
  const dropdownFields = ['Person_Contacted', 'Action_Location', 'Contact_Result'];
  dropdownFields.forEach(field => {
    if (data[field] && data[field] !== data[field].trim()) {
      errors.push(`❌ ${field} has extra whitespace`);
    }
  });
  
  return {
    isValid: errors.length === 0,
    errors: errors
  };
}
```

---

### 🚨 **Common Mistakes to Avoid**

| ❌ Wrong | ✅ Correct | Field |
|---------|-----------|-------|
| `"-6.2088, 106.8456"` (space) | `"-6.2088,106.8456"` | Location |
| `"Rp 1.000.000"` | `"1000000"` | PTP Amount |
| `"07 Nov 2024"` | `"2024-11-07"` | PTP Date |
| `"812321561"` | `"+62812321561"` | Phone Number |
| `"+62 812-321-561"` (separator) | `"+62812321561"` | Phone Number |
| `true` (boolean) | `"Yes"` (string) | Visit by Skor Team |
| `false` (boolean) | `"No"` (string) | Visit by Skor Team |
| `"debtor"` (lowercase) | `"Debtor"` (exact) | Dropdown values |
| `"PTP"` (shortened) | `"Promise to Pay (PTP)"` (exact) | Dropdown values |
| `Visit_Image_1` (field name) | `image1` (field name) | Image upload field |

---

## ⚠️ Important Validation Rules

### Frontend Validation (Before Submit)

1. **Person Contacted:** REQUIRED untuk semua channel
2. **Action Location:** REQUIRED untuk semua channel
3. **Contact Result:** REQUIRED untuk semua channel
4. **Notes:** REQUIRED untuk semua channel (tidak boleh kosong)
5. **Images:**
   - Visit: Minimal 1 image, maksimal 3 images
   - Message: Minimal 1 image, maksimal 3 images
   - Call: No images
6. **PTP Fields** (jika Contact Result = PTP):
   - PTP Amount: REQUIRED (harus diisi)
   - PTP Date: REQUIRED (harus dipilih)
7. **Location** (untuk Visit):
   - Harus tersedia (GPS coordinates)
   - User bisa refresh jika belum akurat

---

### Data Processing Rules

1. **PTP Amount:**
   - Input: User bisa ketik "1000000" atau "1.000.000" atau "Rp 1.000.000"
   - Display: Auto-format sebagai "Rp 1.000.000"
   - Submit ke API: Extract digits only → "1000000"

2. **PTP Date:**
   - Display: Format Indonesia "07 Nov 2024"
   - Submit ke API: Format ISO "2024-11-07"
   - Validation:
     - Minimum: Today
     - Maximum: Today + 5 days
     - Blocked: Sundays

3. **New Phone Number:**
   - Input: User ketik digits only
   - Display: Prefix "+62 " + digits
   - Submit ke API: "+62" + digits
   - Example: Input "8123456789" → Display "+62 8123456789" → API "+628123456789"

4. **Location (Visit only):**
   - Format: "latitude,longitude" (separated by comma)
   - Example: "-6.2088,106.8456"

---

## 🎨 UI/UX Guidelines

### Form Layout
1. Sections dipisah dengan Card (elevation/shadow)
2. Required fields ditandai dengan asterisk (*) atau validator message
3. Dropdown menggunakan searchable dropdown (jika banyak opsi)
4. Date picker menggunakan calendar widget
5. Image upload dengan preview thumbnail

### Channel Switching
- User bisa switch channel sewaktu-waktu
- **WARNING:** Jika switch channel, form akan di-reset:
  - Action Location direset (karena opsi berbeda)
  - Contact Result direset (karena opsi berbeda)
  - PTP fields dihapus (jika ada)
  - Images dihapus jika switch dari Visit/Message ke Call

### Auto-fill Behavior
1. **Date & Time:** Auto-filled saat form dibuka (Jakarta timezone)
2. **Location (Visit):** Auto-filled dari GPS saat form dibuka
3. **Visit by Skor Team:** Auto-set berdasarkan user's team
   - Team = "Skorcard" → "Yes"
   - Team lainnya → "No"
4. **Visit Agent:** Auto-filled dari user's name
5. **Visit Agent Team Lead:** Auto-filled dari user's team

### Loading States
1. **Submit Button:** Show loading spinner saat submit
2. **Location Refresh:** Show loading message saat refresh GPS
3. **Image Upload:** Show loading saat upload dari camera/gallery

---

## 🔄 Form Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Form Opens                                               │
│    - Auto-fill Date & Time (Jakarta timezone)              │
│    - Auto-fill Location (if Visit channel)                 │
│    - Auto-set Visit by Skor Team (based on user team)      │
│    - Auto-fill Agent & Team Lead (from user data)          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. User Selects Channel                                     │
│    - Visit / Call / Message                                 │
│    - Form fields adjust based on channel                    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. User Fills Required Fields                               │
│    - Person Contacted (dropdown)                            │
│    - Action Location (dropdown - options vary by channel)   │
│    - Images (if Visit/Message - min 1, max 3)              │
│    - Contact Result (dropdown - options vary by channel)    │
│    - Notes (text area - required)                           │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Conditional: If Contact Result = PTP                     │
│    - PTP Amount (text input with Rupiah formatting)         │
│    - PTP Date (date picker with rules)                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. User Fills Optional Fields                               │
│    - New Phone Number                                       │
│    - New Address                                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. User Clicks Submit                                        │
│    - Validate all required fields                           │
│    - Build payload (JSON)                                   │
│    - If has images: FormData (multipart)                    │
│    - If no images: JSON                                     │
│    - POST to API                                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. Success                                                   │
│    - Show success message                                   │
│    - Navigate back to client details                        │
│    - Trigger refresh in client details                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 📱 Responsive Design Notes

### Mobile (< 768px)
- Single column layout
- Full-width buttons
- Image preview in horizontal scroll
- Dropdown with native mobile picker

### Tablet (768px - 1024px)
- 2-column layout untuk some sections
- Larger touch targets

### Desktop (> 1024px)
- Max-width container (800px)
- Centered layout
- Larger form controls

---

## 🧪 Testing Checklist

### Functional Testing
- [ ] Channel switching works (Visit ↔ Call ↔ Message)
- [ ] Form reset when switching channel
- [ ] Person Contacted dropdown shows all 16 options
- [ ] Action Location dropdown changes based on channel
- [ ] Contact Result dropdown changes based on channel
- [ ] PTP fields appear/disappear based on Contact Result
- [ ] Image upload works (camera & gallery)
- [ ] Image delete works
- [ ] Maximum 3 images enforced
- [ ] Location refresh works (Visit only)
- [ ] Date picker enforces rules (min, max, no Sunday)
- [ ] Currency formatting works (PTP Amount)
- [ ] Phone number formatting works (New Phone Number)
- [ ] Form validation works (all required fields)
- [ ] Submit with images (multipart) works
- [ ] Submit without images (JSON) works
- [ ] Success redirect works
- [ ] Error handling works

### Data Validation Testing
- [ ] Empty required fields show error
- [ ] PTP Amount accepts only numbers
- [ ] PTP Date blocks invalid dates
- [ ] Phone number accepts only digits
- [ ] Image count validation (min 1 for Visit/Message)
- [ ] Location validation (Visit only)

### API Integration Testing
- [ ] Correct payload structure for Visit
- [ ] Correct payload structure for Call
- [ ] Correct payload structure for Message
- [ ] Multipart upload works with images
- [ ] JSON upload works without images
- [ ] API error handling works
- [ ] Network error handling works

---

## 📚 Reference

### Related Files
- **Form Screen:** `lib/screens/contactability_form_screen.dart`
- **Model:** `lib/core/models/contactability.dart`
- **Controller:** `lib/core/controllers/contactability_controller.dart`
- **API Service:** `lib/core/services/api_service.dart`

### API Documentation
- **Endpoint:** `/webhook/95709b0d-0d03-4710-85d5-d72f14359ee4`
- **Method:** POST
- **Base URL Production:** `https://n8n.skorcard.app`
- **Base URL Staging:** `https://n8n-sit.skorcard.app`

---

**Document Version:** 1.0  
**Last Updated:** November 7, 2024  
**Author:** Technical Documentation Team
