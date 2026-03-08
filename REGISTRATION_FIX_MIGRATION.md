# Registration Fix - Setup Required

## Problem Identified

The registration was failing because the application was trying to create user profiles in a `profiles` table that **doesn't exist** in the Supabase database.

## What Was Wrong

1. **Missing profiles table**: The code calls `createUserProfile()` which tries to insert into a `profiles` table
2. **No table schema**: The table needs to exist with proper columns (id, name, email, role, etc.)
3. **No RLS policies**: Security policies weren't defined for the profiles table

## What I Fixed

1. ✅ **Cleaned up registration code**: Removed references to non-existent `user_roles` and `farmers` tables
2. ✅ **Created migration file**: `supabase/migrations/2026-02-28_create_user_profiles.sql`
3. ✅ **Added detailed logging**: So you can see exactly where the process succeeds/fails

## What You Need to Do

### Step 1: Apply the Migration to Supabase

1. Go to your Supabase dashboard: https://app.supabase.com
2. Select your project (pajbygbwbjabxiiwqrxm)
3. Go to **SQL Editor** (left sidebar)
4. Click **New Query**
5. Copy and paste the entire contents of this file:
   ```
   supabase/migrations/2026-02-28_create_user_profiles.sql
   ```
6. Click **Run** (or Cmd+Enter)
7. You should see: "Success. No rows returned"

### Step 2: Test Registration

1. Stop the app if it's running
2. Run `flutter pub get` to ensure all dependencies are updated
3. Run the app: `flutter run`
4. Try registering with a new email address
5. Watch the Debug Console for messages like:
   - `Starting registration for email: ...`
   - `Step 1: Creating Supabase Auth user...`
   - `✓ Auth user created successfully with ID: ...`
   - `Step 2: Creating user profile in profiles table...`
   - `✓ User profile created successfully in profiles table`
   - `Registration completed successfully for: ...`

### Step 3: Verify Success

Once registration works:
- ✅ You should be logged in automatically
- ✅ Your dashboard should load
- ✅ You can create batches
- ✅ You can access all features

## If It Still Fails

If you still see errors, check the Debug Console for messages starting with `❌`:
- `❌ Registration error: [error details]`

Send me the exact error message and I can investigate further.

## Tables Created

The migration creates:

### profiles table
```sql
id              UUID (primary key, references auth.users)
name            TEXT
email           TEXT (unique)
role            TEXT (default: 'farmer')
avatar_url      TEXT (for future profile pictures)
created_at      TIMESTAMPTZ
updated_at      TIMESTAMPTZ
```

### Security Features
- ✅ Row Level Security (RLS) enabled
- ✅ Users can only see their own profile
- ✅ Users can insert/update their own profile during signup
- ✅ Automatic timestamp updates
- ✅ Admin users can view all profiles

## Next Steps After Registration Works

Once registration is working:
1. Test the login flow
2. Test the farmer/vet role detection
3. Implement creator vs farmer dashboard logic
4. Begin RevenueCat subscription integration

---

**Questions?** Check the console logs first - they contain the exact error details needed for debugging.
