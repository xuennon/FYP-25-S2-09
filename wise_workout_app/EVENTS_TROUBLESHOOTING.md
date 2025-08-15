# Events Not Showing - Troubleshooting Guide

## Issue: Events created by business users not appearing on the mobile app

### Updates Made:
1. ✅ **Added Real-time Listening**: Events now update automatically when business users create them
2. ✅ **Enhanced Event Model**: Updated to support new data structure with sports array and metrics
3. ✅ **Added Debug Tools**: Added debug button and automatic debugging when no events found
4. ✅ **Improved Error Handling**: Better error messages and diagnostics

### Steps to Test:

#### 1. Check Console Output
When you open the Events tab, look for these console messages:
```
🔄 Starting real-time events listener...
🔄 Event page: Starting to load events...
🔍 Querying events collection...
📄 Found X documents in events collection
```

#### 2. Use Debug Button
- Go to Events tab
- Tap the bug icon (🐛) next to the refresh button
- Check console for debug output

#### 3. Manual Testing
```dart
// In your events service, call:
await _eventsService.debugEventsCollection();
```

### Expected Event Data Structure:
```json
{
  "name": "Event Name",
  "description": "Event description",
  "createdBy": "business_user_uid",
  "businessId": "business_user_uid", 
  "businessName": "Business Name",
  "sports": ["hike"],
  "startDate": "2025-08-07",
  "endDate": "2025-08-15",
  "participants": [],
  "createdAt": "2025-07-31T09:43:05.303Z",
  "metrics": {
    "elevation": 0
  }
}
```

### Common Issues & Solutions:

#### 1. **Firebase Rules**
Make sure Firestore rules allow reading events:
```javascript
match /events/{eventId} {
  allow read if true; // Public read access
}
```

#### 2. **Collection Name Mismatch**
- Business users should write to: `events` collection
- Mobile app reads from: `events` collection

#### 3. **Authentication Issues**
- Check if user is logged in: `FirebaseAuth.instance.currentUser != null`
- Check Firebase console for authentication errors

#### 4. **Data Format Issues**
- Events must have required fields: `name`, `startDate`, `endDate`
- Dates can be either ISO strings or Timestamps
- Sports field can be array or single sportType

#### 5. **Network/Connection Issues**
- Check internet connection
- Check Firebase project configuration
- Check if emulator can access internet

### Testing Checklist:

- [ ] App connects to Firebase successfully
- [ ] User is authenticated
- [ ] Events collection exists in Firestore
- [ ] Events have correct data structure
- [ ] Firebase rules allow reading events
- [ ] Real-time listener is active
- [ ] Console shows debug information

### Debug Commands:
```dart
// Check if service is working
print('Events service initialized: ${_eventsService != null}');

// Check current user
print('Current user: ${FirebaseAuth.instance.currentUser?.uid}');

// Manual debug
await _eventsService.debugEventsCollection();

// Check listener status
print('Real-time listener active: ${_eventsService._eventsSubscription != null}');
```

If events still don't appear after these checks, the issue is likely:
1. Business users writing to wrong collection
2. Data format mismatch
3. Firebase configuration issue
4. Network connectivity problem
