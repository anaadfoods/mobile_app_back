import '../entities/chat_session.dart';
import '../repositories/chat_repository.dart';

/// Use case: Create a new empty chat session.
class CreateSessionUseCase {
  final ChatRepository _repository;
  const CreateSessionUseCase(this._repository);

  Future<ChatSession> call({String? title}) {
    return _repository.createSession(title: title);
  }
}
