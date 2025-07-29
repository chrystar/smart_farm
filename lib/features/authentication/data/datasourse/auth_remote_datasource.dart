import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_farm/core/config/api_config.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> register({
    required String name,
    required String phoneNumber,
    required String password,
  });

  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({
    required this.client,
  });

  @override
  Future<UserModel> register({
    required String name,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'phoneNumber': phoneNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data['data']['user']);
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          'password': password,
        }),
      );

      final Map<String, dynamic> data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Failed to login: ${e.toString()}');
    }
  }
} 