import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/features/misc/domain/usecases/fetch_user_summary_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/sync_user_profile_use_case.dart';
import 'package:grocery_app/features/misc/presentation/cubit/account_state.dart';

/// Consumers: AuthCubit, ThemeCubit
/// This Cubit reads current auth state and theme preferences directly or via listeners.
class AccountCubit extends Cubit<AccountState> {
  final FetchUserSummaryUseCase _fetchUserSummaryUseCase;
  final SyncUserProfileUseCase _syncUserProfileUseCase;

  AccountCubit({
    required FetchUserSummaryUseCase fetchUserSummaryUseCase,
    required SyncUserProfileUseCase syncUserProfileUseCase,
  })  : _fetchUserSummaryUseCase = fetchUserSummaryUseCase,
        _syncUserProfileUseCase = syncUserProfileUseCase,
        super(const AccountInitial());

  Future<void> loadAccountData() async {
    emit(const AccountLoading());
    try {
      final summary = await _fetchUserSummaryUseCase();
      final profile = await _syncUserProfileUseCase();
      emit(AccountLoaded(userSummary: summary, userProfile: profile));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> refreshSummary() async {
    final currentState = state;
    final currentProfile = currentState is AccountLoaded ? currentState.userProfile : null;
    try {
      final summary = await _fetchUserSummaryUseCase();
      emit(AccountLoaded(userSummary: summary, userProfile: currentProfile));
    } catch (e) {
      // keep existing state on error
    }
  }
}
