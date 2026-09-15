import '../entities/chat_session.dart';
import '../repositories/chat_repository.dart';

/// Use case: Rename an existing chat session.
class RenameSessionUseCase {
  final ChatRepository _repository;
  const RenameSessionUseCase(this._repository);

  Future<ChatSession> call(String sessionId, String title) {
    return _repository.renameSession(sessionId, title);
  }
}
