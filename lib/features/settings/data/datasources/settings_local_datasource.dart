import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences_model.dart';
import 'dart:convert';

abstract class SettingsLocalDataSource {
  Future<UserPreferencesModel> getPreferences(String userId);
  Future<void> savePreferences(UserPreferencesModel preferences);
  Future<void> clear();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences sharedPreferences;

  SettingsLocalDataSourceImpl({required this.sharedPreferences});

  static const String _preferencesKey = 'USER_PREFERENCES_';

  @override
  Future<UserPreferencesModel> getPreferences(String userId) async {
    final jsonString = sharedPreferences.getString(_preferencesKey + userId);
    
    if (jsonString == null) {
      // Return default preferences
      return UserPreferencesModel(userId: userId);
    }

    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserPreferencesModel.fromJson(jsonMap);
  }

  @override
  Future<void> savePreferences(UserPreferencesModel preferences) async {
    final jsonString = jsonEncode(preferences.toJson());
    await sharedPreferences.setString(
      _preferencesKey + preferences.userId,
      jsonString,
    );
  }

  @override
  Future<void> clear() async {
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(_preferencesKey)) {
        await sharedPreferences.remove(key);
      }
    }
  }
}
