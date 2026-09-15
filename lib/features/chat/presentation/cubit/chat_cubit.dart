import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/send_message_use_case.dart';
import '../../domain/usecases/stream_message_use_case.dart';
import '../../domain/usecases/create_session_use_case.dart';
import '../../domain/usecases/list_sessions_use_case.dart';
import '../../domain/usecases/get_session_detail_use_case.dart';
import '../../domain/usecases/rename_session_use_case.dart';
import '../../domain/usecases/delete_session_use_case.dart';
import '../../domain/usecases/confirm_action_use_case.dart';
import '../../domain/usecases/save_health_observation_use_case.dart';
import '../../domain/usecases/delete_memory_use_case.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_stream_event.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final StreamMessageUseCase _streamMessageUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final CreateSessionUseCase _createSessionUseCase;
  final ListSessionsUseCase _listSessionsUseCase;
  final GetSessionDetailUseCase _getSessionDetailUseCase;
  final RenameSessionUseCase _renameSessionUseCase;
  final DeleteSessionUseCase _deleteSessionUseCase;
  final ConfirmActionUseCase _confirmActionUseCase;
  final SaveHealthObservationUseCase _saveHealthObservationUseCase;
  final DeleteMemoryUseCase _deleteMemoryUseCase;

  StreamSubscription<ChatStreamEvent>? _streamSubscription;

  ChatCubit({
    required StreamMessageUseCase streamMessageUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required CreateSessionUseCase createSessionUseCase,
    required ListSessionsUseCase listSessionsUseCase,
    required GetSessionDetailUseCase getSessionDetailUseCase,
    required RenameSessionUseCase renameSessionUseCase,
    required DeleteSessionUseCase deleteSessionUseCase,
    required ConfirmActionUseCase confirmActionUseCase,
    required SaveHealthObservationUseCase saveHealthObservationUseCase,
    required DeleteMemoryUseCase deleteMemoryUseCase,
  }) : _streamMessageUseCase = streamMessageUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _createSessionUseCase = createSessionUseCase,
       _listSessionsUseCase = listSessionsUseCase,
       _getSessionDetailUseCase = getSessionDetailUseCase,
       _renameSessionUseCase = renameSessionUseCase,
       _deleteSessionUseCase = deleteSessionUseCase,
       _confirmActionUseCase = confirmActionUseCase,
       _saveHealthObservationUseCase = saveHealthObservationUseCase,
       _deleteMemoryUseCase = deleteMemoryUseCase,
       super(const ChatState());

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }

  Future<void> loadSessions() async {
    emit(state.copyWith(sessionListStatus: SessionListStatus.loading));
    try {
      final sessions = await _listSessionsUseCase();
      emit(
        state.copyWith(
          sessionListStatus: SessionListStatus.loaded,
          sessions: sessions,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          sessionListStatus: SessionListStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> createNewSession({String? title}) async {
    emit(state.copyWith(isCreatingSession: true));
    try {
      final session = await _createSessionUseCase(title: title);
      emit(
        state.copyWith(
          activeSessionId: session.sessionId,
          messages: [],
          suggestedChips: [],
          isCreatingSession: false,
        ),
      );
      await loadSessions();
    } catch (e) {
      emit(
        state.copyWith(isCreatingSession: false, errorMessage: e.toString()),
      );
    }
  }

  Future<void> selectSession(String sessionId) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final detail = await _getSessionDetailUseCase(sessionId);
      emit(
        state.copyWith(
          status: ChatStatus.loaded,
          activeSessionId: detail.session.sessionId,
          messages: detail.messages,
          suggestedChips: [],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ChatStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> sendMessage(String message, {File? file}) async {
    if (message.trim().isEmpty && file == null) return;

    final userMessage = ChatMessageEntity(
      role: ChatRole.user,
      content: message,
      timestamp: DateTime.now(),
    );

    emit(
      state.copyWith(
        status: ChatStatus.sending,
        messages: List.from(state.messages)..add(userMessage),
        streamingText: '',
        currentStage: null,
        stageLabel: null,
        stageHistory: [],
        suggestedChips: [],
      ),
    );

    String? sessionId = state.activeSessionId;
    if (sessionId == null) {
      try {
        final session = await _createSessionUseCase(
          title: message.length > 30 ? message.substring(0, 30) : message,
        );
        sessionId = session.sessionId;
        emit(state.copyWith(activeSessionId: sessionId));
      } catch (e) {
        emit(
          state.copyWith(
            status: ChatStatus.error,
            errorMessage: "Failed to create session: $e",
          ),
        );
        return;
      }
    }

    await _streamSubscription?.cancel();
    emit(state.copyWith(status: ChatStatus.streaming));

    _streamSubscription = _streamMessageUseCase(
      message: message,
      sessionId: sessionId,
      file: file,
      topK: 5,
    ).listen(
      (event) {
        switch (event.type) {
          case ChatStreamEventType.stage:
            final newStageItem = {
              'stage': event.stage ?? '',
              'label': event.label ?? '',
            };
            final updatedHistory = List<Map<String, String>>.from(
              state.stageHistory,
            );
            if (!updatedHistory.any((item) => item['stage'] == event.stage)) {
              updatedHistory.add(newStageItem);
            }
            emit(
              state.copyWith(
                currentStage: event.stage,
                stageLabel: event.label,
                stageHistory: updatedHistory,
              ),
            );
            break;
          case ChatStreamEventType.token:
            emit(
              state.copyWith(
                streamingText: state.streamingText + (event.content ?? ''),
              ),
            );
            break;
          case ChatStreamEventType.finalPayload:
            final aiMessage = ChatMessageEntity(
              role: ChatRole.assistant,
              content: event.finalPayload?.response ?? state.streamingText,
              timestamp: DateTime.now(),
              responseType: event.finalPayload?.responseType ?? 'general_text',
              intent: event.finalPayload?.intent ?? 'general_query',
              recommendations: event.finalPayload?.recommendations ?? [],
              selfCareTips: event.finalPayload?.selfCareTips ?? [],
              orderData: event.finalPayload?.orderData,
              productsData: event.finalPayload?.productsData ?? [],
              confirmationData: event.finalPayload?.confirmationData,
              thaliData: event.finalPayload?.thaliData,
              cartData: event.finalPayload?.cartData,
              uiAction: event.finalPayload?.uiAction,
              actionButtons: event.finalPayload?.actionButtons ?? [],
              healthObservation: event.finalPayload?.healthObservation,
            );
            emit(
              state.copyWith(
                status: ChatStatus.loaded,
                messages: List.from(state.messages)..add(aiMessage),
                quotaInfo: event.finalPayload?.quotaInfo,
                suggestedChips: event.finalPayload?.suggestedChips ?? [],
                streamingText: '',
                currentStage: null,
                stageLabel: null,
              ),
            );
            break;
          case ChatStreamEventType.done:
            loadSessions();
            break;
          case ChatStreamEventType.error:
            emit(
              state.copyWith(
                status: ChatStatus.error,
                errorMessage: event.errorDetail ?? 'Unknown streaming error',
              ),
            );
            break;
        }
      },
      onError: (error) {
        emit(
          state.copyWith(
            status: ChatStatus.error,
            errorMessage: error.toString(),
          ),
        );
      },
    );
  }

  /// Non-streaming fallback for sending a message.
  Future<void> sendMessageNonStreaming(String message, {File? file}) async {
    if (message.trim().isEmpty && file == null) return;

    final userMessage = ChatMessageEntity(
      role: ChatRole.user,
      content: message,
      timestamp: DateTime.now(),
    );

    emit(
      state.copyWith(
        status: ChatStatus.sending,
        messages: List.from(state.messages)..add(userMessage),
        suggestedChips: [],
      ),
    );

    String? sessionId = state.activeSessionId;
    if (sessionId == null) {
      try {
        final session = await _createSessionUseCase(
          title: message.length > 30 ? message.substring(0, 30) : message,
        );
        sessionId = session.sessionId;
        emit(state.copyWith(activeSessionId: sessionId));
      } catch (e) {
        emit(
          state.copyWith(
            status: ChatStatus.error,
            errorMessage: "Failed to create session: $e",
          ),
        );
        return;
      }
    }

    try {
      final res = await _sendMessageUseCase(
        message: message,
        sessionId: sessionId,
        file: file,
        topK: 5,
      );

      final aiMessage = ChatMessageEntity(
        role: ChatRole.assistant,
        content: res.response,
        timestamp: DateTime.now(),
        responseType: res.responseType,
        intent: res.intent,
        recommendations: res.recommendations,
        selfCareTips: res.selfCareTips,
        orderData: res.orderData,
        productsData: res.productsData,
        confirmationData: res.confirmationData,
        thaliData: res.thaliData,
        cartData: res.cartData,
        uiAction: res.uiAction,
        actionButtons: res.actionButtons,
        healthObservation: res.healthObservation,
      );

      emit(
        state.copyWith(
          status: ChatStatus.loaded,
          messages: List.from(state.messages)..add(aiMessage),
          quotaInfo: res.quotaInfo,
          suggestedChips: res.suggestedChips,
        ),
      );
      await loadSessions();
    } catch (e) {
      emit(
        state.copyWith(status: ChatStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> renameSession(String sessionId, String title) async {
    try {
      await _renameSessionUseCase(sessionId, title);
      await loadSessions();
    } catch (e) {
      emit(state.copyWith(errorMessage: "Rename failed: $e"));
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _deleteSessionUseCase(sessionId);
      if (state.activeSessionId == sessionId) {
        emit(
          state.copyWith(
            activeSessionId: null,
            messages: [],
            suggestedChips: [],
          ),
        );
      }
      await loadSessions();
    } catch (e) {
      emit(state.copyWith(errorMessage: "Delete failed: $e"));
    }
  }

  void clearChat() {
    emit(
      state.copyWith(
        activeSessionId: null,
        messages: [],
        suggestedChips: [],
        status: ChatStatus.initial,
      ),
    );
    createNewSession();
  }

  /// Confirm a pending side-effect action with the backend nonce.
  Future<void> confirmAction({
    required String confirmationId,
    required String message,
  }) async {
    final sessionId = state.activeSessionId;
    if (sessionId == null) return;
    emit(state.copyWith(isConfirming: true));
    try {
      final res = await _confirmActionUseCase(
        message: message,
        sessionId: sessionId,
        confirmationId: confirmationId,
      );
      final aiMessage = ChatMessageEntity(
        role: ChatRole.assistant,
        content: res.response,
        timestamp: DateTime.now(),
        responseType: res.responseType,
        intent: res.intent,
        recommendations: res.recommendations,
        selfCareTips: res.selfCareTips,
        orderData: res.orderData,
        productsData: res.productsData,
        confirmationData: res.confirmationData,
        thaliData: res.thaliData,
        cartData: res.cartData,
        uiAction: res.uiAction,
        actionButtons: res.actionButtons,
        healthObservation: res.healthObservation,
      );
      emit(state.copyWith(
        isConfirming: false,
        messages: List.from(state.messages)..add(aiMessage),
        quotaInfo: res.quotaInfo,
        suggestedChips: res.suggestedChips,
      ));
    } catch (e) {
      emit(state.copyWith(
        isConfirming: false,
        errorMessage: 'Confirmation failed: $e',
      ));
    }
  }

  /// Save a health observation with explicit user consent.
  Future<void> saveHealthObservation({
    required String originalMessage,
  }) async {
    final sessionId = state.activeSessionId;
    if (sessionId == null) return;
    emit(state.copyWith(isSavingObservation: true));
    try {
      await _saveHealthObservationUseCase(
        message: originalMessage,
        sessionId: sessionId,
      );
      // Mark the last assistant message's observation as saved
      final updatedMessages = List<ChatMessageEntity>.from(state.messages);
      for (int i = updatedMessages.length - 1; i >= 0; i--) {
        if (updatedMessages[i].healthObservation != null &&
            !updatedMessages[i].observationSaved) {
          updatedMessages[i] = updatedMessages[i].copyWith(
            observationSaved: true,
          );
          break;
        }
      }
      emit(state.copyWith(
        isSavingObservation: false,
        messages: updatedMessages,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSavingObservation: false,
        errorMessage: 'Failed to save observation: $e',
      ));
    }
  }

  /// Dismiss a health observation locally without calling the API.
  void dismissHealthObservation(int messageIndex) {
    final updatedMessages = List<ChatMessageEntity>.from(state.messages);
    if (messageIndex >= 0 && messageIndex < updatedMessages.length) {
      updatedMessages[messageIndex] = updatedMessages[messageIndex].copyWith(
        observationSaved: true, // Mark as handled
      );
      emit(state.copyWith(messages: updatedMessages));
    }
  }

  /// Delete all AI memory for the current user.
  Future<void> deleteMemory() async {
    emit(state.copyWith(
      isDeletingMemory: true,
      memoryDeleteStatus: MemoryDeleteStatus.deleting,
    ));
    try {
      await _deleteMemoryUseCase();
      emit(state.copyWith(
        isDeletingMemory: false,
        memoryDeleteStatus: MemoryDeleteStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        isDeletingMemory: false,
        memoryDeleteStatus: MemoryDeleteStatus.error,
        errorMessage: 'Failed to delete AI memory: $e',
      ));
    }
  }
}
