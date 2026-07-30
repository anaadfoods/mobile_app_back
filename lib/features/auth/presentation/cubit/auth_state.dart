import 'package:equatable/equatable.dart';
import 'package:grocery_app/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// The initial state of the authentication flow, before any checks have been made.
class AuthInitial extends AuthState {}

/// The state when an authentication process (like login, register, logout) is in progress.
class AuthLoading extends AuthState {}

/// The state indicating the user is successfully authenticated and has user data.
class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// The state indicating the user is not authenticated.
class Unauthenticated extends AuthState {}

/// A transient state for when a user's profile has been successfully updated.
/// It extends [Authenticated] to keep the user in the logged-in state.
class AuthProfileUpdateSuccess extends Authenticated {
  final String message;

  const AuthProfileUpdateSuccess(super.user, this.message);

  @override
  List<Object?> get props => [user, message];
}

/// A transient state for when a user's address has been updated.
/// It extends [Authenticated] to keep the user in the logged-in state.
class AuthAddressUpdated extends Authenticated {
  final String message;

  const AuthAddressUpdated(super.user, this.message);

  @override
  List<Object?> get props => [user, message];
}

/// A transient state indicating that user registration was successful.
/// The app should typically navigate to the login screen from this state.
class AuthRegistrationSuccess extends AuthState {}

/// The state representing any error that occurs during the authentication process.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State indicating that deactivation OTP has been sent.
class AuthDeactivationOtpSent extends AuthState {
  final String message;

  const AuthDeactivationOtpSent(this.message);

  @override
  List<Object?> get props => [message];
}
