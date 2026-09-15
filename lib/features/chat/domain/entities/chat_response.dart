import 'action_button.dart';
import 'health_observation.dart';
import 'token_quota_info.dart';

/// Domain entity representing the full AI agent chat response.
///
/// Maps to the backend `ChatResponse` schema, containing the response text,
/// typed card payloads (order_status, product_list, confirmation_required, thali_plan),
/// UI action payloads, action buttons, token quota info, suggested chips, and extracted keywords.
class ChatResponseEntity {
  /// The AI-generated response text (GitHub-Flavored Markdown).
  final String response;

  /// Session ID for this conversation (use in subsequent requests).
  final String sessionId;

  /// Typed response intent: general_text, health_recommendation, product_list, thali_suggestion, order_status, confirmation_required, clarifying_question, error
  final String responseType;

  /// Intent label e.g. cold_relief, headache, order_tracking
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

  /// Health profile signal context
  final Map<String, dynamic>? personalizationContext;

  /// Structured error details if unfulfilled
  final Map<String, dynamic>? error;

  /// Catalog / document source IDs
  final List<String> sources;

  /// Authenticated user ID.
  final dynamic userId;

  /// Authenticated user email.
  final String? userEmail;

  /// Action payload for Flutter to trigger UI screens/modals.
  final Map<String, dynamic>? uiAction;

  /// Interactive action buttons for screen redirections.
  final List<ActionButton> actionButtons;

  /// 3-Tier AI Token Quota & usage status.
  final TokenQuotaInfo? quotaInfo;

  /// List of single-tap quick prompt recommendation chips.
  final List<String> suggestedChips;

  /// Extracted health biomarkers and medical keywords.
  final List<String> extractedKeywords;

  /// Extracted health observation data.
  final HealthObservation? healthObservation;

  const ChatResponseEntity({
    required this.response,
    required this.sessionId,
    this.responseType = 'general_text',
    this.intent = 'general_query',
    this.recommendations = const [],
    this.selfCareTips = const [],
    this.orderData,
    this.productsData = const [],
    this.confirmationData,
    this.thaliData,
    this.cartData,
    this.personalizationContext,
    this.error,
    this.sources = const [],
    this.userId,
    this.userEmail,
    this.uiAction,
    this.actionButtons = const [],
    this.quotaInfo,
    this.suggestedChips = const [],
    this.extractedKeywords = const [],
    this.healthObservation,
  });
}
