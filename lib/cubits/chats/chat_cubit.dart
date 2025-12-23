import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/models/chat_model.dart';
import 'package:grocery_app/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repository;

  ChatCubit({required ChatRepository repository}) 
      : _repository = repository, 
        super(const ChatState());

  Future<void> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty) return;

    // 1. OPTIMISTIC UPDATE: Add user message immediately
    final userMessage = ChatMessage(text: messageText, isUser: true);
    
    final updatedMessages = List<ChatMessage>.from(state.messages)
      ..add(userMessage);

    emit(state.copyWith(
      messages: updatedMessages,
      status: ChatStatus.loading,
    ));

    try {
      // 2. Call API
      final response = await _repository.sendQuery(messageText);

      // 3. Create Bot Message from API Response
      final botMessage = ChatMessage(
        text: response.answer, 
        isUser: false
      );

      final finalMessages = List<ChatMessage>.from(state.messages)
        ..add(botMessage);

      emit(state.copyWith(
        messages: finalMessages,
        status: ChatStatus.success,
      ));
    } catch (e) {
      // Handle Error (optionally remove the user message or show red error)
      emit(state.copyWith(
        status: ChatStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}