class ApiConfig {
  // For Android Emulator, use 10.0.2.2 instead of localhost
  // For iOS Simulator, use localhost
  // For physical device testing, use your computer's IP address
  static const String baseUrl = 'http://192.168.43.123:3000/api';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
}