# Activities Not Showing - Troubleshooting Guide

## Problem
Activities are being saved to Firebase successfully, but they're not showing up in the Activities page of the app, even though the data exists in the Firebase console.

## Root Cause
**Missing Firestore Security Rules for Activities Collection**

The Firebase Firestore database is missing security rules for the `activities` collection. Without explicit rules, Firestore denies all access to the collection by default.

## Solution

### Step 1: Update Firestore Security Rules

1. Go to your Firebase Console: https://console.firebase.google.com/
2. Select your project
3. Navigate to "Firestore Database" → "Rules"
4. Add the following rules to your Firestore rules (insert before the final default deny rule):

```javascript
// Activities - users can manage their own activities
match /activities/{activityId} {
  allow read, write if request.auth != null && 
    (resource == null || resource.data.userId == request.auth.uid);
  allow create if request.auth != null && request.auth.uid == request.resource.data.userId;
}

// Event Leaderboards - users can read, system can write based on activities
match /eventLeaderboards/{leaderboardId} {
  allow read if request.auth != null;
  allow write if request.auth != null && 
    (resource == null || resource.data.userId == request.auth.uid);
}
```

### Step 2: Verify Data Structure

Make sure your activities in Firebase have the correct structure:
- `userId` field matches the authenticated user's UID
- `createdAt` field exists for proper ordering
- All required fields are present

### Step 3: Test the Fix

1. After updating the Firestore rules, restart your app
2. Try logging in and navigating to the Activities page
3. Check the Flutter console for debug output showing:
   - Current user ID
   - Number of activities loaded
   - Any error messages

### Step 4: Debug Tools Added

The app now includes enhanced debugging:

1. **Debug Button**: A blue bug icon in the Activities page that will:
   - Show current user ID
   - Force reload activities
   - Display count of activities found
   - Show first 3 activities in console

2. **Console Logging**: Enhanced logs showing:
   - Activities page initialization
   - Firebase loading process
   - Activity counts and user IDs

## Verification Steps

1. **Check Firebase Console**:
   - Go to Firestore Database
   - Look for `activities` collection
   - Verify your activities have `userId` field matching your account

2. **Check App Logs**:
   - Look for console output when opening Activities page
   - Should see user ID and activity count
   - Any error messages about permissions

3. **Test Creating New Activity**:
   - Record a new workout
   - Check if it appears immediately in Activities page
   - Verify it's saved to Firebase with correct user ID

## Expected Debug Output

When working correctly, you should see in the Flutter console:
```
🚀 ActivitiesPage initState
👤 Current user on init: [your-user-id]
🔄 ActivitiesPage: Starting to load Firebase activities...
👤 Current user ID: [your-user-id]
🔄 Loading user activities from Firebase...
✅ Loaded [number] user activities
🏗️ ActivitiesPage building...
📱 isLoading: false
📊 firebaseActivities count: [number]
👤 Current user ID: [your-user-id]
```

## Common Issues

1. **Firestore Rules Not Applied**: Wait a few minutes after updating rules
2. **Wrong User ID**: Check if the activities' `userId` field matches your current user
3. **Authentication Issue**: Ensure you're properly logged in
4. **Network/Permissions**: Check device internet connection and Firebase permissions

## Files Modified

- `lib/activities_page.dart`: Added debug logging and tools
- `firestore_rules_final.txt`: Added activities collection rules (needs to be deployed to Firebase)

The main fix is updating the Firestore security rules in the Firebase Console.
