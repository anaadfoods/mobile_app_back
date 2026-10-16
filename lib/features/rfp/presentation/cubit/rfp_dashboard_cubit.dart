import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/rfp_booking.dart';
import '../../domain/entities/rfp_delivery.dart';
import '../../domain/entities/rfp_delivery_otp_status.dart';
import '../../domain/entities/rfp_pricing.dart';
import '../../domain/usecases/get_booking_details_use_case.dart';
import '../../domain/usecases/get_delivery_otp_status_use_case.dart';
import '../../domain/usecases/get_delivery_schedule_use_case.dart';
import '../../domain/usecases/pay_remaining_use_case.dart';
import '../../domain/usecases/verify_rfp_payment_use_case.dart';

// ─── State ─────────────────────────────────────────────────────────────────

class RfpDashboardState extends Equatable {
  final bool isLoading;
  final String? error;
  final RfpBooking? activeBooking;
  final List<RfpDelivery> upcomingDeliveries;
  final List<RfpDelivery> deliveryHistory;
  final RfpPricing? billing;
  final int selectedWeek;
  final RfpDeliveryOtpStatus? activeOtpStatus;

  const RfpDashboardState({
    this.isLoading = false,
    this.error,
    this.activeBooking,
    this.upcomingDeliveries = const [],
    this.deliveryHistory = const [],
    this.billing,
    this.selectedWeek = 4,
    this.activeOtpStatus,
  });

  bool get hasBooking => activeBooking != null;

  bool get hasOutForDelivery =>
      upcomingDeliveries.any((d) => d.isOutForDelivery) ||
      (activeBooking?.deliveries.any((d) => d.isOutForDelivery) ?? false);

  RfpDelivery? get currentOutForDelivery =>
      upcomingDeliveries.where((d) => d.isOutForDelivery).firstOrNull ??
      activeBooking?.deliveries.where((d) => d.isOutForDelivery).firstOrNull;

  List<RfpDelivery> get deliveriesForSelectedWeek =>
      [
        ...upcomingDeliveries,
        ...deliveryHistory,
      ].where((d) => d.weekNumber == selectedWeek).toList();

  RfpDashboardState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    RfpBooking? activeBooking,
    bool clearBooking = false,
    List<RfpDelivery>? upcomingDeliveries,
    List<RfpDelivery>? deliveryHistory,
    RfpPricing? billing,
    int? selectedWeek,
    RfpDeliveryOtpStatus? activeOtpStatus,
    bool clearOtpStatus = false,
  }) {
    return RfpDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeBooking:
          clearBooking ? null : (activeBooking ?? this.activeBooking),
      upcomingDeliveries: upcomingDeliveries ?? this.upcomingDeliveries,
      deliveryHistory: deliveryHistory ?? this.deliveryHistory,
      billing: billing ?? this.billing,
      selectedWeek: selectedWeek ?? this.selectedWeek,
      activeOtpStatus:
          clearOtpStatus ? null : (activeOtpStatus ?? this.activeOtpStatus),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    error,
    activeBooking,
    upcomingDeliveries,
    deliveryHistory,
    billing,
    selectedWeek,
    activeOtpStatus,
  ];
}

// ─── Cubit ─────────────────────────────────────────────────────────────────

class RfpDashboardCubit extends Cubit<RfpDashboardState> {
  final GetActiveBookingUseCase _getActiveBooking;
  final GetDeliveryScheduleUseCase _getDeliverySchedule;
  final GetUpcomingDeliveriesUseCase _getUpcomingDeliveries;
  final GetBookingDetailsUseCase? _getBookingDetails;
  final PayRemainingUseCase? _payRemaining;
  final VerifyRfpPaymentUseCase? _verifyPayment;
  final GetDeliveryOtpStatusUseCase? _getDeliveryOtpStatus;

  RfpDashboardCubit({
    required GetActiveBookingUseCase getActiveBooking,
    required GetDeliveryScheduleUseCase getDeliverySchedule,
    required GetUpcomingDeliveriesUseCase getUpcomingDeliveries,
    GetBookingDetailsUseCase? getBookingDetails,
    PayRemainingUseCase? payRemaining,
    VerifyRfpPaymentUseCase? verifyPayment,
    GetDeliveryOtpStatusUseCase? getDeliveryOtpStatus,
  }) : _getActiveBooking = getActiveBooking,
       _getDeliverySchedule = getDeliverySchedule,
       _getUpcomingDeliveries = getUpcomingDeliveries,
       _getBookingDetails = getBookingDetails,
       _payRemaining = payRemaining,
       _verifyPayment = verifyPayment,
       _getDeliveryOtpStatus = getDeliveryOtpStatus,
       super(const RfpDashboardState());

  Future<void> loadDashboard({String? bookingId}) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      RfpBooking? booking;
      if (bookingId != null && _getBookingDetails != null) {
        try {
          booking = await _getBookingDetails(bookingId);
        } catch (_) {
          booking = await _getActiveBooking();
        }
      } else {
        booking = await _getActiveBooking();
      }

      if (booking == null) {
        emit(
          state.copyWith(
            isLoading: false,
            clearBooking: true,
            upcomingDeliveries: const [],
            deliveryHistory: const [],
            clearOtpStatus: true,
          ),
        );
        return;
      }

      final schedule = await _getDeliverySchedule(booking.id);
      final upcoming = await _getUpcomingDeliveries(booking.id);
      final history =
          schedule.where((d) => d.status.toLowerCase() == 'delivered').toList();

      final allUpcoming =
          upcoming.isNotEmpty
              ? upcoming
              : booking.deliveries
                  .where((d) => d.status.toLowerCase() != 'delivered')
                  .toList();

      RfpDeliveryOtpStatus? otpStatus;
      if (_getDeliveryOtpStatus != null) {
        final target =
            allUpcoming.where((d) => d.isOutForDelivery).firstOrNull ??
            booking.deliveries.where((d) => d.isOutForDelivery).firstOrNull ??
            allUpcoming.firstOrNull;
        if (target != null && target.id.isNotEmpty) {
          try {
            otpStatus = await _getDeliveryOtpStatus(target.id);
          } catch (_) {}
        }
      }

      emit(
        state.copyWith(
          isLoading: false,
          activeBooking: booking,
          upcomingDeliveries: allUpcoming,
          deliveryHistory:
              history.isNotEmpty
                  ? history
                  : booking.deliveries
                      .where((d) => d.status.toLowerCase() == 'delivered')
                      .toList(),
          activeOtpStatus: otpStatus,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setInitialBooking(RfpBooking booking) {
    final schedule = booking.deliveries;
    final upcoming =
        schedule
            .where(
              (d) =>
                  d.status.toLowerCase() == 'upcoming' ||
                  d.status.toLowerCase() == 'scheduled' ||
                  d.status.toLowerCase() == 'pending' ||
                  d.status.toLowerCase() == 'out_for_delivery',
            )
            .toList();
    final history =
        schedule.where((d) => d.status.toLowerCase() == 'delivered').toList();

    emit(
      state.copyWith(
        activeBooking: booking,
        upcomingDeliveries: upcoming,
        deliveryHistory: history,
        clearError: true,
      ),
    );

    if (booking.id.isNotEmpty) {
      _refreshDeliveries(booking.id);
    }
  }

  Future<void> _refreshDeliveries(String bookingId) async {
    try {
      final schedule = await _getDeliverySchedule(bookingId);
      final upcoming = await _getUpcomingDeliveries(bookingId);
      final history =
          schedule.where((d) => d.status.toLowerCase() == 'delivered').toList();

      RfpDeliveryOtpStatus? otpStatus;
      if (_getDeliveryOtpStatus != null) {
        final target =
            upcoming.where((d) => d.isOutForDelivery).firstOrNull ??
            schedule.where((d) => d.isOutForDelivery).firstOrNull ??
            upcoming.firstOrNull;
        if (target != null && target.id.isNotEmpty) {
          try {
            otpStatus = await _getDeliveryOtpStatus(target.id);
          } catch (_) {}
        }
      }

      emit(
        state.copyWith(
          upcomingDeliveries: upcoming,
          deliveryHistory: history,
          activeOtpStatus: otpStatus ?? state.activeOtpStatus,
        ),
      );
    } catch (_) {}
  }

  /// Ingests a new live OTP immediately into state, e.g. from real-time push notification.
  void ingestLiveOtp({
    required String otp,
    String? deliveryId,
    DateTime? expiresAt,
  }) {
    emit(
      state.copyWith(
        activeOtpStatus: RfpDeliveryOtpStatus(
          state: 'ACTIVE',
          otp: otp,
          expiresAt:
              expiresAt ?? DateTime.now().add(const Duration(minutes: 15)),
        ),
      ),
    );
  }

  /// Refreshes deliveries and active OTP from the server.
  Future<void> refreshDeliveries() async {
    final bookingId = state.activeBooking?.id;
    if (bookingId != null && bookingId.isNotEmpty) {
      await _refreshDeliveries(bookingId);
    } else {
      await loadDashboard();
    }
  }

  Future<void> checkDeliveryOtpStatus([String? deliveryId]) async {
    if (_getDeliveryOtpStatus == null) return;
    try {
      final targetId =
          deliveryId ??
          state.currentOutForDelivery?.id ??
          state.upcomingDeliveries.firstOrNull?.id;
      if (targetId != null && targetId.isNotEmpty) {
        final otpStatus = await _getDeliveryOtpStatus(targetId);
        emit(state.copyWith(activeOtpStatus: otpStatus));
      }
    } catch (_) {}
  }

  void selectWeek(int week) {
    emit(state.copyWith(selectedWeek: week));
  }

  Future<Map<String, dynamic>?> payRemaining() async {
    final booking = state.activeBooking;
    if (booking == null || _payRemaining == null) return null;

    if (booking.remainingPaid || booking.remainingAmount <= 0) {
      emit(state.copyWith(error: 'Remaining amount is already paid.'));
      return null;
    }

    final subId = int.tryParse(booking.id.replaceAll(RegExp(r'[^0-9]'), ''));
    if (subId == null) {
      emit(state.copyWith(error: 'Invalid subscription ID.'));
      return null;
    }

    try {
      final res = await _payRemaining(subId);
      return res;
    } catch (e) {
      final errStr = e.toString();
      if (errStr.toLowerCase().contains('already paid') ||
          errStr.toLowerCase().contains('already_paid')) {
        await loadDashboard(bookingId: booking.id);
        emit(state.copyWith(error: 'Remaining amount is already paid.'));
      } else {
        emit(state.copyWith(error: e.toString()));
      }
      return null;
    }
  }

  Future<bool> verifyRemainingPayment(String merchantTransactionId) async {
    if (_verifyPayment == null) {
      await loadDashboard(bookingId: state.activeBooking?.id);
      return true;
    }

    try {
      final res = await _verifyPayment(merchantTransactionId);
      final statusUpper = res['status']?.toString().toUpperCase() ?? '';
      final isSuccess =
          res['success'] == true ||
          statusUpper == 'SUCCESS' ||
          statusUpper == 'COMPLETED';

      if (isSuccess) {
        await loadDashboard(bookingId: state.activeBooking?.id);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
