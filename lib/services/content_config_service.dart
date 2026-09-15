import 'package:dio/dio.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/utils/app_logger.dart';

/// Service for fetching admin-configurable content from the backend.
/// All methods use network-first with hardcoded fallback strategy.
class ContentConfigService {
  static final ContentConfigService _instance =
      ContentConfigService._internal();
  factory ContentConfigService() => _instance;
  ContentConfigService._internal();
  static ContentConfigService create() => ContentConfigService._internal();

  final Map<String, List<Map<String, dynamic>>> _encyclopediaCache = {};

  /// Get encyclopedia entries with in-memory caching
  Future<List<Map<String, dynamic>>> getEncyclopediaCategory({
    required String endpoint,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _encyclopediaCache.containsKey(endpoint)) {
      return _encyclopediaCache[endpoint]!;
    }
    final data = await fetchEncyclopedia(endpoint: endpoint);
    if (data.isNotEmpty) {
      _encyclopediaCache[endpoint] = data;
    }
    return data.isNotEmpty ? data : (_encyclopediaCache[endpoint] ?? []);
  }

  /// Fetch agent tool definitions from backend.
  /// Returns list of maps with keys: trigger, alias, name_en, default_query_en, order
  Future<List<Map<String, dynamic>>> fetchAgentTools({
    required String token,
  }) async {
    try {
      final response = await ApiClient.instance.get(
        ApiConfig.agentToolsEndpoint,
        options: Options(
          headers: ApiConfig.getAuthHeaders(token),
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      AppLogger.warn('ContentConfigService', 'fetchAgentTools failed: $e');
    }
    return [];
  }

  /// Fetch suggested prompts from backend.
  /// Returns list of maps with keys: code, title_template_en, query_template_en,
  /// context_required, requires_health_profile, order
  Future<List<Map<String, dynamic>>> fetchSuggestedPrompts({
    required String token,
  }) async {
    try {
      final response = await ApiClient.instance.get(
        ApiConfig.suggestedPromptsEndpoint,
        options: Options(
          headers: ApiConfig.getAuthHeaders(token),
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      AppLogger.warn(
          'ContentConfigService', 'fetchSuggestedPrompts failed: $e');
    }
    return [];
  }

  /// Fetch content blocks for a specific screen from backend.
  /// Returns list of maps with keys: screen, block_key, content_en, content_hi, metadata, order
  Future<List<Map<String, dynamic>>> fetchContentBlocks({
    required String token,
    required String screen,
  }) async {
    try {
      final response = await ApiClient.instance.get(
        ApiConfig.contentBlocksEndpoint,
        queryParameters: {'screen': screen},
        options: Options(
          headers: ApiConfig.getAuthHeaders(token),
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      AppLogger.warn(
          'ContentConfigService', 'fetchContentBlocks failed: $e');
    }
    return [];
  }

  /// Fetch preset locations from backend.
  /// Returns list of maps with keys: name, latitude, longitude, timezone, order
  Future<List<Map<String, dynamic>>> fetchPresetLocations() async {
    try {
      final response = await ApiClient.instance.get(
        '${ApiConfig.panchangBaseUrl}${ApiConfig.panchangPresetLocations}',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      AppLogger.warn(
          'ContentConfigService', 'fetchPresetLocations failed: $e');
    }
    return [];
  }

  /// Fetch encyclopedia entries by category endpoint.
  /// [endpoint] should be one of the ApiConfig.encyclopedia* constants.
  Future<List<Map<String, dynamic>>> fetchEncyclopedia({
    required String endpoint,
  }) async {
    try {
      final response = await ApiClient.instance.get(
        '${ApiConfig.panchangBaseUrl}$endpoint',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      AppLogger.warn('ContentConfigService', 'fetchEncyclopedia failed: $e');
    }
    return [];
  }

  /// Fetch guidance profile form options from backend.
  /// Returns map with keys: diet_styles, fasting_preferences, devatas,
  /// calendar_profiles, locales — each a list of {value, label} maps.
  Future<Map<String, dynamic>?> fetchGuidanceOptions() async {
    try {
      final response = await ApiClient.instance.get(
        '${ApiConfig.panchangBaseUrl}${ApiConfig.panchangGuidanceOptions}',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      AppLogger.warn(
          'ContentConfigService', 'fetchGuidanceOptions failed: $e');
    }
    return null;
  }
}
