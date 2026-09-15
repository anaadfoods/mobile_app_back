import 'chat_response.dart';

/// Types of events emitted during SSE streaming.
enum ChatStreamEventType { stage, token, finalPayload, done, error }

/// Domain entity representing a single event in the SSE chat stream.
///
/// The backend emits these event types:
/// - `stage`: AI processing stage (e.g. 'MEDICAL_OCR', 'API_TOOL', 'KNOWLEDGE_RAG', 'SYNTHESIZING')
/// - `token`: A single word/token of the streaming response
/// - `finalPayload`: The complete response with metadata (ui_action, chips, keywords)
/// - `done`: Stream is complete
/// - `error`: An error occurred during processing
class ChatStreamEvent {
  /// The type of this stream event.
  final ChatStreamEventType type;

  /// Stage identifier (only for `stage` events).
  final String? stage;

  /// Human-readable stage label (only for `stage` events).
  final String? label;

  /// Token content (only for `token` events).
  final String? content;

  /// Complete response payload (only for `finalPayload` events).
  final ChatResponseEntity? finalPayload;

  /// Error detail message (only for `error` events).
  final String? errorDetail;

  const ChatStreamEvent({
    required this.type,
    this.stage,
    this.label,
    this.content,
    this.finalPayload,
    this.errorDetail,
  });
}
