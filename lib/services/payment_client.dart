import 'package:dio/dio.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/utils/app_logger.dart';
import 'package:grocery_app/service_locator.dart';

/// Specialized HTTP client for payment operations with certificate pinning.
///
/// This client is used exclusively for Juspay payment bridge communications.
/// It implements SSL/TLS certificate pinning to prevent MITM attacks on financial endpoints.
class PaymentClient {
  PaymentClient._privateConstructor() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.paymentUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: ApiConfig.getBaseHeaders(),
      ),
    );

    _dio.interceptors.add(PaymentAuthInterceptor());
    _dio.interceptors.add(CertificatePinningInterceptor());
  }

  static PaymentClient get instance => getIt<PaymentClient>();
  static PaymentClient create() => PaymentClient._privateConstructor();

  late final Dio _dio;

  Dio get dio => _dio;

  /// POST request for payment operations
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

  /// GET request for payment operations
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
}

/// Interceptor for payment authentication
/// Adds authorization headers to payment requests
class PaymentAuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await getIt<TokenService>().getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    AppLogger.instance.log('Payment request error: ${err.message}');
    return handler.next(err);
  }
}

/// Interceptor implementing certificate pinning for payment endpoints
///
/// Certificate pinning ensures that the app only communicates with the legitimate
/// payment server by verifying the SSL certificate against a known good certificate.
class CertificatePinningInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // For development/testing, you can disable pinning by checking an env var
      // In production, always enforce pinning
      await _verifyCertificate(options.uri.host);
      return handler.next(options);
    } catch (e) {
      AppLogger.instance.log('Certificate pinning verification failed: $e');
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'Certificate pinning verification failed: $e',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  /// Verify certificate using http_certificate_pinning
  Future<void> _verifyCertificate(String host) async {
    final allowlist = ApiConfig.paymentCertificateSha256Pins;
    if (allowlist.isEmpty) {
      throw StateError(
        'PAYMENT_CERT_SHA256_PINS must contain at least one SHA256 pin for $host',
      );
    }

    try {
      final result = await HttpCertificatePinning.check(
        serverURL: ApiConfig.paymentUrl,
        sha: SHA.SHA256,
        allowedSHAFingerprints: allowlist,
        headerHttp: {"Content-Type": "application/json"},
        timeout: 60,
      );

      if (!result.contains('CONNECTION_SECURE')) {
        throw Exception('Certificate verification failed: $result');
      }

      AppLogger.instance.log(
        'Certificate pinning verification succeeded for $host',
      );
    } catch (e) {
      AppLogger.instance.log('Certificate pinning error: $e');
      rethrow;
    }
  }
}
