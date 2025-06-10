class ApiConfig {
  static const bool _isDevelopment =
      true; // Change this based on your environment

  // Development URLs
  static const String _devBaseUrl = 'http://192.168.43.81:8000/api';
  static const String _devWebSocketUrl = 'ws://192.168.43.81:8000/ws';

  // Production URLs
  static const String _prodBaseUrl = 'https://your-production-url.com/api';
  static const String _prodWebSocketUrl = 'wss://your-production-url.com/ws';

  // Get the appropriate base URL based on environment
  static String get baseUrl => _isDevelopment ? _devBaseUrl : _prodBaseUrl;
  static String get webSocketUrl =>
      _isDevelopment ? _devWebSocketUrl : _prodWebSocketUrl;

  // API Endpoints
  static String get authToken => '$baseUrl/auth/token/';
  static String get authRefresh => '$baseUrl/auth/token/refresh/';
  static String get authVerify => '$baseUrl/auth/token/verify/';
  static String get authLogout => '$baseUrl/auth/logout/';

  // Add other endpoints as needed
  static String get products => '$baseUrl/products/';
  static String get categories => '$baseUrl/categories/';
  static String get subscriptionPlans => '$baseUrl/subscription-plans/';

  // Add other API-related configuration constants here
  static const int requestTimeout = 30; // seconds
  static const String apiVersion = 'v1';
}
