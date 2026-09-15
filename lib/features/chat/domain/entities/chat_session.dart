/// Chat session entity representing a single conversation.
///
/// Maps to the backend `SessionMeta` schema from the AI Service.
class ChatSession {
  /// Unique session identifier.
  final String sessionId;

  /// Owner user ID.
  final String userId;

  /// Conversation title (auto-generated from first message or user-set).
  final String title;

  /// ISO timestamp of session creation.
  final String createdAt;

  /// ISO timestamp of last activity.
  final String updatedAt;

  /// Number of messages in the session.
  final int messageCount;

  const ChatSession({
    required this.sessionId,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });
}
