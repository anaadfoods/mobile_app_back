import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/utils/app_logger.dart';

import '../../domain/entities/action_button.dart';
import '../../domain/entities/chat_response.dart';
import '../../domain/entities/chat_stream_event.dart';
import '../../domain/entities/token_quota_info.dart';
import '../models/chat_message_model.dart';
import '../models/chat_response_model.dart';
import '../models/chat_session_model.dart';
import '../../domain/entities/health_observation.dart';

/// Helper class for passing session detail data from the data source.
class ChatSessionDetailData {
  final ChatSessionModel session;
  final List<ChatMessageModel> messages;

  const ChatSessionDetailData({required this.session, required this.messages});
}

/// Abstract interface for the chat remote data source.
abstract class ChatRemoteDataSource {
  /// Send a message and get a complete response.
  Future<ChatResponseModel> sendMessage({
    required String message,
    String? sessionId,
    int topK = 4,
    File? file,
    bool userConfirmed = false,
    String? confirmationId,
    bool saveHealthObservation = false,
  });

  /// Send a message and receive a streaming response via SSE.
  Stream<ChatStreamEvent> streamMessage({
    required String message,
    String? sessionId,
    int topK = 4,
    File? file,
    bool userConfirmed = false,
    String? confirmationId,
    bool saveHealthObservation = false,
  });

  /// Create a new chat session.
  Future<ChatSessionModel> createSession({String? title});

  /// List all chat sessions for the current user.
  Future<List<ChatSessionModel>> listSessions();

  /// Get full conversation history for a specific session.
  Future<ChatSessionDetailData> getSessionDetail(String sessionId);

  /// Rename a chat session.
  Future<ChatSessionModel> renameSession(String sessionId, String title);

  /// Delete a chat session.
  Future<bool> deleteSession(String sessionId);

  /// Delete all AI memory (Qdrant vectors) for the current user.
  Future<bool> deleteMemory();
}

/// Implementation of [ChatRemoteDataSource] using a dedicated Dio client
/// pointed at the AI Service FastAPI backend.
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  late final Dio _dio;

  ChatRemoteDataSourceImpl() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.aiServiceBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Get the current auth token and build authorization headers.
  Future<Options> _authOptions({
    String? contentType,
    ResponseType? responseType,
  }) async {
    final token = await getIt<TokenService>().getAccessToken();
    return Options(
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
      contentType: contentType,
      responseType: responseType,
    );
  }

  // ─────────────────────────────────────────────
  //  Chat Endpoints
  // ─────────────────────────────────────────────

  @override
  Future<ChatResponseModel> sendMessage({
    required String message,
    String? sessionId,
    int topK = 4,
    File? file,
    bool userConfirmed = false,
    String? confirmationId,
    bool saveHealthObservation = false,
  }) async {
    final formMap = <String, dynamic>{
      'message': message,
      'top_k': topK.toString(),
    };
    if (userConfirmed) formMap['user_confirmed'] = 'true';
    if (confirmationId != null) formMap['confirmation_id'] = confirmationId;
    if (saveHealthObservation) formMap['save_health_observation'] = 'true';
    if (sessionId != null) formMap['session_id'] = sessionId;

    final currentUser = getIt<TokenService>().currentUser ?? await getIt<TokenService>().getUserData();
    if (currentUser != null) {
      formMap['user_profile'] = jsonEncode(currentUser.toProfileJson());
    }

    if (file != null) {
      formMap['file'] = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      );
    }

    final formData = FormData.fromMap(formMap);
    final options = await _authOptions(contentType: 'multipart/form-data');

    final response = await _dio.post(
      ApiConfig.aiChatEndpoint,
      data: formData,
      options: options,
    );

    return ChatResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Stream<ChatStreamEvent> streamMessage({
    required String message,
    String? sessionId,
    int topK = 4,
    File? file,
    bool userConfirmed = false,
    String? confirmationId,
    bool saveHealthObservation = false,
  }) async* {
    final formMap = <String, dynamic>{
      'message': message,
      'top_k': topK.toString(),
    };
    if (userConfirmed) formMap['user_confirmed'] = 'true';
    if (confirmationId != null) formMap['confirmation_id'] = confirmationId;
    if (saveHealthObservation) formMap['save_health_observation'] = 'true';
    if (sessionId != null) formMap['session_id'] = sessionId;

    final currentUser = getIt<TokenService>().currentUser ?? await getIt<TokenService>().getUserData();
    if (currentUser != null) {
      formMap['user_profile'] = jsonEncode(currentUser.toProfileJson());
    }

    if (file != null) {
      formMap['file'] = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      );
    }

    final formData = FormData.fromMap(formMap);
    final options = await _authOptions(
      contentType: 'multipart/form-data',
      responseType: ResponseType.stream,
    );

    final response = await _dio.post<ResponseBody>(
      ApiConfig.aiChatStreamEndpoint,
      data: formData,
      options: options,
    );

    final stream = response.data!.stream;
    final buffer = StringBuffer();

    await for (final chunk in stream.cast<List<int>>().transform(
      utf8.decoder,
    )) {
      buffer.write(chunk);

      // Process complete SSE data lines
      while (true) {
        final bufStr = buffer.toString();
        final dataIdx = bufStr.indexOf('data: ');
        if (dataIdx == -1) break;

        // Find the end of this SSE message (double newline)
        final msgStart = dataIdx + 6; // length of 'data: '
        final doubleNewline = bufStr.indexOf('\n\n', msgStart);
        if (doubleNewline == -1) break; // Incomplete message, wait for more

        final jsonStr = bufStr.substring(msgStart, doubleNewline).trim();
        // Remove processed data from buffer
        buffer.clear();
        buffer.write(bufStr.substring(doubleNewline + 2));

        if (jsonStr.isEmpty) continue;

        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final event = json['event'] as String? ?? '';

          switch (event) {
            case 'stage':
              yield ChatStreamEvent(
                type: ChatStreamEventType.stage,
                stage: json['stage'] as String?,
                label: json['label'] as String?,
              );
              break;

            case 'token':
              yield ChatStreamEvent(
                type: ChatStreamEventType.token,
                content: json['content'] as String?,
              );
              break;

            case 'final_payload':
              final rawUiAction =
                  json['ui_action'] is Map
                      ? json['ui_action'] as Map<String, dynamic>
                      : (json['ui_action'] is String
                          ? {'action': json['ui_action']}
                          : null);
              List<ActionButton> buttons = [];
              if (json['action_buttons'] != null &&
                  json['action_buttons'] is List) {
                buttons =
                    (json['action_buttons'] as List<dynamic>)
                        .map(
                          (e) => ActionButton.fromJson(
                            Map<String, dynamic>.from(e as Map),
                          ),
                        )
                        .toList();
              } else if (rawUiAction != null && rawUiAction.isNotEmpty) {
                buttons = [ActionButton.fromUiAction(rawUiAction)];
              }

              final rawQuota = json['quota_info'] as Map<String, dynamic>?;
              final quota =
                  rawQuota != null ? TokenQuotaInfo.fromJson(rawQuota) : null;

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
                      ? rawRecs
                          .map((e) => Map<String, dynamic>.from(e as Map))
                          .toList()
                      : [];

              final rawTips = json['self_care_tips'] as List<dynamic>?;
              final List<Map<String, dynamic>> parsedTips =
                  rawTips != null
                      ? rawTips
                          .map((e) => Map<String, dynamic>.from(e as Map))
                          .toList()
                      : [];

              HealthObservation? healthObs;
              if (json['health_observation'] != null && json['health_observation'] is Map) {
                healthObs = HealthObservation.fromJson(
                  Map<String, dynamic>.from(json['health_observation'] as Map),
                );
              }

              String sseRespStr = (json['response'] as String? ?? '').trim();
              if ((sseRespStr.startsWith('{') && sseRespStr.endsWith('}')) ||
                  sseRespStr.contains('"products_data"')) {
                try {
                  final Map<String, dynamic> innerMap =
                      Map<String, dynamic>.from(jsonDecode(sseRespStr) as Map);
                  if (innerMap.containsKey('products_data') &&
                      parsedProducts.isEmpty) {
                    final innerProds =
                        innerMap['products_data'] as List<dynamic>?;
                    if (innerProds != null) {
                      parsedProducts.addAll(
                        innerProds.map(
                          (e) => Map<String, dynamic>.from(e as Map),
                        ),
                      );
                    }
                  }
                  if (innerMap.containsKey('recommendations') &&
                      parsedRecs.isEmpty) {
                    final innerRecs =
                        innerMap['recommendations'] as List<dynamic>?;
                    if (innerRecs != null) {
                      parsedRecs.addAll(
                        innerRecs.map(
                          (e) => Map<String, dynamic>.from(e as Map),
                        ),
                      );
                    }
                  }
                  if (innerMap.containsKey('response') &&
                      innerMap['response'].toString().isNotEmpty) {
                    sseRespStr = innerMap['response'].toString().trim();
                  } else {
                    sseRespStr = '';
                  }
                } catch (_) {}
              }

              if (sseRespStr.isEmpty ||
                  (sseRespStr.startsWith('{') && sseRespStr.endsWith('}')) ||
                  sseRespStr.contains('"products_data"')) {
                if (parsedProducts.isNotEmpty) {
                  final names =
                      parsedProducts
                          .map(
                            (p) =>
                                (p['product_name'] ?? p['name'] ?? '')
                                    .toString(),
                          )
                          .where((n) => n.isNotEmpty)
                          .take(3)
                          .toList();
                  if (names.isNotEmpty) {
                    sseRespStr =
                        'Here are the top organic options from our catalog for you: ${names.join(", ")}.';
                  } else {
                    sseRespStr =
                        'Here are the top organic food products available in our Anaad Foods catalog for your query.';
                  }
                } else if (parsedRecs.isNotEmpty) {
                  sseRespStr =
                      'Here are your personalized Ayurvedic wellness recommendations and suggested practices.';
                } else {
                  sseRespStr =
                      'Here is the summary of information for your request.';
                }
              }

              String sseRespTypeStr =
                  json['response_type'] as String? ?? 'general_text';
              String? sseUiActionType =
                  rawUiAction?['action']?.toString() ??
                  rawUiAction?['action_type']?.toString();

              if (parsedProducts.isNotEmpty) {
                if (sseRespTypeStr == 'general_text') {
                  sseRespTypeStr = 'product_list';
                }
                sseUiActionType ??= 'render_product_carousel';
              } else if (parsedRecs.isNotEmpty) {
                if (sseRespTypeStr == 'general_text') {
                  sseRespTypeStr = 'health_recommendation';
                }
                sseUiActionType ??= 'render_recommendation_cards';
              }

              final sseFinalUiAction =
                  rawUiAction ??
                  (sseUiActionType != null
                      ? {'action': sseUiActionType}
                      : null);

              final payload = ChatResponseEntity(
                response: sseRespStr,
                sessionId: json['session_id'] as String? ?? '',
                responseType: sseRespTypeStr,
                intent:
                    json['intent'] as String? ??
                    (parsedProducts.isNotEmpty
                        ? 'catalog_product_search'
                        : 'general_query'),
                recommendations: parsedRecs,
                selfCareTips: parsedTips,
                orderData: json['order_data'] as Map<String, dynamic>?,
                productsData: parsedProducts,
                confirmationData:
                    json['confirmation_data'] as Map<String, dynamic>?,
                thaliData: json['thali_data'] as Map<String, dynamic>?,
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
                uiAction: sseFinalUiAction,
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
              yield ChatStreamEvent(
                type: ChatStreamEventType.finalPayload,
                finalPayload: payload,
              );
              break;

            case 'done':
              yield const ChatStreamEvent(type: ChatStreamEventType.done);
              break;

            case 'error':
              yield ChatStreamEvent(
                type: ChatStreamEventType.error,
                errorDetail: json['detail'] as String? ?? 'Unknown error',
              );
              break;
          }
        } catch (e) {
          AppLogger.instance.log('SSE parse error: $e for JSON: $jsonStr');
        }
      }
    }
  }

  // ─────────────────────────────────────────────
  //  Session Endpoints
  // ─────────────────────────────────────────────

  @override
  Future<ChatSessionModel> createSession({String? title}) async {
    final options = await _authOptions();
    final response = await _dio.post(
      ApiConfig.aiSessionsEndpoint,
      data: title != null ? {'title': title} : {},
      options: options,
    );
    final data = response.data as Map<String, dynamic>;
    final sessionJson = data['session'] as Map<String, dynamic>? ?? data;
    return ChatSessionModel.fromJson(sessionJson);
  }

  @override
  Future<List<ChatSessionModel>> listSessions() async {
    final options = await _authOptions();
    final response = await _dio.get(
      ApiConfig.aiSessionsEndpoint,
      options: options,
    );
    final data = response.data as Map<String, dynamic>;
    final sessionsList = data['sessions'] as List<dynamic>? ?? [];
    return sessionsList
        .map((e) => ChatSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChatSessionDetailData> getSessionDetail(String sessionId) async {
    final options = await _authOptions();
    final response = await _dio.get(
      '${ApiConfig.aiSessionsEndpoint}/$sessionId',
      options: options,
    );
    final data = response.data as Map<String, dynamic>;
    final sessionJson = data['session'] as Map<String, dynamic>? ?? {};
    final messagesJson = data['messages'] as List<dynamic>? ?? [];

    return ChatSessionDetailData(
      session: ChatSessionModel.fromJson(sessionJson),
      messages:
          messagesJson
              .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  @override
  Future<ChatSessionModel> renameSession(String sessionId, String title) async {
    final options = await _authOptions();
    final response = await _dio.patch(
      '${ApiConfig.aiSessionsEndpoint}/$sessionId',
      data: {'title': title},
      options: options,
    );
    return ChatSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<bool> deleteSession(String sessionId) async {
    final options = await _authOptions();
    final response = await _dio.delete(
      '${ApiConfig.aiSessionsEndpoint}/$sessionId',
      options: options,
    );
    final data = response.data as Map<String, dynamic>;
    return data['deleted'] as bool? ?? false;
  }

  @override
  Future<bool> deleteMemory() async {
    final options = await _authOptions();
    final response = await _dio.delete(
      ApiConfig.aiMemoryEndpoint,
      options: options,
    );
    return response.statusCode == 200;
  }
}
