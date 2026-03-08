# ⚠️ CRITICAL: You Haven't Applied the Migration Yet!

## The Error You're Seeing

```
An unexpected error occurred. Please try again.
```

This error is appearing because **the `profiles` table doesn't exist** in your Supabase database.

## Why It's Happening

1. ✓ Code has been updated to use `profiles` table
2. ✗ **Migration SQL hasn't been run in Supabase** ← THIS IS THE ISSUE
3. Result: Code tries to insert into non-existent table → Error

## What You MUST Do RIGHT NOW

### Step 1: Open Supabase Dashboard
Go to: **https://app.supabase.com**

### Step 2: Select Your Project
Click on your Smart Farm project

### Step 3: Go to SQL Editor
- Left sidebar → **SQL Editor**
- Click **+ New Query**

### Step 4: Copy the Migration SQL
1. Open this file in VS Code:
   ```
   supabase/migrations/2026-02-28_create_user_profiles.sql
   ```
   
2. Select all text:
   ```
   Cmd+A
   ```

3. Copy:
   ```
   Cmd+C
   ```

### Step 5: Paste into Supabase
- In the Supabase SQL Editor
- Paste:
   ```
   Cmd+V
   ```

### Step 6: Run the Migration
- Click the **Run** button (or press Cmd+Enter)
- Wait for the message: **"Success. No rows returned"** ✓

### Step 7: Restart the App
```bash
# In your terminal where Flutter is running
Ctrl+C

# Then run again
flutter run
```

### Step 8: Try Registration Again
- Tap **Register**
- Enter: Name, Email (NEW), Password
- Should work now! ✅

---

## Visual Instructions

```
1. Go to: supabase.com/app
           ↓
2. Select your project
           ↓
3. Click: SQL Editor (left sidebar)
           ↓
4. Click: + New Query
           ↓
5. Open file: supabase/migrations/2026-02-28_create_user_profiles.sql
           ↓
6. Copy all text (Cmd+A, Cmd+C)
           ↓
7. Paste in Supabase (Cmd+V)
           ↓
8. Click: Run button
           ↓
9. Wait for: "Success. No rows returned"
           ↓
10. Restart Flutter app
           ↓
11. Try registration again
           ↓
✅ WORKS!
```

---

## The Migration File

The file you need to run is:
```
/Users/ram/Development/projects/smart_farm/supabase/migrations/2026-02-28_create_user_profiles.sql
```

It contains:
- ✅ CREATE TABLE profiles
- ✅ Indexes for performance
- ✅ Row Level Security (RLS) policies
- ✅ Automatic timestamp updates

**File size**: 66 lines of SQL  
**Time to apply**: 30 seconds

---

## What This Migration Does

Creates a `profiles` table with:
```
id          UUID (unique user ID)
name        TEXT (user's name)
email       TEXT (email address - must be unique)
role        TEXT (farmer/vet/admin)
avatar_url  TEXT (for future profile pictures)
created_at  TIMESTAMP (when created)
updated_at  TIMESTAMP (auto-updated)
```

Plus:
- Security policies so users can only see their own profile
- Indexes for fast email lookups
- Automatic timestamp management

---

## Why This is Important

Without this table:
- ❌ Registration fails
- ❌ Users can't create accounts
- ❌ App can't store user profiles

With this table:
- ✅ Registration works
- ✅ Users can create accounts
- ✅ User data is persisted
- ✅ App is ready for all features

---

## After It Works

Once registration is successful:
1. Test logging in with the account you created
2. Try creating a batch
3. Test other features
4. Continue with subscription system

---

## Need Help?

If you get stuck:
1. Check that you're in the **correct Supabase project**
2. Check that you clicked **SQL Editor** (not something else)
3. Check that you clicked **Run** (not just pasted the SQL)
4. Wait for "Success. No rows returned" message
5. Restart the Flutter app

---

## Don't Skip This!

This is NOT optional. The app **requires** the `profiles` table to exist in your database.

Trying to register without applying the migration = Error every time

Applying the migration + restarting app = Registration works!

---

**TLDR**: 
1. Open Supabase
2. SQL Editor → New Query
3. Copy-paste the SQL from: `supabase/migrations/2026-02-28_create_user_profiles.sql`
4. Click Run
5. Restart Flutter app
6. Try registering again
7. It will work! ✅
