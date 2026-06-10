import 'package:dio/dio.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/utils/app_logger.dart';

import 'package:grocery_app/service_locator.dart';

class ApiClient {
  ApiClient._privateConstructor() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: ApiConfig.getBaseHeaders(),
    ));

    _dio.interceptors.add(AuthInterceptor());
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
