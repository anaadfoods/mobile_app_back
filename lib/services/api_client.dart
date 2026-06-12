import 'package:dio/dio.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/utils/app_logger.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/services/connectivity_service.dart';
import 'package:grocery_app/helpers/cache_helper.dart';

class ApiClient {
  ApiClient._privateConstructor() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: ApiConfig.getBaseHeaders(),
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(),
      CacheInterceptor(),
      RetryInterceptor(dio: _dio),
    ]);
  }

  static ApiClient get instance => getIt<ApiClient>();
  static ApiClient create() => ApiClient._privateConstructor();

  late final Dio _dio;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
}

class AuthInterceptor extends Interceptor {
  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _requestQueue = [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    final isPublic = path.contains(ApiConfig.loginEndpoint) ||
        path.contains(ApiConfig.registerEndpoint) ||
        path.contains(ApiConfig.refreshEndpoint) ||
        path.contains(ApiConfig.sendOtpEndpoint) ||
        path.contains('/api/auth/verify-otp/') ||
        path.contains('/forgot-password/');

    if (!isPublic) {
      final token = await TokenService().getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final options = err.requestOptions;

      // If it is the refresh endpoint itself failing, do not retry
      if (options.path.contains(ApiConfig.refreshEndpoint)) {
        return handler.next(err);
      }

      if (_isRefreshing) {
        _requestQueue.add({
          'options': options,
          'handler': handler,
        });
        return;
      }

      _isRefreshing = true;
      try {
        final success = await TokenService().refreshAccessToken();
        if (success) {
          final token = await TokenService().getAccessToken();
          
          // Re-issue current request
          options.headers['Authorization'] = 'Bearer $token';
          final response = await ApiClient.instance.dio.fetch(options);
          handler.resolve(response);

          // Re-issue queued requests
          for (final request in _requestQueue) {
            final reqOptions = request['options'] as RequestOptions;
            final reqHandler = request['handler'] as ErrorInterceptorHandler;
            reqOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final resp = await ApiClient.instance.dio.fetch(reqOptions);
              reqHandler.resolve(resp);
            } catch (e) {
              if (e is DioException) {
                reqHandler.next(e);
              } else {
                reqHandler.reject(DioException(requestOptions: reqOptions, error: e));
              }
            }
          }
          _requestQueue.clear();
          return;
        } else {
          await TokenService().logout();
        }
      } catch (e) {
        AppLogger.instance.log('AuthInterceptor error during token refresh: $e');
        await TokenService().logout();
      } finally {
        _isRefreshing = false;
      }
    }
    return handler.next(err);
  }
}

/// CacheInterceptor caches GET responses and returns them when offline or when the server is down.
class CacheInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only cache GET requests
    if (options.method != 'GET') {
      return handler.next(options);
    }

    try {
      final hasNet = await ConnectivityService().hasConnection;
      if (!hasNet) {
        final cacheKey = _getCacheKey(options);
        final cachedData = await CacheHelper.get(cacheKey);
        if (cachedData != null) {
          AppLogger.instance.log(
            'Offline Mode: Serving cached response for: ${options.path}'
          );
          return handler.resolve(
            Response(
              requestOptions: options,
              data: cachedData,
              statusCode: 200,
              statusMessage: 'OK (From Local Offline Cache)',
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.instance.log('CacheInterceptor onRequest error: $e');
    }
    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.requestOptions.method == 'GET' && response.statusCode == 200 && response.data != null) {
      try {
        final cacheKey = _getCacheKey(response.requestOptions);
        // Save data asynchronously to not block response delivery
        CacheHelper.set(cacheKey, response.data);
      } catch (e) {
        AppLogger.instance.log('CacheInterceptor onResponse error: $e');
      }
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.requestOptions.method == 'GET') {
      try {
        final cacheKey = _getCacheKey(err.requestOptions);
        final cachedData = await CacheHelper.get(cacheKey);
        if (cachedData != null) {
          AppLogger.instance.log(
            'Server Error/Unreachable: Falling back to local cache for: ${err.requestOptions.path}'
          );
          return handler.resolve(
            Response(
              requestOptions: err.requestOptions,
              data: cachedData,
              statusCode: 200,
              statusMessage: 'OK (Fallback to Local Cache)',
            ),
          );
        }
      } catch (e) {
        AppLogger.instance.log('CacheInterceptor onError fallback error: $e');
      }
    }
    return handler.next(err);
  }

  String _getCacheKey(RequestOptions options) {
    final queryStr = options.queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return 'api_cache_${options.path}_$queryStr';
  }
}

/// RetryInterceptor automatically retries transiently failing HTTP requests with exponential backoff.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryInterval;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 1),
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    var extra = err.requestOptions.extra;
    var retryCount = extra['retry_count'] as int? ?? 0;

    if (_isRetryable(err) && retryCount < maxRetries) {
      retryCount++;
      extra['retry_count'] = retryCount;

      final delay = retryInterval * (1 << (retryCount - 1));
      AppLogger.instance.log(
        'Transient connection error: ${err.type} (${err.message}). '
        'Retrying request ($retryCount/$maxRetries) in ${delay.inMilliseconds}ms: '
        '${err.requestOptions.method} ${err.requestOptions.path}'
      );

      await Future.delayed(delay);

      try {
        final response = await dio.request(
          err.requestOptions.path,
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
          cancelToken: err.requestOptions.cancelToken,
          options: Options(
            method: err.requestOptions.method,
            headers: err.requestOptions.headers,
            extra: extra,
            responseType: err.requestOptions.responseType,
            contentType: err.requestOptions.contentType,
            validateStatus: err.requestOptions.validateStatus,
            receiveTimeout: err.requestOptions.receiveTimeout,
            sendTimeout: err.requestOptions.sendTimeout,
          ),
          onSendProgress: err.requestOptions.onSendProgress,
          onReceiveProgress: err.requestOptions.onReceiveProgress,
        );
        return handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          err = e;
        } else {
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: e,
            ),
          );
        }
      }
    }

    return handler.next(err);
  }

  bool _isRetryable(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    if (err.type == DioExceptionType.connectionError) {
      return true;
    }
    if (err.error != null && err.error.toString().toLowerCase().contains('socketexception')) {
      return true;
    }
    if (err.type == DioExceptionType.badResponse) {
      final status = err.response?.statusCode;
      if (status == 502 || status == 503 || status == 504) {
        return true;
      }
    }
    return false;
  }
}
