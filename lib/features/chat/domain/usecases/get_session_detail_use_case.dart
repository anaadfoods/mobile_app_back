import '../entities/chat_session_detail.dart';
import '../repositories/chat_repository.dart';

/// Use case: Get full conversation history for a specific session.
class GetSessionDetailUseCase {
  final ChatRepository _repository;
  const GetSessionDetailUseCase(this._repository);

  Future<ChatSessionDetail> call(String sessionId) {
    return _repository.getSessionDetail(sessionId);
  }
}
