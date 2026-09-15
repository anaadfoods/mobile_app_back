import '../repositories/chat_repository.dart';

/// Use case: Delete all AI memory (Qdrant vector facts) for the current user.
class DeleteMemoryUseCase {
  final ChatRepository _repository;
  const DeleteMemoryUseCase(this._repository);

  Future<bool> call() {
    return _repository.deleteMemory();
  }
}
