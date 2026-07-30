import 'package:equatable/equatable.dart';

abstract class HelpState extends Equatable {
  const HelpState();

  @override
  List<Object?> get props => [];
}

class HelpInitial extends HelpState {
  const HelpInitial();
}

class HelpLoading extends HelpState {
  const HelpLoading();
}

class HelpSuccess extends HelpState {
  final String message;

  const HelpSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class HelpError extends HelpState {
  final String message;

  const HelpError(this.message);

  @override
  List<Object?> get props => [message];
}
