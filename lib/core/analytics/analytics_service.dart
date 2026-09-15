import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grocery_app/services/notification_service.dart';
import 'package:path_provider/path_provider.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late Dio _dio;

  String _sutraBaseUrl = 'http://127.0.0.1:8010';
  String _anaadBaseUrl = 'http://127.0.0.1:8000';

  String? _anonymousId;
  int? _authenticatedUserId;
  String? _deviceId;
  String? _sessionId;
  String? _currentScreen = 'Home';
  String? _telemetryToken;
  DateTime? _telemetryTokenExpiresAt;
  DateTime? _lastActivityTime;
  Timer? _flushTimer;
  bool _isFlushing = false;

  static const Duration _sessionTimeout = Duration(minutes: 30);
  static const Duration _flushInterval = Duration(seconds: 15);

  /// Initializes the analytics engine with API clients and persistent device identity.
  Future<void> initialize({
    required Dio dio,
    String? sutraBaseUrl,
    String? anaadBaseUrl,
  }) async {
    _dio = dio;
    if (sutraBaseUrl != null) _sutraBaseUrl = sutraBaseUrl;
    if (anaadBaseUrl != null) _anaadBaseUrl = anaadBaseUrl;

    await _initIdentity();
    _startNewSession();

    // Auto-flush queue periodically
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
  }

  Future<void> _initIdentity() async {
    _anonymousId = await _storage.read(key: 'anaad_analytics_anon_id');
    if (_anonymousId == null) {
      _anonymousId = _generateUuidV4();
      await _storage.write(key: 'anaad_analytics_anon_id', value: _anonymousId);
    }
    try {
      _deviceId = await NotificationService.getDeviceId();
    } catch (e) {
      debugPrint('Device ID initialization skipped: $e');
    }
  }

  /// Sets the canonical authenticated user identity on login or app start.
  void identify(int userId) {
    _authenticatedUserId = userId;
    try {
      FirebaseAnalytics.instance.setUserId(id: userId.toString());
    } catch (e) {
      debugPrint('Firebase setUserId error: $e');
    }
    _getValidTelemetryToken().then((_) {
      _sendIdentityAlias(userId);
    });
  }

  /// Explicitly aliases anonymous installation identity to canonical authenticated user.
  Future<void> _sendIdentityAlias(int userId) async {
    if (_anonymousId == null) return;
    try {
      final telemetryToken = await _getValidTelemetryToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (telemetryToken != null) {
        headers['Authorization'] = 'Bearer $telemetryToken';
      }
      await _dio.post(
        '$_sutraBaseUrl/api/analytics/alias/',
        data: {
          'anonymous_id': _anonymousId,
          'user_id': userId,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'device_id': _deviceId,
        },
        options: Options(headers: headers),
      );
    } catch (e) {
      debugPrint('Identity alias dispatch deferred: $e');
    }
  }

  /// Clears authenticated identity on logout.
  void clearIdentity() {
    _authenticatedUserId = null;
    _telemetryToken = null;
    _telemetryTokenExpiresAt = null;
    try {
      FirebaseAnalytics.instance.setUserId(id: null);
    } catch (e) {
      debugPrint('Firebase clearUserId error: $e');
    }
    _startNewSession();
  }

  int? get authenticatedUserId => _authenticatedUserId;
  String? get anonymousId => _anonymousId;
  String? get deviceId => _deviceId;
  String? get sessionId => _sessionId;
  String? get currentScreen => _currentScreen;
  set currentScreen(String? val) {
    if (val != null && val.isNotEmpty && val != '{}') {
      _currentScreen = val;
    }
  }

  void dispose() {
    _flushTimer?.cancel();
  }

  void _startNewSession() {
    _sessionId = _generateUuidV4();
    _lastActivityTime = DateTime.now();
    trackEvent(
      eventName: 'session_started',
      feature: 'app_lifecycle',
      properties: {
        'session_id': _sessionId,
        'element_text': 'App Launched',
        'target_element': 'App Launched',
      },
    );
  }

  void _checkSessionLiveness() {
    final now = DateTime.now();
    if (_lastActivityTime != null && now.difference(_lastActivityTime!) > _sessionTimeout) {
      _startNewSession();
    }
    _lastActivityTime = now;
  }

  /// Refreshes short-lived telemetry token from Anaad Django if expired or missing.
  Future<String?> _getValidTelemetryToken() async {
    final now = DateTime.now();
    if (_telemetryToken != null &&
        _telemetryTokenExpiresAt != null &&
        _telemetryTokenExpiresAt!.isAfter(now.add(const Duration(minutes: 1)))) {
      return _telemetryToken;
    }

    try {
      final anaadAuthToken = await _storage.read(key: 'access_token');
      if (anaadAuthToken == null) return null;

      final resp = await _dio.post(
        '$_anaadBaseUrl/api/auth/telemetry-token/',
        options: Options(headers: {
          'Authorization': 'Bearer $anaadAuthToken',
          'Content-Type': 'application/json',
        }),
      );

      if (resp.statusCode == 200 && resp.data != null) {
        _telemetryToken = resp.data['token'];
        final expStr = resp.data['expires_at'];
        if (expStr != null) {
          _telemetryTokenExpiresAt = DateTime.tryParse(expStr);
        } else {
          _telemetryTokenExpiresAt = now.add(const Duration(minutes: 14));
        }
        return _telemetryToken;
      }
    } catch (e) {
      debugPrint('Telemetry token acquisition skipped/failed: $e');
    }
    return null;
  }

  /// Records a user click / tap action on a button, card, or interactive element.
  Future<void> trackClick({
    required String elementText,
    String? screen,
    String? componentName,
    String? feature,
    Map<String, dynamic>? properties,
    bool immediateFlush = true,
  }) async {
    final effectiveScreen = screen ?? _currentScreen ?? 'App';
    final props = <String, dynamic>{
      'element_text': elementText,
      'target_element': elementText,
      'component_name': componentName ?? elementText,
      'screen_name': effectiveScreen,
      ...?properties,
    };
    await trackEvent(
      eventName: 'ui_click',
      feature: feature ?? 'ui_interaction',
      screen: effectiveScreen,
      properties: props,
      immediateFlush: immediateFlush,
    );
  }

  /// Core tracking method callable from Cubits, screens, and route observers.
  Future<void> trackEvent({
    required String eventName,
    required String feature,
    String? screen,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? context,
    bool immediateFlush = false,
  }) async {
    _checkSessionLiveness();

    if (screen != null && screen.isNotEmpty && screen != '{}') {
      _currentScreen = screen;
    } else {
      screen = _currentScreen ?? 'App';
    }

    final props = Map<String, dynamic>.from(properties ?? {});
    final target = props['element_text'] ??
        props['target_element'] ??
        props['product_name'] ??
        props['component_name'] ??
        props['query'];
    if (target != null) {
      props['element_text'] ??= target;
      props['target_element'] ??= target;
    }

    final eventId = _generateUuidV4();
    final eventPayload = {
      'event_id': eventId,
      'event_name': eventName,
      'event_version': '1.0.0',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'session_id': _sessionId,
      'anonymous_id': _anonymousId,
      'user_id': _authenticatedUserId,
      'device_id': _deviceId,
      'source': 'frontend',
      'platform': Platform.isIOS ? 'ios' : 'android',
      'application': 'anaad_flutter',
      'environment': kReleaseMode ? 'production' : 'development',
      'app_version': '2.2.0',
      'app_build_number': 4,
      'screen': screen,
      'feature': feature,
      'properties': props,
      'context': context ?? {},
    };

    // 1. Durably append to offline queue for Sutra
    await _enqueueEvent(eventPayload);

    // 2. Dual-dispatch product behavioral events to Firebase Analytics
    try {
      final sanitizedProps = <String, Object>{};
      if (properties != null) {
        properties.forEach((k, v) {
          if (v is String || v is num) {
            sanitizedProps[k] = v;
          } else if (v != null) {
            sanitizedProps[k] = v.toString();
          }
        });
      }
      FirebaseAnalytics.instance.logEvent(
        name: eventName,
        parameters: sanitizedProps.isNotEmpty ? sanitizedProps : null,
      );
    } catch (e) {
      debugPrint('Firebase logEvent error: $e');
    }

    // 3. High-impact friction events trigger immediate dispatch
    if (immediateFlush || eventName == 'payment_transaction_failed' || eventName == 'checkout_coupon_failed') {
      flush();
    }
  }

  /// Flushes buffered events to Sutra Backend.
  Future<void> flush() async {
    if (_isFlushing) return;
    _isFlushing = true;

    try {
      final events = await _readQueuedEvents();
      if (events.isEmpty) {
        _isFlushing = false;
        return;
      }

      // Take up to 50 events in a batch
      final batch = events.take(50).toList();
      final batchEventIds = batch.map((e) => e['event_id'].toString()).toSet();

      final telemetryToken = await _getValidTelemetryToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      final endpoint = telemetryToken != null
          ? '$_sutraBaseUrl/api/analytics/events/'
          : '$_sutraBaseUrl/api/analytics/events/anonymous/';

      if (telemetryToken != null) {
        headers['Authorization'] = 'Bearer $telemetryToken';
      }

      final response = await _dio.post(
        endpoint,
        data: batch,
        options: Options(headers: headers),
      );

      if (response.statusCode == 202) {
        // Remove successfully acknowledged events
        final remaining = events.where((e) => !batchEventIds.contains(e['event_id'].toString())).toList();
        await _writeQueuedEvents(remaining);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Invalidate cached token so fresh RS256 token will be requested
        _telemetryToken = null;
        _telemetryTokenExpiresAt = null;
      }
      debugPrint('Sutra analytics batch dispatch deferred: $e');
    } catch (e) {
      debugPrint('Sutra analytics batch dispatch deferred: $e');
    } finally {
      _isFlushing = false;
    }
  }

  Future<File> _getQueueFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/anaad_telemetry_queue.json');
  }

  Future<List<Map<String, dynamic>>> _readQueuedEvents() async {
    try {
      final file = await _getQueueFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is List) {
            return decoded.cast<Map<String, dynamic>>();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed reading telemetry queue: $e');
    }
    return [];
  }

  Future<void> _writeQueuedEvents(List<Map<String, dynamic>> events) async {
    try {
      final file = await _getQueueFile();
      await file.writeAsString(jsonEncode(events));
    } catch (e) {
      debugPrint('Failed writing telemetry queue: $e');
    }
  }

  Future<void> _enqueueEvent(Map<String, dynamic> event) async {
    final events = await _readQueuedEvents();
    events.add(event);
    // Limit queue size to 2,000 events to prevent unbounded disk growth
    if (events.length > 2000) {
      events.removeRange(0, events.length - 2000);
    }
    await _writeQueuedEvents(events);
  }

  String _generateUuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
