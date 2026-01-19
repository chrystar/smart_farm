# Smart Farm - Authentication Implementation Guide

## Overview

The authentication system has been successfully implemented with Supabase as the backend. The system supports both registration and login with secure token management and persistent session storage.

## Architecture

### Clean Architecture Pattern
The authentication module follows Clean Architecture principles with three layers:

```
Domain (Business Logic)
├── entities/
│   └── user.dart
├── repositories/
│   └── auth_repository.dart
└── usecases/
    ├── register_usecase.dart
    └── login_usecase.dart

Data (Data Sources & Repositories)
├── datasources/
│   └── auth_remote_datasource.dart (Supabase integration)
├── models/
│   └── user_model.dart
└── repositories/
    └── auth_repository_impl.dart

Presentation (UI & State Management)
├── provider/
│   └── auth_provider.dart (Provider pattern)
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── getstarted.dart
└── widgets/
    ├── auth_button.dart
    └── textform.dart
```

## Key Components

### 1. Supabase Service (`core/services/supabase_service.dart`)
- Singleton pattern for Supabase client initialization
- Provides authentication methods: `signUp()`, `signIn()`, `signOut()`
- Database operations: `createUserProfile()`, `getUserProfile()`, `updateUserProfile()`
- Session management

### 2. Auth Remote Data Source
- Handles all Supabase API calls
- Converts auth responses to domain models
- Implements error handling

### 3. Auth Repository Implementation
- Implements the abstract repository
- Wraps data source calls with error handling using `Either<Failure, T>` (Dartz)
- Returns failures or entities

### 4. Auth Provider (State Management)
- Manages authentication state globally
- Provides methods: `login()`, `register()`, `logout()`, `initializeAuth()`
- Persists auth data to secure storage
- Notifies listeners on state changes

### 5. Auth Injection (Dependency Injection)
- Provides all auth dependencies to the widget tree
- Ensures single instances of repositories and use cases

## Features Implemented

### ✅ User Registration
- Input validation (name, phone, password)
- Secure password storage via Supabase Auth
- User profile creation in database
- Error handling and user feedback

### ✅ User Login
- Email-based authentication
- Session token management
- Automatic profile loading
- Remember me functionality via secure storage

### ✅ Session Management
- Automatic token storage in secure storage
- Session restoration on app restart
- Logout functionality with data clearing

### ✅ State Management
- Provider pattern for reactive UI updates
- Loading states during auth operations
- Error message display

### ✅ Security
- Secure token storage via `flutter_secure_storage`
- HTTPS communication with Supabase
- RLS (Row Level Security) policies on database

## File Structure

```
lib/
├── core/
│   ├── config/
│   │   ├── api_config.dart
│   │   └── supabase_config.dart (NEW)
│   └── services/
│       ├── storage_service.dart
│       └── supabase_service.dart (NEW)
├── features/
│   └── authentication/
│       ├── data/
│       │   ├── datasourse/
│       │   │   └── auth_remote_datasource.dart (UPDATED - Supabase)
│       │   ├── models/
│       │   │   └── user_model.dart
│       │   └── repository/
│       │       └── auth_repository_impl.dart (UPDATED)
│       ├── domain/
│       │   ├── entities/
│       │   │   └── user.dart
│       │   ├── repositories/
│       │   │   └── auth_repository.dart (UPDATED)
│       │   └── usecases/
│       │       ├── register_usecase.dart
│       │       └── login_usecase.dart (NEW)
│       ├── di/
│       │   └── auth_injection.dart (UPDATED)
│       └── presentation/
│           ├── provider/
│           │   └── auth_provider.dart (UPDATED)
│           ├── screens/
│           │   ├── login_screen.dart (UPDATED)
│           │   ├── register_screen.dart (UPDATED)
│           │   └── getstarted.dart
│           └── widgets/
│               ├── auth_button.dart
│               └── textform.dart
├── main.dart (UPDATED - Supabase initialization)
└── pubspec.yaml (UPDATED - Dependencies added)
```

## Dependencies Added

```yaml
supabase_flutter: ^1.10.0  # Supabase SDK
dotenv: ^4.1.0             # Environment variables
```

## Setup Instructions

### 1. Update Configuration
Edit `lib/core/config/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String usersTable = 'profiles';
}
```

### 2. Create Database Tables
Run this SQL in Supabase:
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
```

### 3. Get Dependencies
```bash
flutter pub get
```

### 4. Run the App
```bash
flutter run
```

## User Flows

### Registration Flow
```
GetStarted Screen
    ↓
Register Tab (Sign Up)
    ↓ [User enters: name, phone, password, confirm password]
AuthProvider.register()
    ↓
AuthRemoteDataSource.register()
    ↓
SupabaseService.signUp()
    ↓ [Creates auth user]
SupabaseService.createUserProfile()
    ↓ [Creates profile in database]
StorageService.saveToken()
    ↓ [Stores token securely]
HomeScreen
```

### Login Flow
```
GetStarted Screen
    ↓
Login Tab
    ↓ [User enters: email, password]
AuthProvider.login()
    ↓
AuthRemoteDataSource.login()
    ↓
SupabaseService.signIn()
    ↓ [Authenticates user]
SupabaseService.getUserProfile()
    ↓ [Fetches user profile]
StorageService.saveToken()
    ↓ [Stores token securely]
HomeScreen
```

### App Launch Flow
```
main() - Initialize Supabase
    ↓
SplashScreen (2 seconds)
    ↓
OnboardingScreen (if first time)
    ↓
GetStarted/Login
    ↓ OR
HomeScreen (if authenticated)
```

## Testing Scenarios

### ✅ Test Registration
1. Open app
2. Navigate to Sign Up
3. Enter valid data
4. Verify user in Supabase dashboard

### ✅ Test Login
1. Use registered credentials
2. Verify token is stored
3. Check user data in provider

### ✅ Test Session Persistence
1. Login
2. Close app
3. Reopen - should show HomeScreen (no login needed)

### ✅ Test Logout
1. Login
2. Navigate to profile/settings
3. Tap logout
4. Should return to GetStarted

### ✅ Test Error Handling
1. Try registration with invalid data
2. Try login with wrong credentials
3. Verify error messages display

## Important Implementation Details

### Token Management
- Tokens are stored in `flutter_secure_storage`
- Automatically retrieved on app startup via `initializeAuth()`
- Cleared on logout

### Error Handling
- All network errors are caught and displayed to users
- Failures use `dartz` Either type for type-safe error handling
- Validation errors are displayed inline on forms

### State Management
- `AuthProvider` uses `ChangeNotifier` pattern
- All state changes trigger listener notifications
- UI rebuilds reactively

### Security Best Practices
- Passwords are never stored locally
- Only tokens are stored (in secure storage)
- All HTTPS communication with Supabase
- Database RLS policies enforce user data isolation

## Troubleshooting

### Build Errors
If you get build errors:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Check `supabase_config.dart` has correct values

### Authentication Failures
1. Verify Supabase URL and keys
2. Check database table exists and has correct schema
3. Review browser console for CORS issues

### Token Expiration
- Supabase automatically handles token refresh
- App will prompt re-login if session expires

## Next Steps

1. **Implement Forgot Password**: Use Supabase password reset
2. **Add OAuth**: Configure Google/Apple sign-in
3. **Add Phone Authentication**: Use Supabase OTP
4. **Implement User Profile**: Add profile update screen
5. **Add Two-Factor Authentication**: Enhance security

## References

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Provider Documentation](https://pub.dev/packages/provider)
- [Clean Architecture Pattern](https://resocoder.com/flutter-clean-architecture)
- [Dartz Either Pattern](https://pub.dev/packages/dartz)

---

**Last Updated**: 16 January 2026
**Status**: ✅ Complete - Ready for Testing
