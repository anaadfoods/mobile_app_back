import 'dart:io';

import '../../domain/entities/chat_response.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/chat_session_detail.dart';
import '../../domain/entities/chat_stream_event.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

/// Implementation of [ChatRepository] that delegates to the
/// [ChatRemoteDataSource] and converts data models to domain entities.
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  const ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<ChatResponseEntity> sendMessage({
    required String message,
    String? sessionId,
    int topK = 4,
    File? file,
    bool userConfirmed = false,
    String? confirmationId,
    bool saveHealthObservation = false,
  }) async {
    final model = await _remoteDataSource.sendMessage(
      message: message,
      sessionId: sessionId,
      topK: topK,
      file: file,
      userConfirmed: userConfirmed,
      confirmationId: confirmationId,
      saveHealthObservation: saveHealthObservation,
    );
    return model.toEntity();
  }

  @override
  Stream<ChatStreamEvent> streamMessage({
    required String message,
    String? sessionId,
    int topK = 4,
    File? file,
    bool userConfirmed = false,
    String? confirmationId,
    bool saveHealthObservation = false,
  }) {
    // The data source already yields domain ChatStreamEvent entities
    // because SSE parsing is done inline.
    return _remoteDataSource.streamMessage(
      message: message,
      sessionId: sessionId,
      topK: topK,
      file: file,
      userConfirmed: userConfirmed,
      confirmationId: confirmationId,
      saveHealthObservation: saveHealthObservation,
    );
  }

  @override
  Future<ChatSession> createSession({String? title}) async {
    final model = await _remoteDataSource.createSession(title: title);
    return model.toEntity();
  }

  @override
  Future<List<ChatSession>> listSessions() async {
    final models = await _remoteDataSource.listSessions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ChatSessionDetail> getSessionDetail(String sessionId) async {
    final data = await _remoteDataSource.getSessionDetail(sessionId);
    return ChatSessionDetail(
      session: data.session.toEntity(),
      messages: data.messages.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<ChatSession> renameSession(String sessionId, String title) async {
    final model = await _remoteDataSource.renameSession(sessionId, title);
    return model.toEntity();
  }

  @override
  Future<bool> deleteSession(String sessionId) {
    return _remoteDataSource.deleteSession(sessionId);
  }

  @override
  Future<bool> deleteMemory() {
    return _remoteDataSource.deleteMemory();
  }
}
