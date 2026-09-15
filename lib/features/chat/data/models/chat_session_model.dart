import '../../domain/entities/chat_session.dart';

/// Data model for chat session, mapping to/from backend JSON.
///
/// Matches the backend `SessionMeta` Pydantic schema:
/// ```json
/// {"session_id": "...", "user_id": "...", "title": "...",
///  "created_at": "...", "updated_at": "...", "message_count": 0}
/// ```
class ChatSessionModel {
  final String sessionId;
  final String userId;
  final String title;
  final String createdAt;
  final String updatedAt;
  final int messageCount;

  const ChatSessionModel({
    required this.sessionId,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      sessionId: json['session_id'] as String? ?? '',
      userId: (json['user_id'] ?? '').toString(),
      title: json['title'] as String? ?? 'New Conversation',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      messageCount: json['message_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'title': title,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'message_count': messageCount,
    };
  }

  /// Convert to domain entity.
  ChatSession toEntity() {
    return ChatSession(
      sessionId: sessionId,
      userId: userId,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messageCount: messageCount,
    );
  }
}
