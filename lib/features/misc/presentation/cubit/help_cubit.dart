import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/features/misc/domain/usecases/help_confirm_deactivation_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/help_deactivate_account_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/send_otp_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/verify_otp_use_case.dart';
import 'package:grocery_app/features/misc/presentation/cubit/help_state.dart';

class HelpCubit extends Cubit<HelpState> {
  final SendOtpUseCase _sendOtpUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final HelpDeactivateAccountUseCase _deactivateAccountUseCase;
  final HelpConfirmDeactivationUseCase _confirmDeactivationUseCase;

  HelpCubit({
    required SendOtpUseCase sendOtpUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required HelpDeactivateAccountUseCase deactivateAccountUseCase,
    required HelpConfirmDeactivationUseCase confirmDeactivationUseCase,
  })  : _sendOtpUseCase = sendOtpUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        _deactivateAccountUseCase = deactivateAccountUseCase,
        _confirmDeactivationUseCase = confirmDeactivationUseCase,
        super(const HelpInitial());

  Future<bool> sendOtp({
    required String identifier,
    required String type,
  }) async {
    emit(const HelpLoading());
    final result = await _sendOtpUseCase(identifier: identifier, type: type);
    if (result['success'] == true) {
      emit(HelpSuccess(result['message'] ?? 'OTP sent'));
      return true;
    } else {
      emit(HelpError(result['message'] ?? 'Failed to send OTP'));
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String identifier,
    required String otp,
    required String type,
  }) async {
    emit(const HelpLoading());
    final result = await _verifyOtpUseCase(
      identifier: identifier,
      otp: otp,
      type: type,
    );
    if (result['success'] == true) {
      emit(HelpSuccess(result['message'] ?? 'OTP verified'));
      return true;
    } else {
      emit(HelpError(result['message'] ?? 'Failed to verify OTP'));
      return false;
    }
  }

  Future<bool> deactivateAccount(String password) async {
    emit(const HelpLoading());
    final result = await _deactivateAccountUseCase(password);
    if (result['success'] == true) {
      emit(HelpSuccess(result['message'] ?? 'Deactivation OTP sent'));
      return true;
    } else {
      emit(HelpError(result['message'] ?? 'Failed to request deactivation'));
      return false;
    }
  }

  Future<bool> confirmDeactivateAccount(String otp) async {
    emit(const HelpLoading());
    final result = await _confirmDeactivationUseCase(otp);
    if (result['success'] == true) {
      emit(HelpSuccess(result['message'] ?? 'Account deactivated'));
      return true;
    } else {
      emit(HelpError(result['message'] ?? 'Failed to confirm deactivation'));
      return false;
    }
  }
}
