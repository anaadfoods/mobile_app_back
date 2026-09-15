import '../entities/chat_session.dart';
import '../repositories/chat_repository.dart';

/// Use case: List all chat sessions for the authenticated user.
class ListSessionsUseCase {
  final ChatRepository _repository;
  const ListSessionsUseCase(this._repository);

  Future<List<ChatSession>> call() {
    return _repository.listSessions();
  }
}
