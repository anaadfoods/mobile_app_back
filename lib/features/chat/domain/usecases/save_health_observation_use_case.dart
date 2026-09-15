import '../entities/chat_response.dart';
import '../repositories/chat_repository.dart';

/// Use case: Save a health observation with explicit user consent.
///
/// Resends the original user message with `saveHealthObservation=true`
/// to persist the food-symptom association.
class SaveHealthObservationUseCase {
  final ChatRepository _repository;
  const SaveHealthObservationUseCase(this._repository);

  Future<ChatResponseEntity> call({
    required String message,
    required String sessionId,
  }) {
    return _repository.sendMessage(
      message: message,
      sessionId: sessionId,
      saveHealthObservation: true,
    );
  }
}
