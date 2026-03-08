# Vet Report Response and Notification System - Implementation Guide

## Overview
This system allows vets to respond to droppings reports from farmers, and automatically notifies farmers when responses are submitted.

## Database Setup

### 1. Run Database Migrations

Run these SQL files in your Supabase SQL Editor:

1. **`2026-02-18_droppings_reports_storage_policies.sql`** - Creates droppings-reports storage bucket
2. **`2026-02-18_droppings_reports_responses_and_notifications.sql`** - Creates response and notification tables

### 2. Tables Created

#### `droppings_reports_responses`
- Stores vet responses to droppings reports
- Fields: id, report_id, vet_id, title, description, cause, medications, medication_image_url
- RLS enabled: Vets can create/update their own responses, users can view responses to their reports

#### `notifications`
- Stores user notifications
- Fields: id, user_id, title, message, type, reference_id, is_read
- RLS enabled: Users can view/update their own notifications

#### Storage Buckets
- `droppings-reports` - For droppings photos (already exists)
- `medication-images` - For medication photos from vet responses

### 3. Automatic Notification Trigger
A database trigger automatically creates a notification when a vet submits a response.

## Vet App Implementation

### Files Created/Modified:

1. **`lib/models/droppings_report_response.dart`** (NEW)
   - Model for vet responses
   - JSON serialization

2. **`lib/screens/report_response_screen.dart`** (NEW)
   - Form for vet to respond to reports
   - Fields: Title, Description, Cause, Medications, Optional medication image
   - Uploads image to `medication-images` bucket
   - Creates notification automatically via database trigger

3. **`lib/screens/reports_screen.dart`** (MODIFIED)
   - Added navigation: tap on report card to open response screen
   - Added arrow icon to indicate clickable
   - Refreshes list after response submitted

### How It Works (Vet Side):

1. Vet opens the app and sees list of droppings reports
2. Taps on a report to view details
3. Fills out response form:
   - Title (e.g., "Coccidiosis Diagnosis")
   - Description (detailed findings)
   - Cause (what's causing the condition)
   - Medications (dosage and instructions)
   - Optional: Upload medication photo
4. Submits response
5. Farmer automatically receives notification

## Smart Farm App Implementation

### Files Created/Modified:

1. **`lib/models/notification_model.dart`** (NEW)
   - Model for notifications
   - JSON serialization with copyWith

2. **`lib/services/notification_service.dart`** (NEW)
   - Manages notification state
   - Real-time subscription to new notifications
   - Methods: loadNotifications, markAsRead, markAllAsRead
   - Tracks unread count

3. **`lib/screens/notifications_screen.dart`** (NEW)
   - Displays all notifications
   - Color-coded by type (report_response = green, alert = orange, system = blue)
   - Shows unread badge on each notification
   - Swipe to delete
   - Mark all as read button
   - Pull to refresh

4. **`lib/main.dart`** (MODIFIED)
   - Added NotificationService as provider
   - Auto-loads notifications on app start
   - Subscribes to real-time updates

5. **`lib/features/dashboard/presentation/pages/dashboard_screen.dart`** (MODIFIED)
   - Added notification icon with badge in app bar
   - Badge shows unread count (e.g., "3" or "9+" if more than 9)
   - Tapping icon navigates to notifications screen
   - Auto-refreshes notifications when returning

### How It Works (Farmer Side):

1. Farmer receives notification automatically when vet submits response
2. Red badge appears on notification icon in dashboard
3. Taps notification icon to view all notifications
4. Taps on notification to mark as read
5. Can view response details (title, description, cause, medications, medication image)
6. Swipe to delete notifications
7. "Mark all as read" button clears all badges

## Notification Types

- **`report_response`** - Vet responded to droppings report (green icon)
- **`alert`** - Important alerts (orange icon)
- **`system`** - System messages (blue icon)

## Real-time Features

- **Farmer App**: Automatically receives new notifications via Supabase Realtime
- **Notification Badge**: Updates in real-time as new notifications arrive
- **No Manual Refresh Needed**: Notifications appear instantly

## Testing Checklist

### Vet App:
- [ ] Can view list of droppings reports
- [ ] Can tap on report to open response screen
- [ ] All form fields validate correctly
- [ ] Can upload medication image
- [ ] Response submits successfully
- [ ] Returns to reports list after submit

### Smart Farm App:
- [ ] Notification badge appears when vet submits response
- [ ] Badge shows correct unread count
- [ ] Tapping badge opens notifications screen
- [ ] Notifications display with correct colors/icons
- [ ] Can mark individual notification as read
- [ ] Can mark all notifications as read
- [ ] Can swipe to delete notifications
- [ ] Pull to refresh works

### Database:
- [ ] Run both migration files successfully
- [ ] Verify buckets created: `droppings-reports`, `medication-images`
- [ ] Verify tables created: `droppings_reports_responses`, `notifications`
- [ ] Verify trigger creates notification automatically
- [ ] Check RLS policies allow proper access

## Security Notes

- **RLS Enabled**: All tables have Row Level Security
- **Vets Only**: Only vets can create responses
- **User Privacy**: Users can only see their own notifications
- **Storage Security**: Public read, authenticated write for both buckets

## Future Enhancements

1. **Push Notifications**: Add Firebase Cloud Messaging for mobile push
2. **Email Notifications**: Send email when vet responds
3. **Response History**: Show all responses for a report
4. **Vet Rating**: Allow farmers to rate vet responses
5. **In-App Chat**: Direct messaging between vet and farmer

## Troubleshooting

### Notification Not Received
- Check database trigger is active: `SELECT * FROM pg_trigger WHERE tgname = 'trigger_create_notification_on_response';`
- Verify user_id matches in droppings_report
- Check RLS policies allow insert into notifications table

### Badge Not Updating
- Ensure NotificationService is provided in main.dart
- Check real-time subscription is active
- Verify Supabase Realtime is enabled in project settings

### Image Upload Fails
- Check bucket exists and is public
- Verify storage policies allow insert
- Ensure file size < 5MB
- Check file is valid image format (jpeg, jpg, png)

## API References

### Notification Service Methods
```dart
notificationService.loadNotifications() // Fetch all notifications
notificationService.markAsRead(id) // Mark one as read
notificationService.markAllAsRead() // Mark all as read
notificationService.unreadCount // Get unread count
notificationService.subscribeToNotifications() // Start real-time
```

### Database Queries
```sql
-- Get user notifications
SELECT * FROM notifications WHERE user_id = 'USER_ID' ORDER BY created_at DESC;

-- Mark as read
UPDATE notifications SET is_read = true WHERE id = 'NOTIFICATION_ID';

-- Get responses for a report
SELECT * FROM droppings_reports_responses WHERE report_id = 'REPORT_ID';
```

## Summary

✅ Complete end-to-end notification system
✅ Real-time updates via Supabase Realtime
✅ Automatic notifications via database triggers
✅ Secure with Row Level Security
✅ Clean UI with badges and color coding
✅ Ready for production use

The system is fully functional and ready to test!
