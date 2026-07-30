import 'package:equatable/equatable.dart';
import 'package:grocery_app/features/misc/domain/entities/user_summary_entity.dart';

abstract class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {
  const AccountInitial();
}

class AccountLoading extends AccountState {
  const AccountLoading();
}

class AccountLoaded extends AccountState {
  final UserSummaryEntity? userSummary;
  final Map<String, dynamic>? userProfile;

  const AccountLoaded({
    this.userSummary,
    this.userProfile,
  });

  AccountLoaded copyWith({
    UserSummaryEntity? userSummary,
    Map<String, dynamic>? userProfile,
  }) {
    return AccountLoaded(
      userSummary: userSummary ?? this.userSummary,
      userProfile: userProfile ?? this.userProfile,
    );
  }

  @override
  List<Object?> get props => [userSummary, userProfile];
}

class AccountError extends AccountState {
  final String message;

  const AccountError(this.message);

  @override
  List<Object?> get props => [message];
}
