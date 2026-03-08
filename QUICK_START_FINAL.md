# Quick Start Guide - Smart Farm & Vet App

## Prerequisites

1. **Flutter SDK**: Version 3.x or higher
2. **Dart SDK**: Included with Flutter
3. **Supabase Account**: Free tier sufficient (supabase.com)
4. **Device/Emulator**: Android or iOS for testing

---

## Step 1: Get Supabase Credentials

1. Go to [supabase.com](https://supabase.com)
2. Create a new project or use existing one
3. Go to **Settings → API**
4. Copy:
   - **Project URL** (e.g., `https://your-project.supabase.co`)
   - **Anon Key** (public, safe for frontend)

---

## Step 2: Create Storage Bucket

1. In Supabase Dashboard, go to **Storage**
2. Create new bucket:
   - Name: `droppings-reports`
   - Make Public: **Yes**
3. Click **Create**

---

## Step 3: Run Migrations

1. In Supabase Dashboard, go to **SQL Editor**
2. Copy & paste each migration (in order):
   - `supabase/migrations/2026-02-28_create_user_profiles.sql` ⭐ **IMPORTANT: Run this first**
   - `supabase/migrations/2026-02-17_add_duration_days.sql`
   - `supabase/migrations/2026-02-18_create_droppings_reports.sql`
   - `supabase/migrations/2026-02-18_add_vet_access.sql`
3. Run each one (wait for "Success. No rows returned" before moving to next)

---

## Step 4: Seed Vet Users (for Vet App Testing)

In **SQL Editor**, for each vet email:
```sql
INSERT INTO vet_users (user_id)
SELECT id FROM auth.users WHERE email = 'vet-email@example.com';
```

Or create a test vet user first in **Authentication → Users**.

---

## Step 5: Run Smart Farm App

```bash
cd /Users/ram/Development/projects/smart_farm

flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

**What to test**:
- [ ] Login/signup works
- [ ] Create a batch
- [ ] Create an expense
- [ ] Create a vaccine schedule
- [ ] Disable internet → create data → enable internet → sync works
- [ ] Droppings report: Take photo, submit, see in database

---

## Step 6: Run Vet App

```bash
cd /Users/ram/Development/projects/smart_farm/vet_app

flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

**What to test**:
- [ ] Login with vet email (from step 4)
- [ ] See list of all droppings reports
- [ ] Pull to refresh
- [ ] Images load correctly
- [ ] Timestamps display in correct format
- [ ] Sign out works

---

## Step 7: Run Tests

```bash
# Main app tests
cd /Users/ram/Development/projects/smart_farm
flutter test

# Vet app tests
cd /Users/ram/Development/projects/smart_farm/vet_app
flutter test
```

**Expected**: All tests pass ✅

---

## Environment Variables Reference

### Main Smart Farm App

```bash
# REQUIRED
--dart-define=SUPABASE_URL=https://your-project.supabase.co
--dart-define=SUPABASE_ANON_KEY=your-anon-key

# OPTIONAL
--dart-define=SENTRY_DSN=https://key@sentry.io/project  # Error logging
```

### Vet App

```bash
# REQUIRED
--dart-define=SUPABASE_URL=https://your-project.supabase.co
--dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## Directory Structure

```
smart_farm/
├── lib/                          # Main app source
│   ├── main.dart
│   ├── core/                     # Shared services
│   │   ├── config/supabase_config.dart
│   │   ├── services/
│   │   │   ├── supabase_service.dart
│   │   │   └── offline_sync_service.dart
│   │   └── routing/
│   ├── features/                 # Feature modules
│   │   ├── authentication/
│   │   ├── batch/
│   │   ├── sales/
│   │   ├── expenses/
│   │   ├── vaccination/         # Droppings reports here
│   │   └── settings/
│   └── ...
├── test/                         # Unit tests
├── integration_test/             # Integration tests
├── supabase/migrations/          # Database migrations
├── vet_app/                      # Separate vet app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── services/supabase_service.dart
│   │   ├── models/droppings_report.dart
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       └── reports_screen.dart
│   └── test/
└── pubspec.yaml
```

---

## Key Features

### Smart Farm App ✅
- **Batch Management**: Create, track, and manage bird batches
- **Vaccination Schedules**: Automatic alarms for vaccine due dates
- **Sales Tracking**: Record sales with payment status
- **Expense Tracking**: Log farm expenses with grouping
- **Droppings Reports**: Photo submission for vet analysis
- **Offline Support**: Full sync when connectivity restored
- **Secure Auth**: Supabase authentication with session persistence
- **Data Export**: Export all user data as JSON
- **Account Deletion**: Request account deletion via email

### Vet App ✅
- **Secure Login**: Email/password authentication
- **View All Reports**: See droppings reports from all farmers
- **Image Gallery**: Display droppings photos with metadata
- **Timestamps**: Locale-aware date/time formatting
- **Refresh Support**: Pull-to-refresh to fetch latest reports
- **RLS Protection**: Database-level access control

---

## Troubleshooting

### App Crashes on Startup
**Cause**: Missing Supabase credentials  
**Fix**: Verify `--dart-define` arguments are correct and match your Supabase project

### "Cannot connect to server" Error
**Cause**: Network issues or invalid Supabase URL  
**Fix**: Check internet connection and confirm Supabase URL is correct

### Droppings Images Don't Load
**Cause**: Storage bucket not created or image upload failed  
**Fix**: Create `droppings-reports` bucket in Supabase Storage

### Vet App Shows Empty Reports List
**Cause**: No vet user seeded or no reports in database  
**Fix**: Run Step 4 (seed vet users) and Step 5 (create reports in main app)

### Tests Fail
**Cause**: Stale Flutter cache  
**Fix**: Run `flutter clean && flutter pub get && flutter test`

---

## Build for Production

### Android APK
```bash
cd /Users/ram/Development/projects/smart_farm
flutter build apk \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play)
```bash
flutter build appbundle \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ipa \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
# Output: build/ios/ipa/
```

---

## Monitoring & Support

### Error Logging (Sentry)
If `SENTRY_DSN` provided, all errors are logged to Sentry dashboard  
Access at: https://sentry.io/organizations/your-org/projects/

### Database Monitoring (Supabase)
- **SQL Editor**: View tables and run queries
- **Logs**: Monitor auth, storage, API requests
- **Statistics**: Track usage and performance

### Testing
Run tests before deploying:
```bash
# Unit tests
flutter test

# Coverage report
flutter test --coverage
# View: coverage/lcov.info
```

---

## Support Contacts

- **Flutter Issues**: https://github.com/flutter/flutter/issues
- **Supabase Support**: https://supabase.com/docs
- **Dart Documentation**: https://dart.dev/guides
- **This Project**: See README.md and related guides

---

**Last Updated**: 2026-02-18  
**Status**: Ready to Deploy  
**All Tests**: Passing ✅
