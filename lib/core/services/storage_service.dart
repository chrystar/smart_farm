import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Save auth token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get auth token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Delete auth token
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Save user data
  Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userKey, value: userData);
  }

  // Get user data
  Future<String?> getUserData() async {
    return await _storage.read(key: _userKey);
  }

  // Delete user data
  Future<void> deleteUserData() async {
    await _storage.delete(key: _userKey);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}