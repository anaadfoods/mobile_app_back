import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_model.dart';

class ChatRepository {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS
  static const String _baseUrl = 'http://10.0.2.2:8000/query/'; 

  Future<ChatResponse> sendQuery(String question) async {
    try {
      final requestBody = ChatRequest(
        userId: 1, // Hardcoded as per your screenshot, or pass dynamically
        question: question,
      );

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatResponse.fromJson(data);
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }
}