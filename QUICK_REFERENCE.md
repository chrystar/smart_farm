# Quick Reference: Smart Farm Authentication

## 🚀 Quick Start

### 1. Configure Supabase
Edit `lib/core/config/supabase_config.dart`:
```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your_anon_key_here';
```

### 2. Create Database Table
Execute in Supabase SQL Editor:
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User access" ON profiles FOR ALL USING (auth.uid() = id);
```

### 3. Get Dependencies
```bash
flutter pub get
```

## 📁 File Organization

| File | Purpose |
|------|---------|
| `supabase_service.dart` | Supabase client wrapper |
| `auth_remote_datasource.dart` | API calls to Supabase |
| `auth_repository_impl.dart` | Data access layer |
| `auth_provider.dart` | State management |
| `login_screen.dart` | Login UI |
| `register_screen.dart` | Registration UI |
| `auth_injection.dart` | Dependency injection |

## 🔐 Authentication Methods

### Register
```dart
await authProvider.register(
  name: 'John Doe',
  phoneNumber: '+1234567890',
  password: 'password123',
);
```

### Login
```dart
await authProvider.login(
  email: 'john@example.com',
  password: 'password123',
);
```

### Logout
```dart
await authProvider.logout();
```

### Check Auth Status
```dart
bool isAuthenticated = authProvider.isAuthenticated;
User? user = authProvider.user;
String? token = authProvider.token;
```

## 🎯 UI Components

### Login Screen
- Email input
- Password input (toggle visibility)
- Social login buttons (Apple, Google)
- Error display
- Loading indicator

### Register Screen
- Full name input
- Phone number input
- Password input (toggle visibility)
- Confirm password input
- Validation feedback
- Loading state

## 📊 State Management

### AuthProvider Properties
```dart
bool isLoading           // Loading state
String? error            // Error message
User? user              // Current user
String? token           // Session token
bool isAuthenticated    // User logged in?
```

### AuthProvider Methods
```dart
Future<bool> register({...})    // Register new user
Future<bool> login({...})       // Login user
Future<void> logout()           // Logout user
Future<void> initializeAuth()   // Restore session
```

## 🔄 Navigation Flow

```
App Start
  ↓
Supabase Init
  ↓
Splash Screen (2s)
  ↓
Onboarding (if needed)
  ↓
GetStarted (Login/Register)
  ↓ (Success)
Home Screen
```

## ⚠️ Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| CORS error | Check Supabase API settings |
| Auth fails | Verify credentials in config |
| User not found | Ensure `profiles` table exists |
| Token invalid | Clear cache & reinstall app |
| Build errors | Run `flutter clean && flutter pub get` |

## 🧪 Testing Checklist

- [ ] Registration with valid data works
- [ ] Registration validation catches invalid input
- [ ] Login with correct credentials works
- [ ] Login rejects incorrect credentials
- [ ] Session persists after app restart
- [ ] Logout clears all data
- [ ] Error messages display properly
- [ ] Loading indicators show during auth

## 📚 Key Concepts

### Clean Architecture
- Separate domain, data, and presentation layers
- Use cases encapsulate business logic
- Repositories abstract data sources

### Provider Pattern
- Global state management
- Reactive UI updates
- Easy access via `context.read<AuthProvider>()`

### Error Handling
- `Either<Failure, Success>` pattern (Dartz)
- User-friendly error messages
- Validation on both client and server

### Secure Storage
- Tokens in `flutter_secure_storage`
- Automatic session restoration
- Automatic cleanup on logout

## 🔗 Links

- [Supabase Setup Guide](./SUPABASE_SETUP.md)
- [Full Documentation](./AUTHENTICATION_GUIDE.md)
- [Supabase Docs](https://supabase.com/docs)

---

**Version**: 1.0
**Last Updated**: 16 January 2026
