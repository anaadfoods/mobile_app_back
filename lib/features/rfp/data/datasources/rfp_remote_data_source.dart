import 'package:dio/dio.dart';
import '../../../../services/api_client.dart';
import '../../../../services/api_config.dart';
import '../../../../services/api_exception.dart';
import '../../../../utils/app_logger.dart';
import '../models/rfp_batch_model.dart';
import '../models/rfp_pricing_model.dart';
import '../models/rfp_booking_model.dart';
import '../models/rfp_delivery_otp_status_model.dart';
import '../models/user_address_model.dart';

/// Remote data source interface for the RFP subscription feature.
abstract class RfpRemoteDataSource {
  /// Fetch all active and upcoming farming batches with nested plans and pricing.
  Future<List<RfpBatchModel>> getActiveBatches();

  /// Fetch full batch details including plans, available vegetables, and pricings.
  Future<RfpBatchModel> getBatchDetail(int batchId);

  /// Calculate quote breakdown for a bundle selection without modifying the database.
  Future<RfpPricingModel> calculateSubscription({
    required int batchId,
    required List<String> deliveryDays,
    required List<Map<String, dynamic>> plans,
  });

  /// Book an RFP subscription and initiate payment checkout session.
  Future<Map<String, dynamic>> bookSubscription({
    required int batchId,
    required List<String> deliveryDays,
    required List<Map<String, dynamic>> plans,
    String paymentType = 'booking',
    int? addressId,
  });

  /// Reconcile payment transaction with gateway.
  Future<Map<String, dynamic>> verifyPayment({
    required String merchantTransactionId,
  });

  /// Fetch the authenticated user's subscriptions and scheduled deliveries.
  Future<List<RfpBookingModel>> getMySubscriptions();

  /// Initiate checkout session for the remaining balance of a subscription.
  Future<Map<String, dynamic>> payRemaining({required int subscriptionId});

  /// Fetch saved delivery addresses for the authenticated user.
  Future<List<UserAddressModel>> getUserAddresses();

  /// Create and persist a new delivery address for the authenticated user.
  Future<UserAddressModel> createUserAddress(Map<String, dynamic> addressData);

  /// Fetch delivery OTP status for an active RFP delivery.
  Future<RfpDeliveryOtpStatusModel> getDeliveryOtpStatus(int deliveryId);
}

class RfpRemoteDataSourceImpl implements RfpRemoteDataSource {
  final ApiClient _apiClient;

  RfpRemoteDataSourceImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        if (data['error_code'] != null) {
          final code = data['error_code'].toString();
          final msg = data['error']?.toString() ?? data['message']?.toString();
          return msg != null && msg.isNotEmpty ? '[$code] $msg' : code;
        }
        if (data['error'] != null && data['error'].toString().isNotEmpty) {
          return data['error'].toString();
        }
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          return data['message'].toString();
        }
        if (data['detail'] != null && data['detail'].toString().isNotEmpty) {
          return data['detail'].toString();
        }
        if (data['code'] != null && data['code'].toString().isNotEmpty) {
          return data['code'].toString();
        }
        if (data['non_field_errors'] is List &&
            (data['non_field_errors'] as List).isNotEmpty) {
          return (data['non_field_errors'] as List).first.toString();
        }
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    }
    return e.toString();
  }

  @override
  Future<List<RfpBatchModel>> getActiveBatches() async {
    try {
      final response = await _apiClient.get(ApiConfig.rfpActiveBatchesEndpoint);
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List<dynamic>;
        return list
            .map((item) => RfpBatchModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw ApiException(
        'Failed to load active RFP batches',
        response.statusCode ?? 500,
      );
    } catch (e) {
      AppLogger.instance.log('RfpRemoteDataSource.getActiveBatches error: $e');
      if (e is ApiException) rethrow;
      throw Exception(_extractError(e));
    }
  }

  @override
  Future<RfpBatchModel> getBatchDetail(int batchId) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.rfpBatchDetailEndpoint(batchId),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return RfpBatchModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ApiException(
        'Failed to load RFP batch detail for batch $batchId',
        response.statusCode ?? 500,
      );
    } catch (e) {
      AppLogger.instance.log('RfpRemoteDataSource.getBatchDetail error: $e');
      if (e is ApiException) rethrow;
      throw Exception(_extractError(e));
    }
  }

  @override
  Future<RfpPricingModel> calculateSubscription({
    required int batchId,
    required List<String> deliveryDays,
    required List<Map<String, dynamic>> plans,
  }) async {
    try {
      final payload = {
        'batch_id': batchId,
        'delivery_days': deliveryDays,
        'plans': plans,
      };

      final response = await _apiClient.post(
        ApiConfig.rfpCalculateEndpoint,
        data: payload,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final map = response.data as Map<String, dynamic>;
        if (map['success'] == false && map['error'] != null) {
          throw ApiException(map['error'].toString(), 400);
        }
        return RfpPricingModel.fromJson(map);
      }
      throw ApiException(
        'Failed to calculate RFP pricing',
        response.statusCode ?? 500,
      );
    } catch (e) {
      AppLogger.instance.log(
        'RfpRemoteDataSource.calculateSubscription error: $e',
      );
      if (e is ApiException) rethrow;
      throw Exception(_extractError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> bookSubscription({
    required int batchId,
    required List<String> deliveryDays,
    required List<Map<String, dynamic>> plans,
    String paymentType = 'booking',
    int? addressId,
  }) async {
    try {
      final payload = {
        'batch_id': batchId,
        'delivery_days': deliveryDays,
        'plans': plans,
        'payment_type': paymentType,
        if (addressId != null) 'address_id': addressId,
      };

      final response = await _apiClient.post(
        ApiConfig.rfpBookEndpoint,
        data: payload,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw ApiException(
        'Failed to book RFP subscription',
        response.statusCode ?? 500,
      );
    } catch (e) {
      AppLogger.instance.log('RfpRemoteDataSource.bookSubscription error: $e');
      if (e is ApiException) rethrow;
      throw Exception(_extractError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> verifyPayment({
    required String merchantTransactionId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.rfpVerifyPaymentEndpoint,
        data: {'merchant_transaction_id': merchantTransactionId},
      );

      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw ApiException(
        'Failed to verify payment',
        response.statusCode ?? 500,
      );
    } catch (e) {
      AppLogger.instance.log('RfpRemoteDataSource.verifyPayment error: $e');
      if (e is ApiException) rethrow;
      throw Exception(_extractError(e));
    }
  }

  @override
  Future<List<RfpBookingModel>> getMySubscriptions() async {
    try {
      final response = await _apiClient.get(
        ApiConfig.rfpMySubscriptionsEndpoint,
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List<dynamic>;
        return list
            .map(
              (item) => RfpBookingModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      throw ApiException(
        'Failed to load user subscriptions',
        response.statusCode ?? 500,
      );
    } catch (e) {
      AppLogger.instance.log(
        'RfpRemoteDataSource.getMySubscriptions error: $e',
      );
      if (e is ApiException) rethrow;
      throw Exception(_extractError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> payRemaining({
    required int subscriptionId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.rfpPayRemainingEndpoint(subscriptionId),
      );

      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw ApiException(
        'Failed to initiate remaining payment',
        response.statusCode ?? 500,
      );
    } catch (e) {
      AppLogger.instance.log('RfpRemoteDataSource.payRemaining error: $e');
      if (e is ApiException) rethrow;
      throw Exception(_extractError(e));
    }
  }

  @override
  Future<List<UserAddressModel>> getUserAddresses() async {
    try {
      final response = await _apiClient.get(ApiConfig.userAddressesEndpoint);
      if (response.statusCode == 200) {
        if (response.data is List) {
          return (response.data as List<dynamic>)
              .map(
                (item) =>
                    UserAddressModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        } else if (response.data is Map<String, dynamic>) {
          final map = response.data as Map<String, dynamic>;
          final list = map['results'] ?? map['data'] ?? map['addresses'];
          if (list is List) {
            return list
                .map(
                  (item) =>
                      UserAddressModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
        }
      }
      return const [];
    } catch (e) {
      AppLogger.instance.log('RfpRemoteDataSource.getUserAddresses error: $e');
      return const [];
    }
  }

  @override
  Future<UserAddressModel> createUserAddress(
    Map<String, dynamic> addressData,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.userAddressesEndpoint,
        data: addressData,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map) {
        return UserAddressModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      throw ApiException(
        'Failed to save delivery address',
        response.statusCode ?? 500,
      );
    } catch (e) {
      AppLogger.instance.log('RfpRemoteDataSource.createUserAddress error: $e');
      if (e is ApiException) rethrow;
      throw Exception(_extractError(e));
    }
  }

  @override
  Future<RfpDeliveryOtpStatusModel> getDeliveryOtpStatus(int deliveryId) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.rfpDeliveryOtpStatusEndpoint(deliveryId),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return RfpDeliveryOtpStatusModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      return const RfpDeliveryOtpStatusModel(state: 'NO_ACTIVE_OTP');
    } catch (e) {
      AppLogger.instance.log(
        'RfpRemoteDataSource.getDeliveryOtpStatus error: $e',
      );
      return const RfpDeliveryOtpStatusModel(state: 'NO_ACTIVE_OTP');
    }
  }
}
