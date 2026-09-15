import '../repositories/chat_repository.dart';

/// Use case: Delete a chat session and its entire conversation history.
class DeleteSessionUseCase {
  final ChatRepository _repository;
  const DeleteSessionUseCase(this._repository);

  Future<bool> call(String sessionId) {
    return _repository.deleteSession(sessionId);
  }
}
