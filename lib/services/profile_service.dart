import 'dart:io';
import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'auth_service.dart';

class ProfileService {
  static const String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'requiresLogin': true,
        };
      }

      // if (token == null) {
      //   return {'success': false, 'message': 'Authentication token not found'};
      // }

      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/api/auth/profile/'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          imageFile.path,
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Profile image updated successfully'};
      } else {
        return {
          'success': false,
          'message': 'Failed to update profile image: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error uploading profile image: $e'
      };
    }
  }
} 