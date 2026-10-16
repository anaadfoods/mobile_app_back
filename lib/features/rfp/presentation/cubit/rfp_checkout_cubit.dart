import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/rfp_booking.dart';
import '../../domain/entities/rfp_patch_config.dart';
import '../../domain/entities/user_address.dart';
import '../../domain/usecases/create_booking_use_case.dart';
import '../../domain/usecases/calculate_pricing_use_case.dart';
import '../../domain/usecases/verify_rfp_payment_use_case.dart';
import '../../domain/usecases/get_user_addresses_use_case.dart';
import '../../domain/usecases/save_user_address_use_case.dart';
import '../../../../services/token_service.dart';
import 'rfp_checkout_state.dart';

export 'rfp_checkout_state.dart';

// ─── Cubit ─────────────────────────────────────────────────────────────────

class RfpCheckoutCubit extends Cubit<RfpCheckoutState> {
  final CreateBookingUseCase _createBooking;
  final CalculatePricingUseCase _calculatePricing;
  final VerifyRfpPaymentUseCase? _verifyPayment;
  final GetUserAddressesUseCase? _getUserAddresses;
  final SaveUserAddressUseCase? _saveUserAddress;

  RfpCheckoutCubit({
    required CreateBookingUseCase createBooking,
    required CalculatePricingUseCase calculatePricing,
    VerifyRfpPaymentUseCase? verifyPayment,
    GetUserAddressesUseCase? getUserAddresses,
    SaveUserAddressUseCase? saveUserAddress,
  }) : _createBooking = createBooking,
       _calculatePricing = calculatePricing,
       _verifyPayment = verifyPayment,
       _getUserAddresses = getUserAddresses,
       _saveUserAddress = saveUserAddress,
       super(const RfpCheckoutState());

  /// Load user's saved addresses from backend, pre-populating with default/most recent.
  Future<void> loadSavedAddresses() async {
    emit(state.copyWith(isLoadingAddresses: true));
    try {
      List<UserAddress> addresses = [];
      if (_getUserAddresses != null) {
        addresses = await _getUserAddresses();
      }

      if (addresses.isNotEmpty) {
        // Find default or first saved address
        final selected = addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => addresses.first,
        );

        emit(
          state.copyWith(
            isLoadingAddresses: false,
            savedAddresses: addresses,
            addressId: selected.id,
            fullName: selected.fullName,
            addressLine: selected.formattedAddress,
            city: selected.city,
            state: selected.state,
            pincode: selected.pincode,
            phone: selected.phoneNumber,
          ),
        );
        return;
      }

      // Fallback: Populate from TokenService user profile if state is empty
      final user = TokenService().currentUser;
      if (user != null && state.fullName.isEmpty) {
        final name = '${user.firstName} ${user.lastName}'.trim();
        emit(
          state.copyWith(
            isLoadingAddresses: false,
            savedAddresses: const [],
            fullName: name.isNotEmpty ? name : user.username,
            addressLine: user.address ?? '',
            city: user.city ?? '',
            state: user.state ?? '',
            pincode: user.pincode ?? '',
            phone: user.phoneNumber,
          ),
        );
        return;
      }

      emit(state.copyWith(isLoadingAddresses: false));
    } catch (_) {
      emit(state.copyWith(isLoadingAddresses: false));
    }
  }

  /// Select a saved address by its UserAddress entity.
  void selectSavedAddress(UserAddress address) {
    emit(
      state.copyWith(
        addressId: address.id,
        fullName: address.fullName,
        addressLine: address.formattedAddress,
        city: address.city,
        state: address.state,
        pincode: address.pincode,
        phone: address.phoneNumber,
      ),
    );
  }

  Future<void> loadPricing({
    required String planId,
    required List<RfpPatchConfig> patchConfigs,
  }) async {
    emit(state.copyWith(status: CheckoutStatus.loading));
    try {
      final pricing = await _calculatePricing(
        planId: planId,
        patchConfigs: patchConfigs,
      );
      emit(state.copyWith(status: CheckoutStatus.loaded, pricing: pricing));
    } catch (e) {
      emit(state.copyWith(status: CheckoutStatus.error, error: e.toString()));
    }
  }

  void selectPaymentMethod(String method) {
    emit(state.copyWith(selectedPaymentMethod: method));
  }

  void selectPaymentType(String type) {
    emit(state.copyWith(paymentType: type));
  }

  void updateAddress({
    String? fullName,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
    String? phone,
    int? addressId,
  }) {
    emit(
      this.state.copyWith(
        fullName: fullName,
        addressLine: addressLine,
        city: city,
        state: state,
        pincode: pincode,
        phone: phone,
        addressId: addressId,
      ),
    );
  }

  /// Save a new delivery address to the backend and activate it for checkout.
  Future<void> saveNewAddress({
    required String fullName,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    required String phone,
    String label = 'HOME',
    bool isDefault = false,
  }) async {
    emit(this.state.copyWith(isLoadingAddresses: true));
    try {
      if (_saveUserAddress != null) {
        final newAddr = UserAddress(
          id: 0,
          label: label,
          fullName: fullName,
          phoneNumber: phone,
          addressLine1: addressLine,
          city: city,
          state: state,
          pincode: pincode,
          isDefault: isDefault,
        );
        final saved = await _saveUserAddress(newAddr);
        final updatedList = [...this.state.savedAddresses, saved];
        emit(
          this.state.copyWith(
            isLoadingAddresses: false,
            savedAddresses: updatedList,
            addressId: saved.id,
            fullName: saved.fullName,
            addressLine: saved.formattedAddress,
            city: saved.city,
            state: saved.state,
            pincode: saved.pincode,
            phone: saved.phoneNumber,
          ),
        );
        return;
      }
    } catch (_) {
      // If saving to backend fails, update local state fields
    }

    emit(
      this.state.copyWith(
        isLoadingAddresses: false,
        fullName: fullName,
        addressLine: addressLine,
        city: city,
        state: state,
        pincode: pincode,
        phone: phone,
      ),
    );
  }

  String _formatBookingError(dynamic error) {
    final str = error.toString();
    if (str.contains('ALREADY_BOOKED')) {
      return 'You already have an active subscription for this batch.';
    }
    if (str.contains('BATCH_FULL')) {
      return 'This farming batch is currently full. Booking is closed.';
    }
    if (str.contains('PLAN_FULL')) {
      return 'The selected plan is currently full. Please choose another plan or variant.';
    }
    if (str.contains('INVALID_SELECTION')) {
      return 'Invalid selection. Please review your vegetable and plan choices.';
    }
    if (str.contains('PAYMENT_ERROR') || str.contains('SESSION_ERROR')) {
      return 'Unable to initialize payment session. Please try again.';
    }
    return str
        .replaceAll(RegExp(r'^(ApiException: \d* -?|Exception: )'), '')
        .trim();
  }

  Future<RfpBooking?> submitBooking({
    required String batchId,
    required String planId,
    required String locationId,
    required List<RfpPatchConfig> patchConfigs,
  }) async {
    if (state.status == CheckoutStatus.submitting || state.isVerifyingPayment) {
      return null;
    }
    if (!state.canSubmit) {
      emit(
        state.copyWith(
          status: CheckoutStatus.error,
          error: 'Please fill in all required delivery address fields.',
        ),
      );
      return null;
    }

    emit(
      state.copyWith(
        status: CheckoutStatus.submitting,
        error: null,
        verificationFailed: false,
      ),
    );

    try {
      final booking = await _createBooking(
        batchId: batchId,
        planId: planId,
        locationId: locationId,
        patchConfigs: patchConfigs,
        paymentMethod: state.selectedPaymentMethod,
        fullName: state.fullName,
        addressLine: state.addressLine,
        city: state.city,
        pincode: state.pincode,
        phone: state.phone,
        paymentType: state.paymentType,
        addressId: state.addressId,
      );

      emit(
        state.copyWith(
          status: CheckoutStatus.loaded,
          booking: booking,
          merchantTransactionId: booking.merchantTransactionId,
          checkoutUrl: booking.checkoutUrl,
          error: null,
        ),
      );
      return booking;
    } catch (e) {
      emit(
        state.copyWith(
          status: CheckoutStatus.error,
          error: _formatBookingError(e),
        ),
      );
      return null;
    }
  }

  Future<bool> verifyPayment([String? explicitTxId]) async {
    if (state.isVerifyingPayment) return false;

    final txId =
        explicitTxId ??
        state.booking?.merchantTransactionId ??
        state.merchantTransactionId;

    if (txId == null || txId.trim().isEmpty) {
      emit(
        state.copyWith(
          status: CheckoutStatus.error,
          error: 'No merchant transaction ID found to verify payment.',
          isVerifyingPayment: false,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        status: CheckoutStatus.verifying,
        isVerifyingPayment: true,
        error: null,
        verificationFailed: false,
      ),
    );

    try {
      if (_verifyPayment == null) {
        emit(
          state.copyWith(
            status: CheckoutStatus.success,
            isVerifyingPayment: false,
            booking: state.booking?.copyWith(
              status: 'active',
              bookingPaid: true,
            ),
          ),
        );
        return true;
      }

      final res = await _verifyPayment(txId.trim());
      final statusUpper = res['status']?.toString().toUpperCase() ?? '';
      final isSuccess =
          res['success'] == true ||
          statusUpper == 'SUCCESS' ||
          statusUpper == 'COMPLETED';

      if (isSuccess) {
        final updated = state.booking?.copyWith(
          status: 'active',
          bookingPaid: true,
        );

        emit(
          state.copyWith(
            status: CheckoutStatus.success,
            isVerifyingPayment: false,
            booking: updated,
            verificationResponse: res,
            error: null,
          ),
        );
        return true;
      } else {
        final serverMsg =
            res['message']?.toString() ??
            res['error']?.toString() ??
            'Payment verification failed. Please try again.';
        emit(
          state.copyWith(
            status: CheckoutStatus.error,
            isVerifyingPayment: false,
            verificationFailed: true,
            error: serverMsg,
            verificationResponse: res,
          ),
        );
        return false;
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: CheckoutStatus.error,
          isVerifyingPayment: false,
          verificationFailed: true,
          error: _formatBookingError(e),
        ),
      );
      return false;
    }
  }
}
