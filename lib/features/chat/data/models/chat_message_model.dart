import '../../domain/entities/chat_message.dart';

/// Data model for a chat message, mapping to/from backend JSON.
///
/// Backend JSON: `{"role": "user"|"assistant"|"system", "content": "...", "ui_action": {...}}`
class ChatMessageModel {
  final String role;
  final String content;
  final Map<String, dynamic>? uiAction;

  const ChatMessageModel({
    required this.role,
    required this.content,
    this.uiAction,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      uiAction: json['ui_action'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      if (uiAction != null) 'ui_action': uiAction,
    };
  }

  /// Convert to domain entity.
  ChatMessageEntity toEntity() {
    return ChatMessageEntity(
      role: _parseRole(role),
      content: content,
      uiAction: uiAction,
    );
  }

  static ChatRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'user':
        return ChatRole.user;
      case 'assistant':
        return ChatRole.assistant;
      case 'system':
        return ChatRole.system;
      default:
        return ChatRole.user;
    }
  }
}
