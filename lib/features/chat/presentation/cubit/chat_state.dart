import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/token_quota_info.dart';

enum ChatStatus { initial, loading, loaded, sending, streaming, error }

enum SessionListStatus { initial, loading, loaded, error }

enum MemoryDeleteStatus { initial, deleting, success, error }

class ChatState extends Equatable {
  final ChatStatus status;
  final SessionListStatus sessionListStatus;
  final List<ChatSession> sessions;
  final String? activeSessionId;
  final List<ChatMessageEntity> messages;
  final String streamingText;
  final String? currentStage;
  final String? stageLabel;
  final List<Map<String, String>> stageHistory;
  final TokenQuotaInfo? quotaInfo;
  final List<String> suggestedChips;
  final String? errorMessage;
  final bool isCreatingSession;

  /// Whether a confirmation action is being processed.
  final bool isConfirming;

  /// Whether a health observation save is being processed.
  final bool isSavingObservation;

  /// Whether AI memory deletion is being processed.
  final bool isDeletingMemory;

  /// Result status of the last memory deletion attempt.
  final MemoryDeleteStatus memoryDeleteStatus;

  const ChatState({
    this.status = ChatStatus.initial,
    this.sessionListStatus = SessionListStatus.initial,
    this.sessions = const [],
    this.activeSessionId,
    this.messages = const [],
    this.streamingText = '',
    this.currentStage,
    this.stageLabel,
    this.stageHistory = const [],
    this.quotaInfo,
    this.suggestedChips = const [],
    this.errorMessage,
    this.isCreatingSession = false,
    this.isConfirming = false,
    this.isSavingObservation = false,
    this.isDeletingMemory = false,
    this.memoryDeleteStatus = MemoryDeleteStatus.initial,
  });

  ChatState copyWith({
    ChatStatus? status,
    SessionListStatus? sessionListStatus,
    List<ChatSession>? sessions,
    String? activeSessionId,
    List<ChatMessageEntity>? messages,
    String? streamingText,
    String? currentStage,
    String? stageLabel,
    List<Map<String, String>>? stageHistory,
    TokenQuotaInfo? quotaInfo,
    List<String>? suggestedChips,
    String? errorMessage,
    bool? isCreatingSession,
    bool? isConfirming,
    bool? isSavingObservation,
    bool? isDeletingMemory,
    MemoryDeleteStatus? memoryDeleteStatus,
  }) {
    return ChatState(
      status: status ?? this.status,
      sessionListStatus: sessionListStatus ?? this.sessionListStatus,
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      messages: messages ?? this.messages,
      streamingText: streamingText ?? this.streamingText,
      currentStage: currentStage ?? this.currentStage,
      stageLabel: stageLabel ?? this.stageLabel,
      stageHistory: stageHistory ?? this.stageHistory,
      quotaInfo: quotaInfo ?? this.quotaInfo,
      suggestedChips: suggestedChips ?? this.suggestedChips,
      errorMessage: errorMessage ?? this.errorMessage,
      isCreatingSession: isCreatingSession ?? this.isCreatingSession,
      isConfirming: isConfirming ?? this.isConfirming,
      isSavingObservation: isSavingObservation ?? this.isSavingObservation,
      isDeletingMemory: isDeletingMemory ?? this.isDeletingMemory,
      memoryDeleteStatus: memoryDeleteStatus ?? this.memoryDeleteStatus,
    );
  }

  @override
  List<Object?> get props => [
    status,
    sessionListStatus,
    sessions,
    activeSessionId,
    messages,
    streamingText,
    currentStage,
    stageLabel,
    stageHistory,
    quotaInfo,
    suggestedChips,
    errorMessage,
    isCreatingSession,
    isConfirming,
    isSavingObservation,
    isDeletingMemory,
    memoryDeleteStatus,
  ];
}
