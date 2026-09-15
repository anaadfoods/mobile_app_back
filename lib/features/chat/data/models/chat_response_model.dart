import 'dart:convert';

import '../../domain/entities/action_button.dart';
import '../../domain/entities/chat_response.dart';
import '../../domain/entities/health_observation.dart';
import '../../domain/entities/token_quota_info.dart';

/// Data model for the full AI agent chat response.
class ChatResponseModel {
  final String response;
  final String sessionId;
  final String responseType;
  final String intent;
  final List<Map<String, dynamic>> recommendations;
  final List<Map<String, dynamic>> selfCareTips;
  final Map<String, dynamic>? orderData;
  final List<Map<String, dynamic>> productsData;
  final Map<String, dynamic>? confirmationData;
  final Map<String, dynamic>? thaliData;
  final Map<String, dynamic>? cartData;
  final Map<String, dynamic>? personalizationContext;
  final Map<String, dynamic>? error;
  final List<String> sources;
  final dynamic userId;
  final String? userEmail;
  final Map<String, dynamic>? uiAction;
  final List<ActionButton> actionButtons;
  final TokenQuotaInfo? quotaInfo;
  final List<String> suggestedChips;
  final List<String> extractedKeywords;
  final HealthObservation? healthObservation;

  const ChatResponseModel({
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

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) {
    final rawUiAction =
        json['ui_action'] is Map
            ? json['ui_action'] as Map<String, dynamic>
            : (json['ui_action'] is String
                ? {'action': json['ui_action']}
                : null);
    List<ActionButton> buttons = [];

    if (json['action_buttons'] != null && json['action_buttons'] is List) {
      buttons =
          (json['action_buttons'] as List<dynamic>)
              .map(
                (e) =>
                    ActionButton.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
    } else if (rawUiAction != null && rawUiAction.isNotEmpty) {
      buttons = [ActionButton.fromUiAction(rawUiAction)];
    }

    final rawQuotaInfo = json['quota_info'] as Map<String, dynamic>?;
    final quota =
        rawQuotaInfo != null ? TokenQuotaInfo.fromJson(rawQuotaInfo) : null;

    final rawProducts = json['products_data'] as List<dynamic>?;
    final List<Map<String, dynamic>> parsedProducts =
        rawProducts != null
            ? rawProducts
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : [];

    final rawRecs = json['recommendations'] as List<dynamic>?;
    final List<Map<String, dynamic>> parsedRecs =
        rawRecs != null
            ? rawRecs.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];

    final rawTips = json['self_care_tips'] as List<dynamic>?;
    final List<Map<String, dynamic>> parsedTips =
        rawTips != null
            ? rawTips.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];

    HealthObservation? healthObs;
    if (json['health_observation'] != null && json['health_observation'] is Map) {
      healthObs = HealthObservation.fromJson(
        Map<String, dynamic>.from(json['health_observation'] as Map),
      );
    }

    String rawResponseStr = (json['response'] as String? ?? '').trim();

    // ── Unnest JSON string if backend returned JSON embedded in response field ──
    if ((rawResponseStr.startsWith('{') && rawResponseStr.endsWith('}')) ||
        rawResponseStr.contains('"products_data"')) {
      try {
        final Map<String, dynamic> innerMap = Map<String, dynamic>.from(
          jsonDecode(rawResponseStr) as Map,
        );
        if (innerMap.containsKey('products_data') && parsedProducts.isEmpty) {
          final innerProds = innerMap['products_data'] as List<dynamic>?;
          if (innerProds != null) {
            parsedProducts.addAll(
              innerProds.map((e) => Map<String, dynamic>.from(e as Map)),
            );
          }
        }
        if (innerMap.containsKey('recommendations') && parsedRecs.isEmpty) {
          final innerRecs = innerMap['recommendations'] as List<dynamic>?;
          if (innerRecs != null) {
            parsedRecs.addAll(
              innerRecs.map((e) => Map<String, dynamic>.from(e as Map)),
            );
          }
        }
        if (innerMap.containsKey('response') &&
            innerMap['response'].toString().isNotEmpty) {
          rawResponseStr = innerMap['response'].toString().trim();
        } else {
          rawResponseStr = '';
        }
      } catch (_) {}
    }

    // ── Ensure response is a clean conversational sentence ──
    if (rawResponseStr.isEmpty ||
        (rawResponseStr.startsWith('{') && rawResponseStr.endsWith('}')) ||
        rawResponseStr.contains('"products_data"')) {
      if (parsedProducts.isNotEmpty) {
        final names =
            parsedProducts
                .map((p) => (p['product_name'] ?? p['name'] ?? '').toString())
                .where((n) => n.isNotEmpty)
                .take(3)
                .toList();
        if (names.isNotEmpty) {
          rawResponseStr =
              'Here are the top organic options from our catalog for you: ${names.join(", ")}.';
        } else {
          rawResponseStr =
              'Here are the top organic food products available in our Anaad Foods catalog for your query.';
        }
      } else if (parsedRecs.isNotEmpty) {
        rawResponseStr =
            'Here are your personalized Ayurvedic wellness recommendations and suggested practices.';
      } else {
        rawResponseStr = 'Here is the summary of information for your request.';
      }
    }

    String responseTypeStr = json['response_type'] as String? ?? 'general_text';
    String? uiActionType =
        rawUiAction?['action']?.toString() ??
        rawUiAction?['action_type']?.toString();
    final parsedCartData = json['cart_data'] as Map<String, dynamic>?;

    if (parsedCartData != null && parsedCartData.isNotEmpty) {
      if (responseTypeStr == 'general_text') {
        responseTypeStr = 'cart_view';
      }
      uiActionType ??= 'render_cart_card';
    } else if (parsedProducts.isNotEmpty) {
      if (responseTypeStr == 'general_text') {
        responseTypeStr = 'product_list';
      }
      uiActionType ??= 'render_product_carousel';
    } else if (parsedRecs.isNotEmpty) {
      if (responseTypeStr == 'general_text') {
        responseTypeStr = 'health_recommendation';
      }
      uiActionType ??= 'render_recommendation_cards';
    }

    final finalUiAction =
        rawUiAction ?? (uiActionType != null ? {'action': uiActionType} : null);

    return ChatResponseModel(
      response: rawResponseStr,
      sessionId: json['session_id'] as String? ?? '',
      responseType: responseTypeStr,
      intent:
          json['intent'] as String? ??
          (parsedProducts.isNotEmpty
              ? 'catalog_product_search'
              : 'general_query'),
      recommendations: parsedRecs,
      selfCareTips: parsedTips,
      orderData: json['order_data'] as Map<String, dynamic>?,
      productsData: parsedProducts,
      confirmationData: json['confirmation_data'] as Map<String, dynamic>?,
      thaliData: json['thali_data'] as Map<String, dynamic>?,
      cartData: parsedCartData,
      personalizationContext:
          json['personalization_context'] as Map<String, dynamic>?,
      error: json['error'] as Map<String, dynamic>?,
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      userId: json['user_id'],
      userEmail: json['user_email'] as String?,
      uiAction: finalUiAction,
      actionButtons: buttons,
      quotaInfo: quota,
      suggestedChips:
          (json['suggested_chips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      extractedKeywords:
          (json['extracted_keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      healthObservation: healthObs,
    );
  }

  /// Convert to domain entity.
  ChatResponseEntity toEntity() {
    return ChatResponseEntity(
      response: response,
      sessionId: sessionId,
      responseType: responseType,
      intent: intent,
      recommendations: recommendations,
      selfCareTips: selfCareTips,
      orderData: orderData,
      productsData: productsData,
      confirmationData: confirmationData,
      thaliData: thaliData,
      cartData: cartData,
      personalizationContext: personalizationContext,
      error: error,
      sources: sources,
      userId: userId,
      userEmail: userEmail,
      uiAction: uiAction,
      actionButtons: actionButtons,
      quotaInfo: quotaInfo,
      suggestedChips: suggestedChips,
      extractedKeywords: extractedKeywords,
      healthObservation: healthObservation,
    );
  }
}
