class ChatRequest {
  final int userId;
  final String question;

  ChatRequest({required this.userId, required this.question});

  Map<String, dynamic> toJson() {
    return {
      "user_id": userId,
      "question": question,
    };
  }
}

class ChatResponse {
  final String answer;
  final List<String> intent;
  final List<HistoryItem> history;

  ChatResponse({
    required this.answer,
    required this.intent,
    required this.history,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      answer: json['answer'] ?? '',
      intent: List<String>.from(json['intent'] ?? []),
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => HistoryItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class HistoryItem {
  final String role; // "user" or "assistant"
  final String content;

  HistoryItem({required this.role, required this.content});

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      role: json['role'] ?? 'unknown',
      content: json['content'] ?? '',
    );
  }
}

// UI Friendly Model
class ChatMessage {
  final String text;
  final bool isUser;
  
  ChatMessage({required this.text, required this.isUser});
}