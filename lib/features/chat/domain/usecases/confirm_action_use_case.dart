import '../entities/chat_response.dart';
import '../repositories/chat_repository.dart';

/// Use case: Confirm a pending side-effect action.
///
/// Sends the original message back with `userConfirmed=true` and the
/// backend-issued `confirmationId` nonce to execute the action.
class ConfirmActionUseCase {
  final ChatRepository _repository;
  const ConfirmActionUseCase(this._repository);

  Future<ChatResponseEntity> call({
    required String message,
    required String sessionId,
    required String confirmationId,
  }) {
    return _repository.sendMessage(
      message: message,
      sessionId: sessionId,
      userConfirmed: true,
      confirmationId: confirmationId,
    );
  }
}
