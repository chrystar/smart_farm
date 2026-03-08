# 🔧 Quick Fix - Phone Number Field Issue

## The Problem
Your `profiles` table has a `phone_number` field that's **required (NOT NULL)**, but we weren't sending it during registration.

**Error**: `null value in column "phone_number" of relation "profiles" violates not-null constraint`

## The Solution (2 steps)

### Step 1: Apply the Fix Migration
Go to Supabase and run this file:
```
supabase/migrations/2026-02-28_fix_profiles_table.sql
```

**Steps**:
1. Go to: **https://app.supabase.com**
2. Click **SQL Editor** → **+ New Query**
3. Open: `supabase/migrations/2026-02-28_fix_profiles_table.sql`
4. Copy all text (Cmd+A → Cmd+C)
5. Paste in Supabase (Cmd+V)
6. Click **Run**
7. Wait for: **"Success"** ✓

### Step 2: Restart & Test
```bash
Ctrl+C        # Stop Flutter
flutter run   # Start again
```

Try registration again - should work now! ✅

---

## What This Migration Does
- ✅ Makes `phone_number` optional (not required)
- ✅ Ensures email field works correctly
- ✅ Adds proper indexes for performance
- ✅ Updates RLS policies
- ✅ Sets up automatic timestamp updates

---

## Expected Result
When you try to register now:
```
✅ Auth user created successfully
✅ User profile created successfully
✅ REGISTRATION SUCCESSFUL!
```

Then auto-login and dashboard loads. 🎉

---

**That's it!** One SQL file, click Run, restart app, done!
