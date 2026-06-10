import '../models/chat_model.dart';
import '../services/api_client.dart';

class ChatRepository {
  Future<ChatResponse> sendQuery(String question) async {
    try {
      final requestBody = ChatRequest(
        userId: 1, // Hardcoded as per design or pass dynamically
        question: question,
      );

      final response = await ApiClient.instance.post(
        '/query/',
        data: requestBody.toJson(),
      );

      if (response.statusCode == 200) {
        return ChatResponse.fromJson(response.data);
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }
}