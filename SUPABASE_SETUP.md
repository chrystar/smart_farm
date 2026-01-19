# Supabase Configuration Guide

## Setting Up Supabase

### 1. Create a Supabase Project
- Go to [https://supabase.com](https://supabase.com)
- Sign up or log in
- Create a new project
- Wait for the project to initialize

### 2. Get Your Credentials
After your project is created, navigate to:
- **Settings** → **API** to find:
  - `SUPABASE_URL` - Your Supabase project URL
  - `SUPABASE_ANON_KEY` - Your anonymous public key

### 3. Update Configuration
Update the file: `lib/core/config/supabase_config.dart`

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  // ... rest of config
}
```

### 4. Set Up Database Tables

#### Create `profiles` table:
```sql
-- Create profiles table
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can read their own profile" ON profiles
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);
```

### 5. Configure Authentication

In Supabase Dashboard:
- Go to **Authentication** → **Providers**
- Enable **Email** provider
- Configure email confirmation settings
- (Optional) Enable OAuth providers (Google, Apple)

### 6. Initialize Supabase in Your App

The initialization happens in `main.dart`. The app now:
1. Initializes Supabase on startup
2. Shows a splash screen
3. Checks authentication status
4. Routes to appropriate screen

## Authentication Flow

### Registration Flow
1. User enters: Name, Phone Number, Password
2. App calls `signUp()` with email (using phone as email)
3. Supabase creates auth user
4. App creates profile in `profiles` table
5. Session token is stored in secure storage
6. User is navigated to Home screen

### Login Flow
1. User enters: Email, Password
2. App calls `signIn()` with credentials
3. Supabase authenticates and returns session
4. App fetches user profile from database
5. Token and user data stored in secure storage
6. User is navigated to Home screen

### Logout Flow
1. User taps logout
2. App calls `signOut()`
3. Local storage is cleared
4. User is navigated to GetStarted screen

## Important Notes

- **Email vs Phone**: Currently, the system uses email for authentication. Adjust as needed for phone-based auth.
- **Secure Storage**: Tokens are stored using `flutter_secure_storage`
- **Provider Pattern**: Auth state is managed using Provider package
- **Error Handling**: All auth operations include comprehensive error handling

## Testing

### Test Registration
1. Open app
2. Skip onboarding (optional)
3. Go to Sign Up tab
4. Enter test data
5. Check Supabase dashboard for created user

### Test Login
1. Use credentials from registration
2. Verify user is logged in
3. Check local storage for token

## Troubleshooting

- **CORS errors**: Check Supabase project settings → API → CORS configuration
- **Authentication fails**: Verify credentials in `supabase_config.dart`
- **User profile not found**: Ensure `profiles` table is created with correct schema
- **Token expires**: App automatically handles session refresh via Supabase
