import 'dart:io';

import '../entities/chat_response.dart';
import '../entities/chat_session.dart';
import '../entities/chat_session_detail.dart';
import '../entities/chat_stream_event.dart';

/// Abstract repository interface for the AI Chat feature.
///
/// Defines all operations needed for the chat system:
/// messaging (send + stream), and session management (CRUD).
/// Implementations live in the data layer.
abstract class ChatRepository {
  /// Send a message and get a complete response.
  Future<ChatResponseEntity> sendMessage({
    required String message,
    String? sessionId,
    int topK = 4,
    File? file,
    bool userConfirmed = false,
    String? confirmationId,
    bool saveHealthObservation = false,
  });

  /// Send a message and receive a streaming response via SSE.
  Stream<ChatStreamEvent> streamMessage({
    required String message,
    String? sessionId,
    int topK = 4,
    File? file,
    bool userConfirmed = false,
    String? confirmationId,
    bool saveHealthObservation = false,
  });

  /// Create a new chat session.
  Future<ChatSession> createSession({String? title});

  /// List all chat sessions for the current user, newest first.
  Future<List<ChatSession>> listSessions();

  /// Get full conversation history and metadata for a session.
  Future<ChatSessionDetail> getSessionDetail(String sessionId);

  /// Rename a chat session.
  Future<ChatSession> renameSession(String sessionId, String title);

  /// Delete a chat session and its entire conversation history.
  Future<bool> deleteSession(String sessionId);

  /// Delete all AI memory (Qdrant vectors) for the current user.
  Future<bool> deleteMemory();
}
