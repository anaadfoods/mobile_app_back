import 'dart:io';

import '../entities/chat_stream_event.dart';
import '../repositories/chat_repository.dart';

/// Use case: Stream a message to the AI agent via SSE.
class StreamMessageUseCase {
  final ChatRepository _repository;
  const StreamMessageUseCase(this._repository);

  Stream<ChatStreamEvent> call({
    required String message,
    String? sessionId,
    int topK = 4,
    File? file,
  }) {
    return _repository.streamMessage(
      message: message,
      sessionId: sessionId,
      topK: topK,
      file: file,
    );
  }
}
