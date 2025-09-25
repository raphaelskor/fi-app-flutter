# Photo Loading Debug Guide

## Issue
KTP and Selfie photos are showing "No photo available" even though:
- API works correctly in Postman
- Skor User ID values exist and are not null

## Debugging Changes Made

### 1. Enhanced Photo Service Logging (`photo_service.dart`)
Added comprehensive logging to track:
- API request details (URL, body, headers)
- Response status and size
- ZIP extraction process
- File identification and saving

### 2. Enhanced Client Model Debugging (`client.dart`)
Added detailed logging to the `skorUserId` getter to:
- Show all available keys in rawApiData
- Display values for different ID field variations
- Track which field is ultimately used

### 3. Enhanced Client Details Screen Debugging (`client_details_screen.dart`)
Added:
- Detailed logging in initState() to show raw API data
- Enhanced logging in `_loadUserPhotos()` method
- Test button to manually test photo API with custom user_id

## How to Debug

### Step 1: Check Console Logs
1. Run the app and navigate to a client details screen
2. Look for these log patterns:

```
🔍 Getting skorUserId from rawApiData...
🔍 Available keys in rawApiData: [list of keys]
🔍 user_ID field: [value]
🔍 User_ID field: [value]
🔍 Skor_User_ID field: [value]
✅ Using [field_name]: [value]
```

### Step 2: Test Photo API Manually
1. In the client details screen, click the "🧪 Test Photo API" button
2. Enter the user_id that works in your Postman test
3. Check console for API call logs:

```
🔍 PhotoService: Fetching photos for userId: [user_id]
🔍 PhotoService: Request body: {"user_id":"[user_id]"}
🔍 PhotoService: Response status: 200
🔍 PhotoService: Response body length: [bytes] bytes
🔍 PhotoService: ZIP decoded successfully. Files count: [count]
```

### Step 3: Verify ZIP Content
Look for logs showing archive file names:
```
🔍 PhotoService: Archive file: [filename] ([size] bytes)
🔍 PhotoService: Processing file: [filename]
🔍 PhotoService: Identified as KTP photo / Selfie photo
```

## Common Issues and Solutions

### Issue 1: skorUserId is null or empty
**Solution**: Check the client raw API data structure. The field name might be different.

### Issue 2: API returns 200 but empty response
**Solution**: Verify the user_id parameter matches the one that works in Postman.

### Issue 3: ZIP contains files but they're not identified as KTP/Selfie
**Solution**: Check file naming convention in ZIP. Files should contain "ktp" or "selfie" in filename.

### Issue 4: Files are identified but not displayed
**Solution**: Check file path and permissions issues.

## Testing Checklist

- [ ] Console shows skorUserId is extracted correctly
- [ ] API request is made with correct user_id
- [ ] API returns 200 status
- [ ] ZIP is decoded successfully
- [ ] Files in ZIP are identified as KTP/Selfie
- [ ] Files are saved to local storage
- [ ] UI updates to show photos

## API Endpoint
```
POST https://n8n.skorcard.app/webhook/c8e14ad2-d9fa-4a0d-be07-3787ff81a463
Content-Type: application/json

{
  "user_id": "YOUR_USER_ID_HERE"
}
```

## Next Steps
1. Run the app and check console logs
2. Test with the manual test button using your working Postman user_id
3. Compare the logs to identify where the process fails
4. Update the code based on findings

## Remove Debug Code
After fixing the issue, remove:
- Extra console.log statements (replace with debugPrint if needed)
- The test button from client_details_screen.dart
- This debug README file