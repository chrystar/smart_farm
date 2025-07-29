import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:smart_farm/core/services/storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/register_usecase.dart';

class AuthProvider extends ChangeNotifier {
  final RegisterUseCase _registerUseCase;
  final StorageService _storageService;

  AuthProvider(this._registerUseCase) : _storageService = StorageService();

  bool _isLoading = false;
  String? _error;
  User? _user;
  String? _token;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  // Initialize auth state from storage
  Future<void> initializeAuth() async {
    _token = await _storageService.getToken();
    final userData = await _storageService.getUserData();
    if (userData != null) {
      final Map<String, dynamic> userMap = json.decode(userData);
      _user = User.fromJson(userMap);
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String phoneNumber,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _registerUseCase(
      name: name,
      phoneNumber: phoneNumber,
      password: password,
    );

    bool success = false;
    result.fold(
      (failure) {
        _error = failure.message;
        _user = null;
        success = false;
      },
      (user) async {
        _user = user;
        // Store user data
        await _storageService.saveUserData(json.encode(user.toJson()));
        // Store token if available in the registration response
        if (user.token != null) {
          _token = user.token;
          await _storageService.saveToken(user.token!);
        }
        _error = null;
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    // Clear user data and token from storage
    await _storageService.clearAll();
    
    // Clear in-memory data
    _user = null;
    _token = null;
    _error = null;
    
    notifyListeners();
  }

  // Set token and user data (used after login)
  Future<void> setAuthData({required String token, required User user}) async {
    _token = token;
    _user = user;
    
    // Store in secure storage
    await _storageService.saveToken(token);
    await _storageService.saveUserData(json.encode(user.toJson()));
    
    notifyListeners();
  }
} 