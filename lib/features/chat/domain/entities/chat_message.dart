import 'action_button.dart';
import 'health_observation.dart';

/// Represents the role of a chat message participant.
enum ChatRole { user, assistant, system }

/// Domain entity for a single chat message.
class ChatMessageEntity {
  /// Role of the message sender.
  final ChatRole role;

  /// Content of the message (may contain markdown).
  final String content;

  /// Optional timestamp for display purposes.
  final DateTime? timestamp;

  /// Typed response intent: general_text, health_recommendation, product_list, thali_suggestion, order_status, confirmation_required, clarifying_question, error
  final String responseType;

  /// Intent label e.g. cold_relief, catalog_product_search
  final String intent;

  /// Recommendation items with product/practice cards
  final List<Map<String, dynamic>> recommendations;

  /// Self-care imperative advice tips
  final List<Map<String, dynamic>> selfCareTips;

  /// Typed order status stepper data
  final Map<String, dynamic>? orderData;

  /// Typed product cards data list
  final List<Map<String, dynamic>> productsData;

  /// Typed side-effect confirmation card data
  final Map<String, dynamic>? confirmationData;

  /// Typed food thali plan data
  final Map<String, dynamic>? thaliData;

  /// Typed cart data
  final Map<String, dynamic>? cartData;

  /// Optional UI Action payload for triggering navigation or interactive buttons.
  final Map<String, dynamic>? uiAction;

  /// List of interactive action buttons for screen redirection.
  final List<ActionButton> actionButtons;

  /// Extracted health observation data
  final HealthObservation? healthObservation;

  /// Whether the observation has been saved
  final bool observationSaved;

  const ChatMessageEntity({
    required this.role,
    required this.content,
    this.timestamp,
    this.responseType = 'general_text',
    this.intent = 'general_query',
    this.recommendations = const [],
    this.selfCareTips = const [],
    this.orderData,
    this.productsData = const [],
    this.confirmationData,
    this.thaliData,
    this.cartData,
    this.uiAction,
    this.actionButtons = const [],
    this.healthObservation,
    this.observationSaved = false,
  });

  /// Whether this message was sent by the user.
  bool get isUser => role == ChatRole.user;

  /// Whether this message was sent by the AI assistant.
  bool get isAssistant => role == ChatRole.assistant;

  ChatMessageEntity copyWith({
    ChatRole? role,
    String? content,
    DateTime? timestamp,
    String? responseType,
    String? intent,
    List<Map<String, dynamic>>? recommendations,
    List<Map<String, dynamic>>? selfCareTips,
    Map<String, dynamic>? orderData,
    List<Map<String, dynamic>>? productsData,
    Map<String, dynamic>? confirmationData,
    Map<String, dynamic>? thaliData,
    Map<String, dynamic>? cartData,
    Map<String, dynamic>? uiAction,
    List<ActionButton>? actionButtons,
    HealthObservation? healthObservation,
    bool? observationSaved,
  }) {
    return ChatMessageEntity(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      responseType: responseType ?? this.responseType,
      intent: intent ?? this.intent,
      recommendations: recommendations ?? this.recommendations,
      selfCareTips: selfCareTips ?? this.selfCareTips,
      orderData: orderData ?? this.orderData,
      productsData: productsData ?? this.productsData,
      confirmationData: confirmationData ?? this.confirmationData,
      thaliData: thaliData ?? this.thaliData,
      cartData: cartData ?? this.cartData,
      uiAction: uiAction ?? this.uiAction,
      actionButtons: actionButtons ?? this.actionButtons,
      healthObservation: healthObservation ?? this.healthObservation,
      observationSaved: observationSaved ?? this.observationSaved,
    );
  }
}
