import 'package:dio/dio.dart' as dio;
import '../../domain/entities/payment_status.dart';
import '../../domain/failures/payment_failure.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/juspay_remote_data_source.dart';

class JuspayPaymentsRepositoryImpl implements PaymentsRepository {
  final JuspayRemoteDataSource _remoteDataSource;
  final Duration _pollInterval;

  JuspayPaymentsRepositoryImpl({
    required JuspayRemoteDataSource remoteDataSource,
    Duration pollInterval = const Duration(seconds: 2),
  })  : _remoteDataSource = remoteDataSource,
        _pollInterval = pollInterval;

  static const int _maxPollAttempts = 15;

  @override
  Future<PaymentStatus> fetchStatus(String reference) async {
    try {
      return await _remoteDataSource.fetchStatus(reference);
    } on dio.DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw PaymentFailure(
        type: PaymentFailureType.unknown,
        message: e.toString(),
      );
    }
  }

  @override
  Future<PaymentStatus> pollStatus(String reference) async {
    PaymentStatus? last;
    for (int i = 0; i < _maxPollAttempts; i++) {
      try {
        final status = await fetchStatus(reference);
        last = status;
        if (!status.isPending) {
          return status;
        }
      } catch (e) {
        // Log error and keep polling if not a terminal exception,
        // but if it's SSL pinning error or cancellation, propagate immediately
        if (e is PaymentFailure &&
            (e.type == PaymentFailureType.sslPinningError ||
                e.type == PaymentFailureType.paymentCancelled)) {
          rethrow;
        }
      }
      if (i < _maxPollAttempts - 1) {
        await Future.delayed(_pollInterval);
      }
    }
    return last ??
        const PaymentStatus(
          status: 'PENDING',
          respMessage: 'Still processing',
        );
  }

  @override
  Future<void> verifyPaymentResponse(String orderId) async {
    try {
      await _remoteDataSource.verifyJuspayResponse(orderId);
    } on dio.DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw PaymentFailure(
        type: PaymentFailureType.unknown,
        message: e.toString(),
      );
    }
  }

  PaymentFailure _mapDioException(dio.DioException e) {
    final msg = e.message ?? '';
    final errorString = e.error?.toString() ?? '';
    
    if (msg.contains('Certificate pinning') ||
        errorString.contains('Certificate pinning')) {
      return PaymentFailure(
        type: PaymentFailureType.sslPinningError,
        message: 'Secure connection verification failed. Potential security risk.',
      );
    }
    
    if (e.type == dio.DioExceptionType.cancel) {
      return const PaymentFailure(
        type: PaymentFailureType.paymentCancelled,
        message: 'Payment was cancelled.',
      );
    }

    return PaymentFailure(
      type: PaymentFailureType.networkError,
      message: 'Network error communicating with payment gateway: $msg',
    );
  }
}
