# Registration Error Troubleshooting Guide

## Problem
When trying to register, you see the error: "An unexpected error occurred. Please try again."

## What Was Wrong
The registration process was failing when trying to insert data into optional tables (`user_roles` and `farmers`) after the user account was created. Since these errors weren't handled gracefully, the entire registration failed with a generic error message.

## What Was Fixed

### 1. Improved Error Handling (auth_remote_datasource.dart)
- Made the `user_roles` and `farmers` table inserts optional
- These inserts now fail gracefully without affecting registration
- Added detailed console logging to help debug if there are issues

### 2. Better Error Messages (error_message_helper.dart)
- Added specific messages for:
  - Duplicate email (already registered)
  - Invalid email format
  - Weak password
- These help users understand what went wrong

### 3. Registration Logging (auth_provider.dart)
- Added console logging for registration success/failure
- This helps debug any remaining issues
- Check the Debug Console when registration fails

## How to Test

### Test Case 1: Valid Registration
1. **Input:**
   - Name: "John Doe"
   - Email: "john@example.com"
   - Password: "password123"
   - Confirm: "password123"

2. **Expected:** ✅ Registration succeeds, navigates to home screen

### Test Case 2: Email Already Used
1. **Input:**
   - Use an email that was already registered
   
2. **Expected:** ❌ Error message: "This email is already registered. Please use a different email or login."

### Test Case 3: Weak Password
1. **Input:**
   - Password less than 6 characters

2. **Expected:** ❌ Error message: "Password is too weak..."

### Test Case 4: Invalid Email
1. **Input:**
   - Email without @ symbol

2. **Expected:** ❌ Error message in form validation

## Debug Information

If you're still having issues, check the Debug Console for messages like:

### Success Messages
```
Registration successful for user: John Doe
user_roles entry created successfully
farmers entry created successfully
```

### Expected Warnings
```
Warning: Could not create user_roles entry: ...
Warning: Could not create farmers entry: ...
```
These are normal - it just means those optional tables don't exist yet or have different constraints.

### Error Messages
```
Registration error (after sign up): Exception: ...
Registration failed: ...
```
These indicate actual errors that need investigation.

## Common Causes & Solutions

### "Email already registered"
**Cause:** You're using an email that's already in the system  
**Solution:** Use a different email address

### "Password too weak"
**Cause:** Password is less than 6 characters  
**Solution:** Use a password with at least 6 characters

### "Invalid email format"
**Cause:** Email doesn't have @ symbol  
**Solution:** Enter a valid email like: user@example.com

### "Connection timed out"
**Cause:** No internet connection or Supabase is unreachable  
**Solution:** Check your internet connection and try again

### "A database error occurred"
**Cause:** Supabase database is having issues  
**Solution:** Wait a moment and try again

## If Still Not Working

### Step 1: Check Internet Connection
```
Make sure you have a stable internet connection
```

### Step 2: Check Supabase Status
- Go to your Supabase project dashboard
- Check if the service is online
- Verify auth is enabled

### Step 3: Check Log Console
- In VS Code, open Debug Console
- Look for "Registration error" or "Registration successful"
- Copy the exact error message

### Step 4: Verify Database Tables
The registration now works even if these tables don't exist:
- ✅ `profiles` (or the usersTable configured) - REQUIRED
- ⚠️  `user_roles` - OPTIONAL (creates entry but doesn't fail if missing)
- ⚠️  `farmers` - OPTIONAL (creates entry but doesn't fail if missing)

### Step 5: Reset and Retry
1. Clear your app cache
2. Close and reopen the app
3. Try registration again

## What Information to Provide if Getting Help

If you're still having issues, provide:
1. The exact error message shown in the app
2. The console error message from Debug Console
3. Your email address (without password)
4. Steps you took before the error
5. Whether login works (if you registered before)

## Technical Details

### Registration Flow
```
User Input
    ↓
Form Validation (client-side)
    ↓
Supabase Auth SignUp
    ↓ (if success)
Create User Profile in Database
    ↓ (if success)
Try to Create user_roles Entry (optional, doesn't fail if missing)
    ↓ (if success)
Try to Create farmers Entry (optional, doesn't fail if missing)
    ↓ (if any of above succeeds)
Save Token Locally
    ↓
Navigate to Home Screen
```

### Error Handling
- Auth errors are caught and converted to user-friendly messages
- Database errors are logged to console
- Optional table inserts won't fail the whole registration
- All errors flow through ErrorMessageHelper for consistent messaging

## Files Modified

1. **auth_remote_datasource.dart** - Made table inserts optional
2. **error_message_helper.dart** - Added specific error messages  
3. **auth_provider.dart** - Added logging for debugging

These changes ensure registration is more robust and errors are properly communicated to the user.
