# Testing Team Invite Deep Links

## How to Test the Deep Link System

### 1. Build and Install the App
```bash
flutter build apk --debug
flutter install
```

### 2. Generate Team Links
1. Open the app and navigate to any team details page
2. Click the "Share" button
3. Choose either:
   - **App Link (Direct)**: `wiseworkout://team/{token}` - Opens directly in app
   - **Web Link (Universal)**: `https://wiseworkout.com/team/{token}` - Works everywhere

### 3. Test Deep Links

#### Method 1: ADB Command (Android)
```bash
# Test custom scheme link
adb shell am start -W -a android.intent.action.VIEW -d "wiseworkout://team/1723464000000abc123" com.example.wise_workout_app

# Test web link  
adb shell am start -W -a android.intent.action.VIEW -d "https://wiseworkout.com/team/1723464000000abc123" com.example.wise_workout_app
```

#### Method 2: Share via Messaging Apps
1. Copy the generated team link
2. Paste it into any messaging app (WhatsApp, Telegram, SMS, etc.)
3. The link should appear as clickable
4. Tap the link - it should open the app directly

#### Method 3: Browser Test
1. Copy the web link (`https://wiseworkout.com/team/{token}`)
2. Paste it into Chrome or any mobile browser
3. The browser should ask "Open in Wise Workout app?"
4. Choose "Yes" to open the app directly

### 4. Expected Behavior

#### When Link is Clicked:
1. **If User is Logged In:**
   - App opens directly to team details page
   - Join dialog appears if not already a member
   - User can join the team immediately

2. **If User is Not Logged In:**
   - App opens to login page
   - After successful login, automatically navigates to team details
   - Join dialog appears

#### Link Types Generated:

1. **App Link (wiseworkout://team/TOKEN)**
   - ✅ Opens directly in app
   - ✅ Works on devices with app installed
   - ❌ Doesn't work if app not installed

2. **Web Link (https://wiseworkout.com/team/TOKEN)**
   - ✅ Works on all devices
   - ✅ Clickable in all messaging platforms
   - ✅ Can redirect to app if installed
   - ✅ Can show web fallback if app not installed

### 5. Link Format Examples

```
App Link:  wiseworkout://team/1723464000000abc123
Web Link:  https://wiseworkout.com/team/1723464000000abc123

Share Message Format:
🏃‍♂️ Join my team "Fitness Warriors" on Wise Workout!
💪 Let's crush our fitness goals together!
Click the link below to join:
https://wiseworkout.com/team/1723464000000abc123
#WiseWorkout #FitnessTeam #WorkoutTogether
```

### 6. Troubleshooting

#### Links Not Clickable?
- Make sure you're using the Web Link format (`https://`) for maximum compatibility
- Some messaging platforms may not recognize custom schemes (`wiseworkout://`)
- Try copying the complete formatted share message

#### App Not Opening?
- Verify the app is installed on the target device
- Check that the Android manifest has the correct intent filters
- Test with ADB commands first to verify configuration

#### Join Dialog Not Appearing?
- Make sure the team link hasn't expired (30 days)
- Verify the user isn't already a member of the team
- Check Firebase console for `team_links` collection data

### 7. Share Message Tips

For maximum clickability:
1. Always use `https://` links in messaging platforms
2. Include engaging text around the link
3. Use the formatted share message provided by the app
4. Test on different platforms (WhatsApp, Telegram, SMS, Email)

### 8. Platform Compatibility

#### Android:
- ✅ Custom schemes work via intent filters
- ✅ HTTPS links work via Android App Links
- ✅ All messaging apps support clickable links

#### iOS (Future):
- 📋 Requires URL scheme registration in Info.plist
- 📋 Requires Universal Links configuration
- 📋 Requires Associated Domains setup

### 9. Security Features

- ✅ Links expire after 30 days
- ✅ Click tracking and analytics
- ✅ Firebase security rules protection
- ✅ User authentication required
- ✅ Team member limits enforced
