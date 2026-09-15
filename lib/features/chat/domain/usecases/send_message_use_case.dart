import 'dart:io';

import '../entities/chat_response.dart';
import '../repositories/chat_repository.dart';

/// Use case: Send a message to the AI agent and get a complete response.
class SendMessageUseCase {
  final ChatRepository _repository;
  const SendMessageUseCase(this._repository);

  Future<ChatResponseEntity> call({
    required String message,
    String? sessionId,
    int topK = 4,
    File? file,
  }) {
    return _repository.sendMessage(
      message: message,
      sessionId: sessionId,
      topK: topK,
      file: file,
    );
  }
}
