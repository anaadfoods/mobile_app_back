import 'chat_session.dart';
import 'chat_message.dart';

/// Domain entity representing a full session detail including metadata
/// and complete conversation history.
class ChatSessionDetail {
  /// Session metadata.
  final ChatSession session;

  /// Full conversation history for this session.
  final List<ChatMessageEntity> messages;

  const ChatSessionDetail({required this.session, required this.messages});
}
