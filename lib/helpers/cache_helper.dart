import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static Future<void> set(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final wrapped = {
      "timestamp": DateTime.now().toIso8601String(),
      "data": data,
    };
    prefs.setString(key, jsonEncode(wrapped));
  }

  static Future<Map<String, dynamic>?> get(String key, {int? maxAgeMinutes}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    final decoded = jsonDecode(jsonString);
    final timestamp = DateTime.parse(decoded['timestamp']);
    if (maxAgeMinutes != null) {
      final diff = DateTime.now().difference(timestamp).inMinutes;
      if (diff > maxAgeMinutes) {
        prefs.remove(key);
        return null; // Cache expired
      }
    }
    return decoded['data'];
  }
}
