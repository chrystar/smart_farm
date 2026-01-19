import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _hasOnboardedKey = 'has_onboarded';

  Future<bool> getHasOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasOnboardedKey) ?? false;
  }

  Future<void> setHasOnboarded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasOnboardedKey, value);
  }
}
