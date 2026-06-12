import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static Future<void> set(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wrapped = {
        "timestamp": DateTime.now().toIso8601String(),
        "data": data,
      };
      await prefs.setString(key, jsonEncode(wrapped));
    } catch (_) {
      // Gracefully ignore storage write failures
    }
  }

  static Future<dynamic> get(String key, {int? maxAgeMinutes}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;

      final decoded = jsonDecode(jsonString);
      final timestamp = DateTime.parse(decoded['timestamp']);
      if (maxAgeMinutes != null) {
        final diff = DateTime.now().difference(timestamp).inMinutes;
        if (diff > maxAgeMinutes) {
          await prefs.remove(key);
          return null; // Cache expired
        }
      }
      return decoded['data'];
    } catch (_) {
      return null; // Gracefully degrade on read or parsing errors
    }
  }

  static Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}
