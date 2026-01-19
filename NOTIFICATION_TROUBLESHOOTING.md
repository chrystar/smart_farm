# Notification Troubleshooting Guide

## Issue
Feeding reminders and daily report reminders are not showing up.

## Possible Causes & Solutions

### 1. **Notification Permissions Not Granted**
**Check:**
- Go to device Settings → Apps → Smart Farm → Notifications
- Ensure notifications are enabled

**Fix:**
The app should request permissions on first launch, but you may need to manually enable them in device settings.

### 2. **Exact Alarm Permission (Android 12+)**
**For Android 12 and above**, exact alarms require special permission:

**Add to `android/app/src/main/AndroidManifest.xml`:**
```xml
<manifest>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application>
        <!-- ... existing code ... -->
    </application>
</manifest>
```

### 3. **Test Notifications**
Add a test button to verify notifications work:

In `settings_screen.dart`, add this test button:
```dart
ElevatedButton(
  onPressed: () async {
    final notificationService = NotificationService();
    await notificationService.showTestNotification();
  },
  child: const Text('Test Notification'),
),
```

### 4. **Check Notification Logs**
When you set a reminder, check the console/logs for:
- `✅ Notification service initialized successfully`
- `📅 Scheduling feeding notification...`
- `✅ Feeding notification scheduled successfully`

If you see errors, they will help identify the problem.

### 5. **Timezone Issues**
The code uses `tz.setLocalLocation(tz.getLocation('UTC'))` which might not match your device timezone.

**Better approach:**
```dart
// In notification_service.dart, replace UTC with your local timezone:
tz.setLocalLocation(tz.getLocation('Africa/Nairobi')); // or your timezone
```

### 6. **iOS Specific**
For iOS, ensure `ios/Runner/Info.plist` has:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### 7. **Verify Scheduled Notifications**
Add this method to NotificationService:
```dart
Future<void> getPendingNotifications() async {
  final pending = await _notifications.pendingNotificationRequests();
  debugPrint('📋 Pending notifications: ${pending.length}');
  for (var notification in pending) {
    debugPrint('  - ID: ${notification.id}, Title: ${notification.title}');
  }
}
```

Call it after scheduling to confirm notifications are queued.

## Quick Fix Steps

1. **Check AndroidManifest.xml** - Add permissions above
2. **Restart the app** completely (kill and relaunch)
3. **Check device settings** - Enable notifications manually
4. **Add test button** to verify basic notification functionality
5. **Check console logs** for error messages

## Testing
1. Set a feeding reminder for 1 minute from now
2. Lock your phone
3. Wait for notification
4. If it doesn't appear, check logs and permissions

## Common Error Messages
- `⚠️ Notification service not initialized` → Call initialize() first
- `❌ Error requesting permissions` → Manually enable in device settings
- `Notification permissions granted: false` → User denied or permission not requested properly
